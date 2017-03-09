#!/usr/bin/env ruby
require 'rest_client'
require 'yaml'
require 'json'
require 'ons-jwe'
require 'openssl'

unless ARGV.length == 2
  puts 'Usage: eq_flush_script.rb <input_file> <server>'
  exit
end

KEY_ID = 'EDCRRM'.freeze
config_file = YAML.load_file(File.join(__dir__, '/config.yml'))
public_key_file = config_file['eq-service']['public_key']
private_key_file = config_file['eq-service']['private_key']
private_key_pass_file = config_file['eq-service']['private_key_passphrase']
port = config_file['eq-service']['port']

def load_key_from_file(file, passphrase = nil)
  OpenSSL::PKey::RSA.new(File.read(File.join(__dir__, file)), passphrase)
end

eq_server = ARGV[1]
input_file = ARGV[0]

file_obj = File.new(input_file, 'r')

public_key  = load_key_from_file(public_key_file)
private_key = load_key_from_file(private_key_file,
                                 private_key_pass_file)

while (line = file_obj.gets)

  claims = {
    collection_exercise_sid: '0',
    eq_id: 'census',
    exp: Time.now.to_i + 60 * 60,
    iat: Time.now.to_i,
    roles: ['flusher'],
    ru_ref: line,
    tx_id: SecureRandom.uuid
  }

  token = JWEToken.new(KEY_ID, claims, public_key, private_key)

  RestClient.post("#{eq_server}:#{port}/flush?token=#{token.value}", {
                  }) do |post_response, _request, _result, &_block|
    code = post_response.code
    case code
    when 200 then $stdout.puts '200 Flush successful.'
    when 401 then $stderr.puts '401 Error: Authentication Failure'
    when 403 then $stderr.puts '403 Error: Permission Denied'
    when 404 then $stderr.puts '404 Error: Survey Response not found for case ' + line
    when 500 then $stderr.puts '500 Error: Flushing failed'
    end
  end
  sleep(3)
end

file_obj.close
