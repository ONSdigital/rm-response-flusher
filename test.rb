require 'json'
require 'ons-jwe'
require 'openssl'
require 'sinatra'
require 'jwt'
require 'yaml'

post '/flush' do
  token = params[:token]
  puts token
end
