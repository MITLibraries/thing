require 'test_helper'

class AuthenticationTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  def silence_omniauth
    previous_logger = OmniAuth.config.logger
    OmniAuth.config.logger = Logger.new('/dev/null')
    yield
  ensure
    OmniAuth.config.logger = previous_logger
  end

  test 'accessing callback without credentials redirects to signin' do
    OmniAuth.config.mock_auth[:saml] = :invalid_credentials
    silence_omniauth do
      get '/users/auth/saml/callback'
      follow_redirect!
    end
    assert_response :success
  end

  test 'accessing callback with for new user' do
    # we can't use `mock_auth` because we wan't to test user creation
    # and `mock_auth` users a fixtured user
    OmniAuth.config.mock_auth[:saml] =
      OmniAuth::AuthHash.new(provider: 'saml',
                             uid: '123545',
                             info: { uid: '123545', email: 'bob@asdf.com' })
    usercount = User.count
    get '/users/auth/saml/callback'
    follow_redirect!
    assert_response :success
    assert_equal(usercount + 1, User.count)
  end

  test 'redirect to root path after login' do
    mock_auth(users(:yo))
    follow_redirect!
    assert_equal '/', @request.path
  end
end
