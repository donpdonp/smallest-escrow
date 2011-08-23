require 'sinatra/base'
require 'uuidtools'

module SmallestEscrow
 class Web < Sinatra::Base

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    erb :create, :locals => {:stats => bitcoind_stats}
  end

  get '/:uuid' do
    offer = Deal.true_load(params[:uuid])
    log("load #{offer}")
    erb :show, :locals => {:offer => offer, :stats => bitcoind_stats}
  end

  post '/create' do
    offer = Deal.true_store(UUIDTools::UUID.random_create.to_s, params)
    log("save #{offer}")
    redirect to("/#{offer.uuid}")
  end

  private
  def log(msg)
    time_msg = "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}"
    #File.open("log","a"){|f| f.write "#{time_msg}\n"}
    puts time_msg
  end

  def bitcoind_stats
    BITBANK.block_count
  end

 end
end

