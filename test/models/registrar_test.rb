# == Schema Information
#
# Table name: registrars
#
#  id         :integer          not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer          not null
#
# Indexes
#
#  index_registrars_on_user_id  (user_id)
#
# Foreign Keys
#
#  user_id  (user_id => users.id)
#
require 'test_helper'

class RegistrarTest < ActiveSupport::TestCase
  setup do
    @registrar = registrar(:valid)
    f = Rails.root.join('test', 'fixtures', 'files', 'registrar.csv')
    @registrar.graduation_list.attach(io: File.open(f), filename: 'registrar.csv')
  end

  teardown do
    @registrar.graduation_list.purge
  end

  test 'valid registrar' do
    assert @registrar.valid?
  end

  test 'invalid without file' do
    @registrar.graduation_list.purge
    assert @registrar.invalid?
  end
end
