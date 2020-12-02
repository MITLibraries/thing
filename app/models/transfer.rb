# == Schema Information
#
# Table name: transfers
#
#  id         :integer          not null, primary key
#  note       :text
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Transfer < ApplicationRecord
  belongs_to :user
end
