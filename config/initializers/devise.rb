# Use this hook to configure devise mailer, warden hooks and so forth.
# Many of these configuration options can be set straight in your model.
Devise.setup do |config|
  # ==> ORM configuration
  # Load and configure the ORM. Supports :active_record (default) and
  # :mongoid (bson_ext recommended) by default. Other ORMs may be
  # available as additional gems.
  require 'devise/orm/active_record'

  # Configure which authentication keys should be case-insensitive.
  # These keys will be downcased upon creating or modifying a user and when used
  # to authenticate or find a user. Default is :email.
  config.case_insensitive_keys = [:email, :uid]

  # Configure which authentication keys should have whitespace stripped.
  # These keys will have whitespace before and after removed upon creating or
  # modifying a user and when used to authenticate or find a user. Default is :email.
  config.strip_whitespace_keys = [:email, :uid]

  # By default Devise will store the user in session. You can skip storage for
  # particular strategies by setting this option.
  # Notice that if you are skipping storage for all authentication paths, you
  # may want to disable generating routes to Devise's sessions controller by
  # passing skip: :sessions to `devise_for` in your config/routes.rb
  config.skip_session_storage = [:http_auth]

  # Email regex used to validate email formats. It simply asserts that
  # one (and only one) @ exists in the given string. This is mainly
  # to give user feedback and not to assert the e-mail validity.
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/

  # The default HTTP method used to sign out a resource. Default is :delete.
  config.sign_out_via = :delete

  if ENV['FAKE_AUTH_ENABLED'] == 'true'
    config.omniauth :developer
  else
    # Omniauth Config
    idp_metadata_parser = OneLogin::RubySaml::IdpMetadataParser.new

    # Load IdP metadata from a file in test ENV
    if Rails.env.test?
      idp_data = File.open("#{Rails.root}/test/fixtures/files/testshib-providers.xml")
      idp_metadata = idp_metadata_parser.parse_to_hash(idp_data)
    # Load IdP metadata directly from the IdP in dev / prod ENV
    else
      idp_metadata = idp_metadata_parser.parse_remote_to_hash(
        ENV['IDP_METADATA_URL'],
        true, # validate cert
        entity_id: ENV['IDP_ENTITY_ID']
      )
    end

    config.omniauth :saml,
                    idp_cert_fingerprint: idp_metadata[:idp_cert_fingerprint],
                    idp_sso_target_url: ENV['IDP_SSO_URL'],
                    idp_cert: idp_metadata[:idp_cert],
                    certificate: Base64.strict_decode64(ENV['SP_CERTIFICATE']),
                    private_key: Base64.strict_decode64(ENV['SP_PRIVATE_KEY']),
                    issuer: ENV['SP_ENTITY_ID'],
                    request_attributes: {},
                    attribute_statements: { uid: [ENV['URN_UID']],
                                            email: [ENV['URN_EMAIL']],
                                            name: [ENV['URN_NAME']] },
                    security: { authn_requests_signed: true,
                                want_assertions_signed: true,
                                want_assertions_encrypted: true,
                                metadata_signed: true,
                                embed_sign: false,
                                digest_method: XMLSecurity::Document::SHA1,
                                signature_method: XMLSecurity::Document::RSA_SHA1 }
  end
end
