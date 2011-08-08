require 'sinatra/base'
require 'uuid'
require 'redis'

class SmallestEscrow < Sinatra::Base

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    erb :create
  end

  get '/:uuid' do
    uuid = params[:uuid]
    offer = redis.get("deal:#{uuid}")
    log("load deal:#{uuid} -> #{offer}")
    erb :show, :locals => {:offer => offer}
  end

  post '/create' do
    uuid = UUID.generate
    redis.set("deal:#{uuid}", params)
    log("save deal:#{uuid} -> #{params}")
    redirect to("/#{uuid}")
  end

  private
  def redis
    @redis ||= Redis.new
  end

  def log(msg)
    File.open("log","a"){|f| f.write msg+"\n"}
  end

end

