# == Schema Information
#
# Table name: users
#
#  id         :integer          not null, primary key
#  uid        :string           not null
#  email      :string           not null
#  admin      :boolean          default(FALSE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  role       :string           default("basic")
#  given_name :string
#  surname    :string
#

class User < ApplicationRecord
  default_scope { order('surname ASC') }

  if Rails.configuration.fake_auth_enabled  # Use config, not ENV. See README.
    devise :omniauthable, omniauth_providers: [:developer]
  else
    devise :omniauthable, omniauth_providers: [:saml]
  end

  validates :uid, presence: true #, uniqueness: true
  validates :email, presence: true
  has_many :theses

  ROLES = %w[basic processor thesis_admin sysadmin]
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
    end
  end

  # Definitely for sure wrong for some people. But staff want to be able to
  # sort on surname for processing purposes, so we're getting given name +
  # surname.
  def name
    if self.surname && self.given_name
      "#{self.surname}, #{self.given_name} (#{self.email})"
    else
      "#{self.email}"
    end
  end

  # We should really be getting the displayName property from Touchstone, but
  # that was a scope creep at the time this feature was implemented.
  def display_name
    if self.surname && self.given_name
      "#{self.given_name} #{self.surname} (#{self.email})"
    else
      "#{self.email}"
    end
  end
end
