require 'rest_client'
require 'yaml'
require 'json'
require 'ons-jwe'
require 'openssl'

KEY_ID = 'EDCRRM'.freeze
config_file = YAML.load_file(File.join(__dir__, '/config.yml'))
public_key_file = config_file['eq-service']['public_key']
private_key_file = config_file['eq-service']['private_key']
private_key_passphrase_file = config_file['eq-service']['private_key_passphrase']

def load_key_from_file(file, passphrase = nil)
    OpenSSL::PKey::RSA.new(File.read(File.join(__dir__, file)), passphrase)
end

port = 4567
eq_server = ARGV[0]

file_obj = File.new('testData', 'r')

while (line = file_obj.gets)
  claims = {
    line: line
  }
  public_key  = load_key_from_file(public_key_file)
  private_key = load_key_from_file(private_key_file,
                                   private_key_passphrase_file)
  token = JWEToken.new(KEY_ID, claims, public_key, private_key)

  RestClient.post("#{eq_server}:#{port}/flush?token=#{token.value}", {
                  }) do |post_response, _request, _result, &_block|
    if post_response.code == 200
      puts '200 Flush successful.'
    end
    if post_response.code == 401
      puts '401 Error: Authentication Failure'
    end
    if post_response.code == 403
      puts '403 Error: Permission Denied'
    end
    if post_response.code == 404
      puts '404 Error: Survey Response not found for case ' + line
    end
    if post_response.code == 500
      puts '500 Error: Flushing failed'
    end
  end
  sleep(3)
end

file_obj.close
