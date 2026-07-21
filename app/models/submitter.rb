# == Schema Information
#
# Table name: submitters
#
#  id            :integer          not null, primary key
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  department_id :integer          not null
#  user_id       :integer          not null
#
# Indexes
#
#  index_submitters_on_department_id  (department_id)
#  index_submitters_on_user_id        (user_id)
#
# Foreign Keys
#
#  department_id  (department_id => departments.id)
#  user_id        (user_id => users.id)
#
class Submitter < ApplicationRecord
  belongs_to :user
  belongs_to :department
end
