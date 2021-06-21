# == Schema Information
#
# Table name: authors
#
#  id                   :integer          not null, primary key
#  user_id              :integer          not null
#  thesis_id            :integer          not null
#  graduation_confirmed :boolean          default(FALSE), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
class Author < ApplicationRecord
  belongs_to :user
  belongs_to :thesis

  validates :graduation_confirmed, exclusion: [nil]

  after_save :update_thesis_status

  # Given a row of CSV data from registrar import, update graduation
  # confirmed attribute (if needed) to true or false based on CSV data
  def set_graduated_from_csv(row)
    graduated = row['Degree Status'] == 'AW'
    if not self.graduation_confirmed == graduated
      self.update!(graduation_confirmed: graduated)
      Rails.logger.info("Author " + self.user.name + " graduation status updated to " + graduated.to_s)
    end
  end

  # The thesis' publication_status is recalculated every time the record is
  # saved, so in case this author's graduation status has changed, we force a
  # recalculation.
  def update_thesis_status
    self.thesis.save
  end
end
