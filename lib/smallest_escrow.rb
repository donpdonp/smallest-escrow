require 'sinatra/base'
require 'uuid'
require 'redis'
require 'deal'

class SmallestEscrow < Sinatra::Base

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    erb :create
  end

  get '/:uuid' do
    offer = Deal.load(redis, params[:uuid])
    log("load #{offer}")
    erb :show, :locals => {:offer => offer}
  end

  post '/create' do
    offer = Deal.store(redis, UUID.generate, params)
    log("save {offer}")
    redirect to("/#{offer.uuid}")
  end

  private
  def redis
    @redis ||= Redis.new
  end

  def log(msg)
    File.open("log","a"){|f| f.write "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}\n"}
  end

end

