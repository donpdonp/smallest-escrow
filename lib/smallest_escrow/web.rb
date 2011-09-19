require 'sinatra/base'
require 'uuidtools'

module SmallestEscrow
 class Web < Sinatra::Base
  use Rack::Session::Cookie

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    locals = before_action
    erb :create, :locals => locals
  end

  get %r{/([a-z0-9-]{36})} do
    offer = Deal.true_load(params[:captures].first)
    if offer
      log("load #{offer}")
      locals = before_action.merge({:btc_tx => offer.btc_transactions, :offer => offer})
      puts locals.inspect
      erb :show, :locals => locals
    end
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
    response = DWOLLA.request(offer)
    log("#{offer} dwolla response #{response.inspect}")
    if response["Result"] == "Success"
      offer.dwolla_checkout_id = response["CheckoutId"]
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

  post "/usd_refund" do
    deal = Deal.true_load(params[:uuid])
    if deal.usd_paid?
      log("usd_refund: refunding")
    end
  end

  # admin
  get "/admin" do
    locals = before_action
    redis_up = Util.tcp_accepting?(6380)
    if redis_up
      token = SmallestEscrow::Dwolla::Auth.get_token
    end
    erb :admin, :locals => locals.merge({:dwolla_token => token,
                                         :redis_up => redis_up})
  end

  get "/dwolla/auth" do
    request_token = DWOLLA.request_token
    log("dwolla/auth: request #{request_token.inspect}")
    session[:request_token] = request_token
    log("dwolla/auth: token #{request_token.token} secret #{request_token.secret}")
    redirect to(request_token.authorize_url)
  end

  get "/dwolla/deauth" do
    SmallestEscrow::Dwolla::Auth.remove_token
    redirect to("/admin")
  end

  get "/dwolla/oauth" do
    log("dwolla/oauth: #{params.inspect} verify: #{params[:oauth_verifier]}")
    log("dwolla/oauth: request #{session[:request_token].inspect}")
    access_token = session[:request_token].get_access_token({}, :oauth_verifier => params[:oauth_verifier])
    log("dwolla/oauth: access #{access_token.inspect}")
    SmallestEscrow::Dwolla::Auth.save_token(access_token)
    redirect to("/admin")
  end

  post "/dwolla/payment" do
    jparams = JSON.parse(request.body.read)
    log("dwolla/payment: jparams #{jparams.inspect}")
    deal = Deal.true_load(jparams["OrderId"])
    if deal.dwolla_checkout_id == jparams["CheckoutId"]
      deal.dwolla_tx_id = jparams["TransactionId"]
      log("dwolla/payment: CheckId matches. Saving TransactionId #{deal.dwolla_tx_id}")
      deal.save
    end
  end

  private
  def log(msg)
    time_msg = "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}"
    puts time_msg
  end

  def before_action
    begin
      bit_stats = BITBANK.info
    rescue RestClient::RequestTimeout
      session[:notice] = "bitcoind timed out"
    rescue RestClient::Unauthorized
      session[:notice] = "bitcoind authorization failed"
    rescue Errno::ECONNREFUSED
      session[:notice] = "bitcoind not ready"
    end
    {:stats => bit_stats}
  end
 end
end

