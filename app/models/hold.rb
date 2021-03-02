# == Schema Information
#
# Table name: holds
#
#  id               :integer          not null, primary key
#  thesis_id        :integer          not null
#  date_requested   :date             not null
#  date_start       :date             not null
#  date_end         :date             not null
#  hold_source_id   :integer          not null
#  case_number      :string
#  status           :integer          not null
#  processing_notes :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Hold < ApplicationRecord
  has_paper_trail

  belongs_to :thesis
  belongs_to :hold_source

  enum status: [ :active, :expired, :released ]

  validates :date_requested, presence: true
  validates :date_start, presence: true
  validates :date_end, presence: true
  validates :status, presence: true

  def degrees
    self.thesis.degrees.map { |d| d.name}.join("\n")
  end

  def grad_date
    self.thesis.grad_date
  end

  def author_names
    self.thesis.users.map { |u| u.name }.join("; ")
  end

  def created_by
    if self.versions.first.event == 'create'
      creator_id = self.versions.first.whodunnit
      user = User.find_by(id: creator_id)
      user.kerberos_id
    end
  end

  # Per internal discussions, we are setting this to the create date of 
  # the parent thesis, which may be slightly different than the date the 
  # file(s) were transferred.
  def date_thesis_file_received
    self.thesis.created_at.strftime('%Y-%m-%d')
  end

  # In the unlikely scenario that the the status was changed to 'released' 
  # multiple times, this assumes we want the most recent date released.
  def date_released
    released_versions = self.versions.select do |version| 
      version.changeset["status"][1] == 'released' if version.changeset["status"].present?
    end
    dates_released = released_versions.map { |version| version.changeset["updated_at"][1] }
    dates_released.sort.last
  end
end
