module Checksums
  def base64_to_hex(base64_string)
    Base64.decode64(base64_string).each_byte.map { |b| format('%02x', b.to_i) }.join
  end
end
