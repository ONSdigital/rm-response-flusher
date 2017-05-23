#!/usr/bin/env ruby
require 'rest_client'
require 'yaml'
require 'json'
require 'ons-jwe'
require 'openssl'
require 'csv'

unless ARGV.length == 2
  puts 'Usage: eq_flush_script.rb <input_file> <server>'
  exit
end

KEY_ID = 'EDCRRM'.freeze
config_file = YAML.load_file(File.join(__dir__, 'config.yml'))
public_key_file = config_file['eq-service']['public_key']
private_key_file = config_file['eq-service']['private_key']
private_key_pass_file = config_file['eq-service']['private_key_passphrase']
port = config_file['eq-service']['port']

def load_key_from_file(file, passphrase = nil)
  OpenSSL::PKey::RSA.new(File.read(File.join(__dir__, file)), passphrase)
end

eq_server = ARGV[1]
input_file = File.read(ARGV[0])

input_file_csv = CSV.parse(input_file, headers: true)

public_key  = load_key_from_file(public_key_file)
private_key = load_key_from_file(private_key_file,
                                 private_key_pass_file)

input_file_csv.each do |input_file_row|
  claims = {
    collection_exercise_sid: '0',
    eq_id: 'census',
    exp: Time.now.to_i + 60 * 60,
    iat: Time.now.to_i,
    roles: ['flusher'],
    ru_ref: input_file_row[0].delete(' '),
    form_type: input_file_row[1].delete(' '),
    tx_id: SecureRandom.uuid
  }

  puts "claims=#{claims}"
  token = JWEToken.new(KEY_ID, claims, public_key, private_key)

  puts "#{eq_server}/flush?token=#{token.value}"

  RestClient.post("#{eq_server}/flush?token=#{token.value}", {
                  }) do |response, _request, _result, &_block|
    case response.code
    when 200
      puts '200 Flush successful'
    when 401
      puts '401 Error: Authentication failure'
    when 403
      puts '403 Error: Permission denied'
    when 404
      puts '404 Error: Survey response not found for case ' + input_file_row[0].delete(' ')
    when 500
      puts '500 Error: Flushing failed'
    end
  end
  sleep(3)
end
