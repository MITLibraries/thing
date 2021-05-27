require 'test_helper'

class NavTest < ActionDispatch::IntegrationTest
  def setup
    auth_setup
  end

  def teardown
    auth_teardown
  end

  # Testing navigation link text
  test 'home page nav' do
    get root_path
    assert_select('.current') do |value|
      assert(value.text.include?('Home'))
    end
  end

  test 'new thesis page nav' do
    mock_auth(users(:basic))
    get thesis_start_path
    assert_select('.current') do |value|
      assert(value.text.include?('Submit thesis information'))
    end
  end

  test 'thesis queue page nav' do
    mock_auth(users(:admin))
    get thesis_select_path
    assert_select('.current') do |value|
      assert(value.text.include?('Process theses'))
    end
  end

  test 'registrar page nav' do
    mock_auth(users(:admin))
    get new_registrar_path
    assert_select('.current') do |value|
      assert(value.text.include?('Upload CSV'))
    end
  end

  test 'harvest page nav' do
    @registrar = registrar(:valid)
    f = Rails.root.join('test','fixtures','files','registrar.csv')
    @registrar.graduation_list.attach(io: File.open(f), filename: 'registrar.csv')
    mock_auth(users(:admin))
    get harvest_path
    assert_select('.current') do |value|
      assert(value.text.include?('Harvest CSV'))
    end
  end

  test 'transfer page nav' do
    mock_auth(users(:admin))
    get new_transfer_path
    assert_select('.current') do |value|
      assert(value.text.include?('Transfer theses'))
    end
  end

  test 'transfer selection nav' do
    mock_auth(users(:admin))
    get transfer_select_path
    assert_select('.current') do |value|
      assert(value.text.include?('Process transfers'))
    end
  end

  # Basic user navigation
  test 'basic navigation' do
    mock_auth(users(:basic))
    get '/'

    assert_select "nav" do
      assert_select "a[href=?]", root_path
      assert_select "a[href=?]", thesis_start_path

      # Navigation should not include:
      assert_select "a[href=?]", thesis_select_path, count: 0
      assert_select "a[href=?]", new_transfer_path, count: 0
      assert_select "a[href=?]", transfer_select_path, count: 0
      assert_select "a[href=?]", new_registrar_path, count: 0
      assert_select "a[href=?]", harvest_path, count: 0
      assert_select "a[href=?]", admin_root_path, count: 0
    end
  end

  # Submitter navigation
  test 'transfer_submitter navigation' do
    mock_auth(users(:transfer_submitter))
    get '/'

    assert_select "nav" do
      assert_select "a[href=?]", root_path
      assert_select "a[href=?]", thesis_start_path
      assert_select "a[href=?]", new_transfer_path

      # Navigation should not include:
      assert_select "a[href=?]", thesis_select_path, count: 0
      assert_select "a[href=?]", transfer_select_path, count: 0
      assert_select "a[href=?]", new_registrar_path, count: 0
      assert_select "a[href=?]", harvest_path, count: 0
      assert_select "a[href=?]", admin_root_path, count: 0
    end
  end

  # Processor navigation
  test 'thesis_processor navigation' do
    mock_auth(users(:processor))
    get '/'

    assert_select "nav" do
      assert_select "a[href=?]", root_path
      assert_select "a[href=?]", thesis_start_path
      assert_select "a[href=?]", thesis_select_path
      # assert_select "a[href=?]", new_transfer_path
      assert_select "a[href=?]", transfer_select_path
      assert_select "a[href=?]", new_registrar_path, count: 0
      assert_select "a[href=?]", harvest_path, count: 0
      # assert_select "a[href=?]", admin_root_path
    end
  end

  # Thesis admin navigation
  test 'thesis_admin navigation' do
    mock_auth(users(:thesis_admin))
    get '/'

    assert_select "nav" do
      assert_select "a[href=?]", root_path
      assert_select "a[href=?]", thesis_start_path
      assert_select "a[href=?]", thesis_select_path
      assert_select "a[href=?]", new_transfer_path
      assert_select "a[href=?]", transfer_select_path
      assert_select "a[href=?]", new_registrar_path
      assert_select "a[href=?]", harvest_path
      assert_select "a[href=?]", admin_root_path
    end
  end

  # Admin navigation
  test 'admin navigation' do
    mock_auth(users(:admin))
    get '/'

    assert_select "nav" do
      assert_select "a[href=?]", root_path
      assert_select "a[href=?]", thesis_start_path
      assert_select "a[href=?]", thesis_select_path
      assert_select "a[href=?]", new_transfer_path
      assert_select "a[href=?]", transfer_select_path
      assert_select "a[href=?]", new_registrar_path
      assert_select "a[href=?]", harvest_path
      assert_select "a[href=?]", admin_root_path
    end
  end
end
