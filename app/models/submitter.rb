# == Schema Information
#
# Table name: submitters
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  department_id :integer          not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Submitter < ApplicationRecord
  belongs_to :user
  belongs_to :department
end
