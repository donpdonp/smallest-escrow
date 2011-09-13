require 'sinatra/base'
require 'uuidtools'

module SmallestEscrow
 class Web < Sinatra::Base
  use Rack::Session::Cookie

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    begin
      stats = BITBANK.info
    rescue RestClient::RequestTimeout
      session[:notice] = "bitcoind timed out"
    end
    erb :create, :locals => {:stats => stats}
  end

  get %r{/([a-z0-9-]{36})} do
    offer = Deal.true_load(params[:captures].first)
    log("load #{offer}")
    begin
      timer = Time.now
      btc_tx = BITBANK.account_by_address(offer.btc_receiving_address).transactions
      log("transactions loaded in #{Time.now - timer} seconds")
      stats = BITBANK.info
    rescue RestClient::RequestTimeout
      session[:notice] = "bitcoind timed out"
    end
    cred = SmallestEscrow::Dwolla::Auth.get_token
    log("dwolla: cred #{cred.inspect}")
    dwolla_at = DWOLLA.access_token(cred)
    log("dwolla: #{dwolla_at.inspect}")
    dwolla_tx = dwolla_at.get("https://www.dwolla.com/oauth/rest/accountapi/transactions")
    log("dwolla: #{dwolla_tx.inspect}")
    erb :show, :locals => {:offer => offer, :stats => stats, :btc_tx => btc_tx}
  end

  post '/create' do
    uuid = UUIDTools::UUID.random_create.to_s
    deal_params = params.merge("btc_receiving_address" => BITBANK.new_address(uuid))
    offer = Deal.true_store(uuid, deal_params)
    log("save #{offer}")
    redirect to("/#{offer.uuid}")
  end

  post '/dwolla_from' do
    offer = Deal.true_load(params[:uuid])
    offer.dwolla_receiving_address = params[:dwolla_receiving_address]
    offer.save
    log("#{offer} updated with dwolla receiving address #{offer.dwolla_receiving_address}")
    response = DWOLLA.request(offer)
    log("#{offer} dwolla response #{response.inspect}")
    if response["Result"] == "Success"
      offer.dwolla_request_payment_key = response["CheckoutId"]
      offer.save
      redirect to("https://www.dwolla.com/payment/checkout/"+response["CheckoutId"])
    else
      session[:notice] = "Dwolla failure: #{response["Message"]}"
    end
    redirect to("/#{offer.uuid}")
  end

  post "/btc_refund" do
    offer = Deal.true_load(params[:uuid])
    btc_account = BITBANK.account_by_address(offer.btc_receiving_address)
    tx = btc_account.transactions.select{|tx| tx.txid == params[:txid]}.first
    if tx
      rtx = btc_account.pay(params[:tobitcoinaddress], tx.amount)
      if rtx
        session[:notice] = "#{rtx.amount} has been refunded."
      else
        session[:notice] = "refund failed."
      end
    else
      session[:notice] = "Transaction #{tx.txid} not found"
    end
    redirect to("/#{offer.uuid}")
  end

  # admin
  get "/admin" do
    begin
      erb :admin, :locals => {:stats => BITBANK.info, 
                              :dwolla_token => SmallestEscrow::Dwolla::Auth.get_token}
    rescue RestClient::RequestTimeout
      session[:notice] = "bitcoind timed out"
    end

  end

  get "/dwolla/auth" do
    request_token = DWOLLA.request_token
    session[:request_token] = request_token
    redirect to(request_token.authorize_url)
  end

  get "/dwolla/deauth" do
    SmallestEscrow::Dwolla::Auth.remove_token
    redirect to("/admin")
  end

  get "/dwolla/oauth" do
    log("dwolla/oauth: #{params.inspect}")
    log("dwolla/oauth: request #{session[:request_token].inspect}")
    access_token = session[:request_token].get_access_token
    log("dwolla/oauth: access #{access_token.inspect}")
    SmallestEscrow::Dwolla::Auth.save_token(access_token)
    redirect to("/admin")
  end

  private
  def log(msg)
    time_msg = "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}"
    #File.open("log","a"){|f| f.write "#{time_msg}\n"}
    puts time_msg
  end

 end
end

