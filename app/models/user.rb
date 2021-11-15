# == Schema Information
#
# Table name: users
#
#  id             :integer          not null, primary key
#  uid            :string           not null
#  email          :string           not null
#  admin          :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  role           :string           default("basic")
#  given_name     :string
#  surname        :string
#  kerberos_id    :string           not null
#  display_name   :string           not null
#  middle_name    :string
#  preferred_name :string
#  orcid          :string
#

class User < ApplicationRecord
  has_paper_trail

  # We need to initialize  some fields before validation, or
  # the record won't save.
  before_validation(on: :create) do
    self.kerberos_id = kerb unless kerberos_id
    self.display_name = name unless display_name
    self.uid = "#{kerberos_id}@mit.edu" unless uid
  end

  # Display name should be aligned with preferred name
  before_update do
    self.display_name = name
  end

  # ORCID has a unique constraint, so if it's empty, we need to save it
  # as nil instead of an empty string
  before_save do
    self.orcid = nil if orcid == ''
  end

  default_scope { order('surname ASC') }

  if Rails.configuration.fake_auth_enabled # Use config, not ENV. See README.
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :uid, presence: true # , uniqueness: true
  validates :email, presence: true
  validates :display_name, presence: true
  validates :kerberos_id, presence: true
  has_many :authors
  has_many :theses, through: :authors, dependent: :restrict_with_error
  has_many :transfers
  has_many :submitters
  has_many :departments, through: :submitters

  ROLES = %w[basic processor thesis_admin].freeze
  validates_inclusion_of :role, in: ROLES

  # `uid` is a unique ID that comes back from OmniAuth (which gets it from
  # the remote authentication provider). It is used to lookup or create a new
  # local user via this method.
  # Touchstone and fake_auth put this UID in different places.
  def self.from_omniauth(auth)
    uid = if auth.info.key? 'uid'
            auth.info.uid
          else
            auth.uid
          end

    User.where(uid: uid).first_or_create do |user|
      user.email = auth.info.email
      user.given_name = auth.info.given_name
      user.surname = auth.info.surname
      user.display_name = auth.info.display_name
    end
  end

  # Given a row of CSV data from Registrar import, find a user by Kerberos ID
  # and update all user attributes for which the Registrar is the authoritative
  # data source, or create a new user from the CSV data if not found.
  def self.create_or_update_from_csv(row)
    user = User.find_by(kerberos_id: row['Krb Name'])
    if user.nil?
      new_user = User.create!(
        kerberos_id: row['Krb Name'],
        email: row['Email Address'].downcase,
        given_name: row['First Name'],
        surname: row['Last Name'],
        middle_name: row['Middle Name'],
        preferred_name: row['Full Name']
      )
      Rails.logger.info("New user created: #{new_user.name}")
      new_user
    else
      user.email = row['Email Address'].downcase
      user.given_name = row['First Name']
      user.surname =  row['Last Name']
      user.middle_name = row['Middle Name']
      user.preferred_name = row['Full Name'] if user.preferred_name.blank?
      user.save
      Rails.logger.info("User updated: #{user.name}")
      user
    end
  end

  # This convenience method returns the list of the user's theses for which the user can submit metadata. The current
  # logic is to return only theses for which two conditions are true:
  # 1. The metadata_complete flag is set to false
  # 2. The issues_flag false is set to false
  def editable_theses
    theses.where(metadata_complete: false).where(issues_found: false)
  end

  # Definitely for sure wrong for some people. But staff want to be able to
  # sort on surname for processing purposes, so we're getting given name +
  # surname. This could pose a problem for those who prefer not to use
  # their legal surname. In an effort to make as few assumptions about
  # identity as possible, we are privileging preferred names for sorting.
  def name
    if preferred_name.present?
      preferred_name.to_s
    elsif surname.present? && given_name.present? && middle_name.present?
      "#{surname}, #{given_name} #{middle_name.first}."
    elsif surname.present? && given_name.present?
      "#{surname}, #{given_name}"
    else
      email.to_s
    end
  end

  # We want to ensure that the email always appears in the processing
  # queue names, but not elsewhere in the application.
  def processing_queue_name
    name.include?(email) ? name.to_s : "#{name} (#{email})"
  end

  # Certain ability checks may be easier when testing for a boolean, rather
  # than the length of the submittable_departments list.
  def submitter?
    return true if submittable_departments.count.positive?
  end

  # Users with the "thesis_admin" role, or the admin flag, can submit
  # transfers for any department. Users with a submitter relationship to a
  # department can only access those departments.
  def submittable_departments
    if role == 'thesis_admin' || admin
      Department.all.order(:name_dw)
    else
      departments.order(:name_dw)
    end
  end

  # The student-submitted metadata report looks for theses that are created by students, based on whether the first
  # version of the thesis has a whodunnit. Since thesis processors may create a thesis for a student, this method helps
  # us determine whether a thesis creator is a student based on their role in the ability model.
  def student?
    role == 'basic' && !admin?
  end

  private

  # For our purposes, kerberos_id is EPPN (uid) without '@mit.edu'
  def kerb
    uid&.delete_suffix('@mit.edu')
  end
end
