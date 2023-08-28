# == Schema Information
#
# Table name: accessions
#
#  id               :integer          not null, primary key
#  accession_number :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  degree_period_id :integer          not null
#

# Accession is where we store the Accession Number that is generated in our Archivematica system. It is used in this
# application to generate an S3 key that automations in Archivematica can detect and associate with Submission
# Information Packages (SIPs) for a single degree period with a single Accession number in Archivematica.
class ArchivematicaAccession < ApplicationRecord
  has_paper_trail
  belongs_to :degree_period

  validates_uniqueness_of :degree_period_id, message: 'already has an accession number'
  validates_uniqueness_of :accession_number
  validates :accession_number, presence: true,
                               format: {
                                 with: /\A(19|20)\d{2}_\d{3}\z/i,
                                 message: 'must match the format `YYYY_ddd`, where `YYYY` is a year between 1900 and ' \
                                          '2099, and `ddd` is a three-digit sequence number (e.g., 2023_001)'
                               }
end
