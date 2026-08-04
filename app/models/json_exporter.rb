class JsonExporter
  def initialize(thesis)
    @thesis = thesis
  end

  def to_hash
    {
      abstract:,
      advisors:,
      authors:,
      degrees:,
      departments:,
      dspace_url:,
      graduation_year:,
      title:
    }
  end

  private

  def abstract
    @thesis.abstract
  end

  def advisors
    @thesis.advisors.map do |advisor|
      { name: advisor.name }
    end
  end

  def authors
    @thesis.authors.map do |author|
      { name: author.user.preferred_name }
    end
  end

  def degrees
    @thesis.degrees.map do |degree|
      { abbreviation: degree.abbreviation }
    end
  end

  def departments
    @thesis.departments.map do |department|
      { name: department.name_dspace }
    end
  end

  def dspace_url
    "https://dspace.mit.edu/handle/#{@thesis.dspace_handle}"
  end

  def graduation_year
    @thesis.graduation_year
  end

  def title
    @thesis.title&.squish
  end
end
