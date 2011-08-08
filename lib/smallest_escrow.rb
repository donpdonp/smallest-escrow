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
    uuid = params[:uuid]
    offer = Deal.load(redis, uuid)
    log("load deal:#{uuid} -> #{offer}")
    erb :show, :locals => {:offer => offer}
  end

  post '/create' do
    Deal.store(redis, UUID.generate, params)
    log("save deal:#{uuid} -> #{params}")
    redirect to("/#{uuid}")
  end

  private
  def redis
    @redis ||= Redis.new
  end

  def log(msg)
    File.open("log","a"){|f| f.write "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}\n"}
  end

end

