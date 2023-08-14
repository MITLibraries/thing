require 'test_helper'

class FakeAuthTest < ActiveSupport::TestCase
  include FakeAuthConfig

  test 'fakeauth disabled' do
    ClimateControl.modify(
      FAKE_AUTH_ENABLED: 'false',
      HEROKU_APP_NAME: 'thesis-submit-pr-123'
    ) do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
    ClimateControl.modify(
      FAKE_AUTH_ENABLED: 'false',
      HEROKU_APP_NAME: 'thesis-dropbox-pr-123'
    ) do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
  end

  test 'fakeauth enabled pr pattern app name' do
    ClimateControl.modify(
      FAKE_AUTH_ENABLED: 'true',
      HEROKU_APP_NAME: 'thesis-submit-pr-123'
    ) do
      assert_equal(true, FakeAuthConfig.fake_auth_status)
    end
    ClimateControl.modify(
      FAKE_AUTH_ENABLED: 'true',
      HEROKU_APP_NAME: 'thesis-dropbox-pr-123'
    ) do
      assert_equal(true, FakeAuthConfig.fake_auth_status)
    end
  end

  test 'fakeauth enabled no heroku app name' do
    ClimateControl.modify FAKE_AUTH_ENABLED: 'true' do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
  end

  test 'fakeauth enabled production app name' do
    ClimateControl.modify FAKE_AUTH_ENABLED: 'true',
                          HEROKU_APP_NAME: 'thesis-submit-production' do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
    ClimateControl.modify FAKE_AUTH_ENABLED: 'true',
                          HEROKU_APP_NAME: 'library-thesis-dropbox' do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
  end

  test 'fakeauth enabled staging app name' do
    ClimateControl.modify FAKE_AUTH_ENABLED: 'true',
                          HEROKU_APP_NAME: 'thesis-submit-staging' do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
    ClimateControl.modify FAKE_AUTH_ENABLED: 'true',
                          HEROKU_APP_NAME: 'library-thesis-dropbox-staging' do
      assert_equal(false, FakeAuthConfig.fake_auth_status)
    end
  end

  test 'fakeauth enabled temp staging app name' do
    ClimateControl.modify FAKE_AUTH_ENABLED: 'true',
                          HEROKU_APP_NAME: 'thesis-submit-staging-new' do
      assert_equal true, FakeAuthConfig.fake_auth_status
    end
  end
end
