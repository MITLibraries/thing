class ZipTricksBag  
  def initialize(thesis)
    bag = Bag.new(thesis)
    tmp = bagamatic(bag, thesis)
    thesis.bag.attach(io: File.open(tmp),
                      filename: "#{bag.bag_name}.zip",
                      content_type: 'application/zip')
  end

  def bagamatic(bag, thesis)
    out = File.open("tmp/#{bag.bag_name}.zip", "wb")

    ZipTricks::Streamer.open(out) do | zip |

      # bag manifest
      zip.write_deflated_file('manifest-md5.txt') do |sink|
        sink << bag.manifest
      end

      # bag_declaration
      zip.write_deflated_file('bagit.txt') do |sink|
        sink << bag.bag_declaration
      end

      bag.data.each do |data|
        if data[1].kind_of?(String)
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
    out.close
    out
  end
end
