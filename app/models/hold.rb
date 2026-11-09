# == Schema Information
#
# Table name: holds
#
#  id               :integer          not null, primary key
#  case_number      :string
#  date_end         :date             not null
#  date_requested   :date             not null
#  date_start       :date             not null
#  processing_notes :text
#  status           :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  hold_source_id   :integer          not null
#  thesis_id        :integer          not null
#
# Indexes
#
#  index_holds_on_hold_source_id  (hold_source_id)
#  index_holds_on_thesis_id       (thesis_id)
#
# Foreign Keys
#
#  hold_source_id  (hold_source_id => hold_sources.id)
#  thesis_id       (thesis_id => theses.id)
#
class Hold < ApplicationRecord
  has_paper_trail

  belongs_to :thesis
  belongs_to :hold_source
  has_many :users, through: :thesis

  enum :status, %i[active expired released]

  validates :date_requested, presence: true
  validates :date_start, presence: true
  validates :date_end, presence: true
  validates :hold_source, presence: true
  validates :status, presence: true
  validates :thesis, presence: true

  after_save :update_thesis_status
  after_destroy :update_thesis_status

  scope :active_or_expired, -> { Hold.active.or(Hold.expired) }
  scope :ends_today_or_before, -> { where('date_end <= ?', Date.current) }

  def degrees
    thesis.degrees.map(&:name_dw).join("\n")
  end

  def grad_date
    thesis.grad_date
  end

  def author_names
    thesis.users.map(&:name).join('; ')
  end

  def created_by
    return unless versions.present? && versions.first.event == 'create'

    creator_id = versions.first.whodunnit
    if (user = User.find_by(id: creator_id))
      user.kerberos_id
    else
      "User ID #{creator_id} no longer active."
    end
  end

  # This may later list just the info for the file flagged 'primary', once
  # we implement that feature.
  def dates_thesis_files_received
    return unless thesis.present? && thesis.files.present?

    thesis.files.map do |file|
      "#{file.created_at.strftime('%Y-%m-%d')} (#{file.blob.filename})"
    end.join('; ')
  end

  # In the unlikely scenario that the the status was changed to 'released'
  # multiple times, this assumes we want the most recent date released.
  def date_released
    released_versions = versions.select do |version|
      next unless version.changeset['status'].present?

      # We check for the integer 2 here because that corresponds with 'released', and PT has been incorrectly storing
      # all enum values as integers since we started using it. That is fixed now that we migrated to JSON, but it
      # remains a problem with historical data.
      ['released', 2].include?(version.changeset['status'][1])
    end
    dates_released = released_versions.map { |version| version.changeset['updated_at'][1] }
    dates_released.max
  end

  # Saving recalculates readiness for both the held thesis and related theses.
  def update_thesis_status
    thesis_ids = [thesis_id, thesis_id_before_last_save].compact.uniq
    user_ids = Author.where(thesis_id: thesis_ids).select(:user_id)
    related_thesis_ids = Author.where(user_id: user_ids).select(:thesis_id)
    Thesis.where(id: thesis_ids).or(Thesis.where(id: related_thesis_ids)).find_each(&:save)
  end
end
