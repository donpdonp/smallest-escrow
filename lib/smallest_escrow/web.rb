require 'sinatra/base'
require 'uuidtools'

module SmallestEscrow
 class Web < Sinatra::Base

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    erb :create, :locals => {:stats => BITBANK.info}
  end

  get '/:uuid' do
    offer = Deal.true_load(params[:uuid])
    log("load #{offer}")
    erb :show, :locals => {:offer => offer, :stats => BITBANK.info}
  end

  post '/create' do
    uuid = UUIDTools::UUID.random_create.to_s
    deal_params = params.merge("btc_receiving_address" => BITBANK.new_address(uuid))
    offer = Deal.true_store(uuid, deal_params)
    log("save #{offer}")
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

