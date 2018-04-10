require 'test_helper'

class RedirectDomainsTest < ActionDispatch::IntegrationTest
  test 'no PREFERRED_DOMAIN' do
    get '/'
    assert_response :success
    assert_equal('/', @request.path)
  end

  test 'PREFERRED_DOMAIN domain matches request host' do
    ClimateControl.modify(PREFERRED_DOMAIN: 'example.org') do
      get 'http://example.org/'
      assert_response :success
      assert_equal('example.org', request.host)
      assert_equal('/', @request.path)
    end
  end

  test 'PREFERRED_DOMAIN does not match request host' do
    ClimateControl.modify(PREFERRED_DOMAIN: 'example.com') do
      get 'http://example.org/'
      assert_response :redirect
      assert_equal('example.org', request.host)
      follow_redirect!
      assert_equal('example.com', request.host)
      assert_equal('/', @request.path)
    end
  end

  test 'vireo/start url handling' do
    get '/vireo/start'
    assert_equal('/vireo/start', @request.path)
    follow_redirect!
    assert_equal('/', @request.path)
  end

  test 'vireo/admin url handling' do
    get '/vireo/admin'
    assert_equal('/vireo/admin', @request.path)
    follow_redirect!
    assert_equal('/', @request.path)
  end

  test 'vireo url handling' do
    get '/vireo'
    assert_equal('/vireo', @request.path)
    follow_redirect!
    assert_equal('/', @request.path)
  end
end
