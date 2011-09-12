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

  get '/:uuid' do
    offer = Deal.true_load(params[:uuid])
    log("load #{offer}")
    begin
      timer = Time.now
      btc_tx = BITBANK.account_by_address(offer.btc_receiving_address).transactions
      log("transactions loaded in #{Time.now - timer} seconds")
      stats = BITBANK.info
    rescue RestClient::RequestTimeout
      session[:notice] = "bitcoind timed out"
    end
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

  private
  def log(msg)
    time_msg = "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}"
    #File.open("log","a"){|f| f.write "#{time_msg}\n"}
    puts time_msg
  end

 end
end

