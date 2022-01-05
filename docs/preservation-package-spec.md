# Preservation Package Specification

All theses submitted to the ETD system will be sent to preservation submission storage after they have been published to DSpace. From preservation submission storage they will be ingested into preservation (AIP) storage via Archivematica with additional metadata sent into ArchivesSpace by digital preservation/archives staff. Archivematica ingest requires a specific [submission structure](https://www.archivematica.org/en/docs/archivematica-1.13/user-manual/transfer/bags/#bags) and [metadata format](https://www.archivematica.org/en/docs/archivematica-1.13/user-manual/transfer/import-metadata/#metadata-bags) outlined below. Every thesis submitted to preservation must be packaged according to this specification.

## Package structure

Each thesis must be submitted as a single zipped bag according to the [bagit specification](https://datatracker.ietf.org/doc/html/rfc8493). The bag should include all files and metadata associated with the thesis, and must be structured as follows. See file [1721.1_123456-thesis.zip](1721.1_123456-thesis.zip) in this project's docs folder for an example bag structured according to these requirements.

- _dspace_handle_-thesis.zip The top-level folder must be a zipped bag named with the
  thesis's DSpace handle followed by "-thesis.zip"
  - data/ There must be a folder in the bag named "data", containing all files associated with the thesis
    - metadata/ There must be a folder in the "data" folder named "metadata", containing exactly one file of the metadata for the thesis
      - metadata.csv The metadata file must be named "metadata.csv". See [Metadata File section](#metadata-file) below for details on the contents of this file
    - _last-kerberos-DEG-DEP-YYYY_-thesis.pdf The data folder must at minimum contain the PDF representation of the thesis
    - _last-kerberos-DEG-DEP-YYYY-supplemental1.txt_ The data folder may additionally contain any other files submitted with the thesis including supplementary files, signature pages, etc
  - bag-info.txt Per the bagit specfication, the bag may contain a bag-info.txt file with additional information. Note: this file is optional, but if it is included it must contain the payload-oxum field with a correct value, otherwise Archivematica will reject the bag.
  - bagit.txt Per the bagit specfication, the bag must contain a bagit.txt file with the required contents
  - manifest-_algorithm_.txt Per the bagit specfication, the bag must contain at least one manifest-_algorithm_.txt file containing the checksum and file path of each file in the data folder, where _algorithm_ in the file name should be the cryptographic hash algorithm use to create the checksums, e.g. "sha256"
  - tagmanifest-_algorithm_.txt Per the bagit specfication, the bag may contain at least one tagmanifest-_algorithm_.txt file containing the checksum and file path of each bagit-related file in the top-level bag folder (except for this file itself, which cannot contain its own checksum), where _algorithm_ in the file name should be the cryptographic hash algorithm use to create the checksums, e.g. "sha256"

## Metadata File

See file [1721.1_123456-thesis.zip/data/metadata/metadata.csv](1721.1_123456-thesis.zip/data/metadata/metadata.csv) in this project's docs folder for an metadata file structured according to these requirements.

All metadata about the thesis must be in a single CSV file with a column for each metadata field and a row for each file associated with the thesis. All characters in this file must be utf-8 encoded, otherwise Archivematica will be unhappy.

Thesis-level metadata  (title, abstract, author, etc.) should be in the row for the thesis PDF file. Repeated fields must have a column for each instance of the field in the metadata. Note: If a rights field includes the copyright character, it must be UTF-8 encoded in the CSV file for Archivematica to parse it correctly.

Other files included in the CSV should have blank values for any fields not directly related to the file -- fields associated with the thesis such as title, abstract, author should be blank, but fields specific to the file such as BitstreamChecksumValue should have the value present in the row for that file.

In addition to the metadata submitted to DSpace, some additional fields are required for preservation and should each have their own column in the CSV file. These are:
- filename: path to file in this bag, e.g. "data/duck-daffy88-SM-RED-2021-signature.pdf"
- Level_of_DPCommitment: string value "Level 3" (only include for the thesis PDF)
- dcterms.isPartOf: string value "AIC#Course_department-code_theses" where _department-code_ is the Data Warehouse department code for the department, e.g. "21". For departments where the code is a single-digit number, the number must be zero-padded to two decimal places, e.g. "01". "Course" is included in this field for numeric departments only, so for example a department such as SDM would be "AIC#SDM_theses" and NOT "AIC#Course_SDM_theses".