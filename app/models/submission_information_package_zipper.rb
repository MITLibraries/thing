# SubmissionInformationPackageZipper creates a temporary zip file containing a bag and then attaches it via
# ActiveStorage. The `keygen` method creates the `path` to the file in S3. We are relying on S3 Replication to copy
# the objects from the ETD bucket to the Archivematica bucket. There is no automatic communication back from S3 or
# Archivematica to ETD, so we treat the successful save of the zip file as `preserved`.
class SubmissionInformationPackageZipper
  def initialize(sip)
    Tempfile.create([sip.bag_name.to_s, '.zip'], binmode: true) do |tmpfile|
      bagamatic(sip, tmpfile)

      sip.bag.attach(io: File.open(tmpfile),
                     key: keygen(sip),
                     filename: "#{sip.bag_name}.zip",
                     content_type: 'application/zip')
    end
  end

  private

  # This key needs to be unique. By default, ActiveStorage generates a UUID, but since we want a file path for our
  # Archivematica needs, we are generating a key. We handle uniqueness on the `bag_name` side.
  def keygen(sip)
    "etdsip/#{sip.thesis.accession_number}/#{sip.bag_name}.zip"
  end

  # bagamatic takes a sip, creates a temporary zip file, and returns that file
  def bagamatic(sip, tmpfile)
    ZipTricks::Streamer.open(tmpfile) do |zip|
      # bag manifest
      zip.write_deflated_file('manifest-md5.txt') do |sink|
        sink << sip.manifest
      end

      # bag_declaration
      zip.write_deflated_file('bagit.txt') do |sink|
        sink << sip.bag_declaration
      end

      # files. metadata.csv is just a string so we have to treat it differently than the binary stored files
      sip.data.each do |data|
        if data[1].is_a?(String)
          zip.write_deflated_file(data[0]) do |sink|
            sink << data[1]
          end
        else
          zip.write_stored_file(data[0]) do |sink|
            sink << data[1].download
          end
        end
      end
    end
    tmpfile.close
  end
end
