require 'rest_client'
require 'yaml'
require 'json'
require 'ons-jwe'
require 'openssl'

KEY_ID                    = 'EDCRRM'.freeze
config_file = YAML.load_file(File.join(__dir__, '/config.yml'))
public_key = config_file['eq-service']['public_key']
private_key = config_file['eq-service']['private_key']
private_key_passphrase =  config_file['eq-service']['private_key_passphrase']

def load_key_from_file(file, passphrase = nil)
  OpenSSL::PKey::RSA.new(File.read(File.join(__dir__, file)), passphrase)
end

port = 4567
eqServer = ARGV[0]

fileObj = File.new('testData', "r")

  while (line = fileObj.gets)
    claims = {
      line: line
    }
    public_key  = load_key_from_file(public_key)
    private_key = load_key_from_file(private_key,
                                    private_key_passphrase)
    token  = JWEToken.new(KEY_ID, claims, public_key, private_key)

    RestClient.post("#{eqServer}:#{port}/flush/?token=#{token.value}", {
      #line: line,
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

fileObj.close
