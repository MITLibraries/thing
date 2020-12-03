# == Schema Information
#
# Table name: transfers
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  department_id :integer          not null
#  grad_date     :date             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Transfer < ApplicationRecord
  belongs_to :user
end
