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
  # We need to initialize  some fields before validation, or 
  # the record won't save.
  before_validation(on: :create) do
    self.kerberos_id = kerb unless self.kerberos_id
    self.display_name = name unless self.display_name
    self.uid = self.kerberos_id + '@mit.edu' unless self.uid
  end

  # Display name should be aligned with preferred name
  before_update do
    self.display_name = name
  end

  # ORCID has a unique constraint, so if it's empty, we need to save it 
  # as nil instead of an empty string
  before_save do
    self.orcid = nil if self.orcid == ""
  end

  default_scope { order('surname ASC') }

  if Rails.configuration.fake_auth_enabled  # Use config, not ENV. See README.
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :uid, presence: true #, uniqueness: true
  validates :email, presence: true
  validates :display_name, presence: true
  validates :kerberos_id, presence: true
  has_many :authors
  has_many :theses, through: :authors, dependent: :restrict_with_error
  has_many :transfers
  has_many :submitters
  has_many :departments, through: :submitters

  ROLES = %w[basic processor thesis_admin]
  validates_inclusion_of :role, :in => ROLES

  # `uid` is a unique ID that comes back from OmniAuth (which gets it from
  # the remote authentication provider). It is used to lookup or create a new
  # local user via this method.
  # Touchstone and fake_auth put this UID in different places.
  def self.from_omniauth(auth)
    if auth.info.key? 'uid'
      uid = auth.info.uid
    else
      uid = auth.uid
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
      Rails.logger.info("New user created: " + new_user.name)
      return new_user
    else
      user.email = row['Email Address'].downcase
      user.given_name = row['First Name']
      user.surname =  row['Last Name']
      user.middle_name = row['Middle Name']
      user.preferred_name = row['Full Name'] if user.preferred_name.blank?
      user.save
      Rails.logger.info("User updated: " + user.name)
      return user
    end
  end

  # This convenience method returns the list of the user's theses for which
  # the user can submit metadata. The logic regarding which theses qualify for
  # this list may be subject to change; initially this is all theses for which
  # the "metadata_complete" flag is not set.
  def editable_theses
    self.theses.where(metadata_complete: false)
  end

  # Definitely for sure wrong for some people. But staff want to be able to
  # sort on surname for processing purposes, so we're getting given name +
  # surname. This could pose a problem for those who prefer not to use 
  # their legal surname. In an effort to make as few assumptions about 
  # identity as possible, we are privileging preferred names for sorting.
  def name
    if self.preferred_name.present?
      "#{self.preferred_name}"
    elsif self.surname.present? && self.given_name.present? && self.middle_name.present?
      "#{self.surname}, #{self.given_name} #{self.middle_name.first}."
    elsif self.surname.present? && self.given_name.present?
      "#{self.surname}, #{self.given_name}"
    else
      "#{self.email}"
    end
  end

  # We want to ensure that the email always appears in the processing 
  # queue names, but not elsewhere in the application.
  def processing_queue_name
    self.name.include?(self.email) ? "#{self.name}" : "#{self.name} (#{self.email})"
  end

  # Certain ability checks may be easier when testing for a boolean, rather
  # than the length of the submittable_departments list.
  def submitter?
    return true if submittable_departments.count > 0
  end

  # Users with the "thesis_admin" role, or the admin flag, can submit
  # transfers for any department. Users with a submitter relationship to a
  # department can only access those departments.
  def submittable_departments
    if role == "thesis_admin" || admin
      Department.all.order(:name_dw)
    else
      departments.order(:name_dw)
    end
  end

  private

    # For our purposes, kerberos_id is EPPN (uid) without '@mit.edu'
    def kerb
      self.uid.delete_suffix('@mit.edu') if uid
    end
end
