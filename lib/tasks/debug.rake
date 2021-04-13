require 'onelogin/ruby-saml'

namespace :debug do
  desc "Debug an encrypted saml response. Ensure SP cert and key are set in .env"
  task :saml, :filepath do |t, args|
    # Assumptions: you have extracted the saml response from logs and placed ONLY
    # the response (not the XML!, not the quotes) into a file on a single line
    saml_response = File.open(args[:filepath]).first

    # see https://github.com/onelogin/ruby-saml#the-initialization-phase for more
    # options depending on what you are debugging
    settings = OneLogin::RubySaml::Settings.new
    settings.certificate = Base64.strict_decode64(ENV['SP_CERTIFICATE'])
    settings.private_key = Base64.strict_decode64(ENV['SP_PRIVATE_KEY'])

    response = OneLogin::RubySaml::Response.new(saml_response, settings: settings)
    # This should output all attributes we got back.
    pp "-- START SAML RESPONSE --"
    pp response.attributes
    pp "-- END SAML RESPONSE --"
  end
end
