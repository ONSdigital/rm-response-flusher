#test.rb
require 'json'
require 'ons-jwe'
require 'openssl'
require 'sinatra'
require 'jwt'
require 'yaml'

post '/flush/' do
  token = params[:token]
  puts token
  config_file = YAML.load_file(File.join(__dir__, '/config.yml'))
  public_key = config_file['eq-service']['public_key']
  payload = token.value[0, token.value.index('.')]
  #payload = JWT.decode token, public_key, true, { :algorithm => 'RS256' }
  puts(payload)
end
