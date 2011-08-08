require 'sinatra/base'
require 'uuid'

module SmallestEscrow
 class Web < Sinatra::Base

  set :static, true
  set :public, "public"
  set :show_execptions, true
  
  get '/' do
    erb :create
  end

  get '/:uuid' do
    offer = Deal.true_load(params[:uuid])
    log("load #{offer}")
    erb :show, :locals => {:offer => offer}
  end

  post '/create' do
    offer = Deal.true_store(UUID.generate, params)
    log("save #{offer}")
    redirect to("/#{offer.uuid}")
  end

  private
  def log(msg)
    File.open("log","a"){|f| f.write "#{Time.now.strftime("%Y-%m-%d %I:%M%P")} #{msg}\n"}
  end

 end
end

