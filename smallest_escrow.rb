require 'sinatra/base'

class SmallestEscrow < Sinatra::Base

  set :static, true
  set :show_execptions, true
  
  get '/' do
    erb :create
  end
end

