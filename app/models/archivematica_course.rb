class ArchivematicaCourse
  # If `code_dw` is a numeric code, pad to two digits.
  # If `code_dw` starts with a number, preface it with `Course_`
  # If `code_dw` is not numeric, use it without modification.
  def self.format_course(code_dw)
    return code_dw unless starts_with_number?(code_dw)
    # if entirely numeric, pad it
    return "Course_#{format('%02d', code_dw.to_i)}" if numeric?(code_dw)

    "Course_#{code_dw}"
  end

  def self.numeric?(string)
    true if Float(string)
  rescue StandardError
    false
  end

  def self.starts_with_number?(string)
    true if Float(string[0])
  rescue StandardError
    false
  end
end
