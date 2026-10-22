# DSpace chokes on certain unicode characters. If a thesis has files that contain one of these
# characters, DSpace will allow publication, but it won't allow end users to download the files.
#
# This helper class exists to normalize filenames to remove characters that DSpace struggles with.
# Thus far, we've learned that decomposed diacritics, zero-width spaces, and en-dashes all cause
# issues. We normalize characters beyond this set that we suspect might also be problematic (e.g.,
# all dash variants, directional diacritics).

class FilenameNormalizer
  def self.comparison_key(filename)
    ActiveStorage::Filename.new(sanitize_filename(filename.to_s)).to_s
  end

  def self.sanitize_filename(filename)
    # Remove zero-width spaces and directional marks
    normalized = filename.gsub(/[\u200B\u200C\u200D\u200E\u200F\u202A-\u202E]/, '')

    # Change decomposed accented characters to precomposed
    normalized = normalized.unicode_normalize(:nfc)

    # Convert dash variants to normal hyphens
    normalized.gsub(/[\u2010-\u2015]/, '-')
  end
end
