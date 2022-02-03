class Marc
  attr_reader :record

  def initialize(thesis)
    @thesis = thesis
    @record = MARC::Record.new
    @record.leader = '00000nam a2200217Kc 4500'
    @record.append(MARC::ControlField.new('008', control008))
    data_fields
  end

  private

  def data_fields
    data040
    authors
    data245
    data264
    data300
    data336
    data337
    data338
    data347
    data502
    data520
    data655
    data856
    data992
  end

  def data040
    @record.append(MARC::DataField.new(
                     '040', ' ', ' ',
                     %w[a MYG],
                     %w[b env],
                     %w[e rda],
                     %w[c MYG]
                   ))
  end

  def authors
    field = '100'
    @thesis.authors.each do |author|
      @record.append(MARC::DataField.new(
                       field, '0', ' ',
                       ['a', author.user.preferred_name],
                       %w[e author.]
                     ))
      field = '700'
    end
  end

  def data245
    @record.append(MARC::DataField.new(
                     '245', '0', '0',
                     ['a', @thesis.title]
                   ))
  end

  def data264
    @record.append(MARC::DataField.new(
                     '264', ' ', '1',
                     ['a', 'Cambridge, Massachusetts'],
                     ['b', 'Massachusetts Institute of Technology'],
                     ['c', @thesis.graduation_year]
                   ))
  end

  def data300
    @record.append(MARC::DataField.new(
                     '300', ' ', ' ',
                     ['a', '1 online resource']
                   ))
  end

  def data336
    @record.append(MARC::DataField.new(
                     '336', ' ', ' ',
                     %w[a text],
                     %w[b txt],
                     %w[2 rdacontent]
                   ))
  end

  def data337
    @record.append(MARC::DataField.new(
                     '337', ' ', ' ',
                     %w[a computer],
                     %w[b c],
                     %w[2 rdamedia]
                   ))
  end

  def data338
    @record.append(MARC::DataField.new(
                     '338', ' ', ' ',
                     ['a', 'online resource'],
                     %w[b cr],
                     %w[2 rdacarrier]
                   ))
  end

  def data347
    @record.append(MARC::DataField.new(
                     '347', ' ', ' ',
                     ['a', 'text file'],
                     %w[b PDF],
                     %w[2 rda]
                   ))
  end

  def data502
    @thesis.degrees.each do |degree|
      @record.append(MARC::DataField.new(
                       '502', ' ', ' ',
                       ['b', degree.abbreviation]
                     ))
    end
    @thesis.departments.each do |dept|
      @record.append(MARC::DataField.new(
                       '502', ' ', ' ',
                       ['c', dept.name_dspace]
                     ))
    end
    @record.append(MARC::DataField.new(
                     '502', ' ', ' ',
                     ['d', @thesis.graduation_year]
                   ))
  end

  def data520
    @record.append(MARC::DataField.new(
                     '520', ' ', ' ',
                     ['a', @thesis.abstract]
                   ))
  end

  def data655
    @record.append(MARC::DataField.new(
                     '655', ' ', '7',
                     ['a', 'Academic theses.'],
                     %w[2 lcgft]
                   ))
  end

  def data856
    @record.append(MARC::DataField.new(
                     '856', '4', '0',
                     ['u', "https://dspace.mit.edu/handle/#{@thesis.dspace_handle}"]
                   ))
  end

  def data992
    @thesis.advisors.each do |advisor|
      @record.append(MARC::DataField.new(
                       '992', ' ', ' ',
                       ['a', advisor.name]
                     ))
    end
  end

  def control008
    field = []
    # digits 00-05: {YYMMDD} (i.e. the current date)
    field << DateTime.now.strftime('%y%m%d')
    # digit 06: "s"
    field << 's'
    # digits 07-10: {YYYY} (publication date)
    field << @thesis.graduation_year
    # digits 11-14: [blank][blank][blank][blank]
    field << '    '
    # digits 15-17: "mau"
    field << 'mau'
    # digits 18-21: [blank]s
    field << '    '
    # digit 22: [blank]
    field << ' '
    # digit 23: "o"
    field << 'o'
    # digit 24: "m"
    field << 'm'
    # digits 25-27: [blank]s
    field << '   '
    # digit 28: [blank]
    field << ' '
    # digit 29: "0"
    field << '0'
    # digit 30: "0"
    field << '0'
    # digit 31: "0"
    field << '0'
    # digit 32: [blank]
    field << ' '
    # digit 33: "0"
    field << '0'
    # digit 34: [blank]
    field << ' '
    # digits 35-37: "eng"
    field << 'eng'
    # digit 38: [blank]
    field << ' '
    # digit 39: "d"
    field << 'd'
    field.join
  end
end
