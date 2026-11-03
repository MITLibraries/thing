class Report
  delegate :url_helpers, to: 'Rails.application.routes'

  def card_empty_theses(collection)
    {
      'value' => collection.count,
      'verb' => %w[has have],
      'label' => 'no attached files'
    }
  end

  def card_files(collection, term)
    subset = collection.joins(:files_attachments)
    {
      'value' => subset.pluck(:id).uniq.count,
      'verb' => %w[has have],
      'label' => 'files attached',
      'note' => 'Only theses with a status of "Not ready for publication" and "Publication review" will be visible ' \
                'in the processing queue.',
      'link' => {
        'url' => url_helpers.thesis_select_path(graduation: term),
        'text' => "See #{subset.where('publication_status != ?', 'Published').pluck(:id).uniq.count} unpublished " \
                  'theses in processing queue'
      }
    }
  end

  def card_issues(collection)
    {
      'value' => collection.where('issues_found = ?', true).count,
      'label' => 'flagged with issues'
    }
  end

  def card_multiple_authors(collection)
    {
      'value' => collection.joins(:authors).group('theses.id').having('COUNT(authors.id) > 1').length,
      'verb' => %w[has have],
      'label' => 'multiple authors'
    }
  end

  def card_multiple_degrees(collection)
    {
      'value' => collection.joins(:degrees).group('theses.id').having('COUNT(degrees.id) > 1').length,
      'verb' => %w[has have],
      'label' => 'multiple degrees'
    }
  end

  def card_multiple_departments(collection)
    {
      'value' => collection.joins(:departments).group('theses.id').having('COUNT(departments.id) > 1').length,
      'verb' => %w[has have],
      'label' => 'multiple departments'
    }
  end

  def card_overall(collection, term)
    searchterm = term if term != 'all'
    {
      'value' => collection.count,
      'verb' => ['thesis record', 'thesis records'],
      'link' => {
        'url' => url_helpers.admin_theses_path(search: searchterm),
        'text' => 'See all in admin dashboard'
      }
    }
  end

  def card_student_contributions(collection)
    {
      'value' => collection.map(&:student_contributed?).count(true),
      'verb' => %w[has have],
      'label' => 'had metadata contributed by students'
    }
  end

  def data_category_copyright_holder(terms = nil)
    dashboard_category_data(Copyright.pluck(:holder), terms) do |theses|
      theses.joins(:copyright).group(:holder, :grad_date).count
    end
  end

  def data_category_department(terms = nil)
    dashboard_category_data(Department.pluck(:name_dw), terms) do |theses|
      theses.joins(:files_attachments).joins(:departments).group(:name_dw, :grad_date).distinct.count
    end
  end

  def data_category_license(terms = nil)
    dashboard_category_data(License.pluck(:display_description), terms) do |theses|
      theses.joins(:license).group(:display_description, :grad_date).count
    end
  end

  def data_category_publication_status(terms = nil)
    dashboard_category_data(Thesis.publication_statuses, terms) do |theses|
      theses.group(:publication_status, :grad_date).count
    end
  end

  def data_files_attached_to_theses(terms = nil)
    theses = Thesis.all
    theses = theses.where(grad_date: terms) if terms
    {
      label: 'Files attached to theses',
      data: pad_terms(theses.joins(:files_attachments).group(:grad_date).count, terms)
    }
  end

  def data_issues(terms = nil)
    theses = Thesis.all
    theses = theses.where(grad_date: terms) if terms
    {
      label: 'Flagged with issues',
      data: pad_terms(theses.where('issues_found = ?', true).group(:grad_date).count, terms)
    }
  end

  def data_multiple_authors(terms = nil)
    row_data = data_multiple_records(:authors, 'authors', terms)
    {
      label: 'Multiple authors',
      data: pad_terms(row_data, terms)
    }
  end

  def data_multiple_degrees(terms = nil)
    row_data = data_multiple_records(:degrees, 'degrees', terms)
    {
      label: 'Multiple degrees',
      data: pad_terms(row_data, terms)
    }
  end

  def data_multiple_departments(terms = nil)
    row_data = data_multiple_records(:departments, 'departments', terms)
    {
      label: 'Multiple departments',
      data: pad_terms(row_data, terms)
    }
  end

  def data_student_contributions(terms = nil)
    terms ||= Thesis.distinct.order(:grad_date).pluck(:grad_date)
    {
      label: 'Students contributing',
      data: pad_terms(student_contribution_counts(terms), terms)
    }
  end

  def data_authors_not_graduated(terms = nil)
    terms ||= Thesis.distinct.order(:grad_date).pluck(:grad_date)
    confirmed = Author.where(graduation_confirmed: true).select(:thesis_id)
    unconfirmed = Author.where(graduation_confirmed: false).select(:thesis_id)
    theses = Thesis.where(grad_date: terms)
    outstanding = theses.where(id: unconfirmed).or(theses.where.not(id: confirmed))
    row_data = outstanding.with_files.group(:grad_date).count
    {
      label: 'Authors not graduated',
      data: pad_terms(row_data, terms)
    }
  end

  def data_thesis_records(terms = nil)
    {
      label: 'Thesis records',
      data: pad_terms(dashboard_theses(terms).group(:grad_date).count, terms)
    }
  end

  def data_theses_with_files(terms = nil)
    {
      label: 'Theses with files',
      data: pad_terms(dashboard_theses(terms).joins(:files_attachments).group(:grad_date).distinct.count, terms)
    }
  end

  def index_data(terms = nil)
    output = {}
    output['summary'] = []
    output['summary'].push data_thesis_records(terms)
    output['summary'].push data_theses_with_files(terms)
    output['summary'].push data_files_attached_to_theses(terms)
    output['summary'].push data_issues(terms)
    output['summary'].push data_student_contributions(terms)
    output['summary'].push data_authors_not_graduated(terms)
    output['summary'].push data_multiple_authors(terms)
    output['summary'].push data_multiple_degrees(terms)
    output['summary'].push data_multiple_departments(terms)
    output['publication-status'] = []
    output['publication-status'].push(*data_category_publication_status(terms))
    output['copyright'] = []
    output['copyright'].push(*data_category_copyright_holder(terms))
    output['license'] = []
    output['license'].push(*data_category_license(terms))
    output['departments'] = []
    output['departments'].push(*data_category_department(terms))
    output
  end

  def empty_theses_data(collection)
    result = {}
    result['empty-theses'] = card_empty_theses collection
    result
  end

  def empty_theses_record(collection)
    result = {}
    result['empty-theses'] = record_empty_theses collection
    result
  end

  # This assumes a couple of things: first, that all items in a collection should be instances of the same model, and
  # second, that the model of any non-thesis collections belongs_to the Thesis model.
  def extract_terms(collection)
    if collection.first.is_a? Thesis
      collection.pluck(:grad_date).uniq.sort
    else
      collection.includes(:thesis).pluck(:grad_date).uniq.sort
    end
  end

  def record_empty_theses(collection)
    {
      title: 'Theses without files',
      data: collection
    }
  end

  def list_unattached_files(collection)
    result = []
    collection.joins(:files_attachments).order(:grad_date).uniq.each do |record|
      record.files.where(purpose: nil).each do |file|
        result.push(file)
      end
    end
    result
  end

  def list_proquest_files(collection)
    result = []
    collection.joins(:files_attachments).order(:grad_date).uniq.each do |record|
      record.files.where(purpose: 'proquest_form').each do |file|
        result.push(file)
      end
    end
    result
  end

  def list_student_submitted_metadata(collection)
    result = []
    collection.order(:grad_date).uniq.each do |record|
      next unless student_initiated_record?(record)

      result.push([record, record.versions.first.whodunnit])
    end
    result
  end

  def list_authors_not_graduated(collection)
    result = []
    collection.order(:grad_date).uniq.each do |record|
      next if record.authors_graduated?

      result.push(record)
    end
    result
  end

  def table_copyright(collection)
    result = {}
    collection.group(:copyright).count.each do |record|
      if record[0].instance_of?(NilClass)
        result['Undefined'] = record[1]
      else
        result[record[0].holder] = record[1]
      end
    end
    table_populate_defaults result, Copyright.pluck(:holder)
    {
      'title' => 'Thesis counts by copyright',
      'summary' => 'This table presents a summary of thesis records by their copyright status. The second column ' \
                   'names the copyright holder, while the first column shows how many records have that copyright.',
      'column' => 'Copyright holder',
      'data' => result
    }
  end

  def table_department(collection)
    result = collection.joins(:files_attachments).joins(:departments).group(:name_dw).distinct.count
    table_populate_defaults result, Department.pluck(:name_dw)
    {
      'title' => 'Thesis counts by department',
      'summary' => 'This table presents a summary of which departments have how many theses for the selected term. ' \
                   'The second column shows the programs at MIT which grant degrees, while the first column shows ' \
                   'how many theses have come from that program during this period.',
      'note' => 'Please note: total theses indicated by this table may be greater than the overall number of theses ' \
                'because some theses have multiple departments.',
      'column' => 'Department',
      'data' => result
    }
  end

  def table_license(collection)
    result = {}
    collection.group(:license).count.each do |record|
      if record[0].instance_of? NilClass
        result['Undefined'] = record[1]
      else
        result[record[0].display_description] = record[1]
      end
    end
    table_populate_defaults result, License.pluck(:display_description)
    {
      'title' => 'Thesis counts by Creative Commons license',
      'summary' => 'This table presents a summary of which Creative Commons license has been selected by the author, ' \
                   'for those theses for which the author retains copyright. The second column gives the specific CC ' \
                   'license selected, while the first column shows how many theses have selected it.',
      'note' => 'Please note: theses for which the author does not claim copyright will have "Undefined" in this ' \
                'field.',
      'column' => 'License',
      'data' => result
    }
  end

  def table_hold(collection)
    result = collection.joins(:hold_sources).group(:source).count
    table_populate_defaults result, HoldSource.pluck(:source)
    {
      'title' => 'Hold counts by hold source',
      'column' => 'Source',
      'data' => result
    }
  end

  def table_populate_defaults(data, values)
    values.each do |value|
      data[value] = 0 unless data[value]
    end
  end

  def table_status(collection)
    result = collection.group(:publication_status).count
    table_populate_defaults result, Thesis.publication_statuses
    {
      'title' => 'Thesis counts by publication status',
      'summary' => 'This table presents a summary of thesis records by their publication status. The second column ' \
                   'gives the status, while the first column gives how many records have that status.',
      'column' => 'Publication status',
      'data' => result
    }
  end

  def term_data(collection, term)
    result = {}
    result['overall'] = card_overall collection, term
    result['files'] = card_files collection, term
    result['issues'] = card_issues collection
    result['students-contributing'] = card_student_contributions collection
    result['multiple-authors'] = card_multiple_authors collection
    result['multiple-degrees'] = card_multiple_degrees collection
    result['multiple-departments'] = card_multiple_departments collection
    result
  end

  def term_tables(collection)
    result = {}
    result['status'] = table_status collection
    result['copyright'] = table_copyright collection
    result['license'] = table_license collection
    result['departments'] = table_department collection
    result['hold'] = table_hold collection
    result
  end

  private

  def pad_terms(data, terms = nil)
    # Given a hash of data for a single row of the reporting table, this will compare the data to the set of all
    # terms, adding zero values where needed to the simple iterator in the view will place them accurately.
    # Sample input (missing some terms)
    # {Mon, 01 Feb 2021=>1,
    #  Sat, 01 May 2021=>4,
    #  Tue, 01 Jun 2021=>2,
    #  Thu, 01 Sep 2022=>2}
    # Sample output (now with a value for every term)
    # {Fri, 01 Feb 1861=>0,
    #  Mon, 01 Feb 2021=>1,
    #  Sat, 01 May 2021=>4,
    #  Tue, 01 Jun 2021=>2,
    #  Sun, 01 May 2022=>0,
    #  Thu, 01 Sep 2022=>2}
    output = {}
    (terms || Thesis.pluck(:grad_date).uniq.sort).each do |term|
      output[term] = 0
      output[term] = data[term] if data.include? term
    end
    output
  end

  def dashboard_category_data(values, terms)
    rows = populate_category(values)
    yield(dashboard_theses(terms)).each do |(label, grad_date), count|
      rows[label][grad_date] = count
    end
    rows.map do |label, data|
      { label: label, data: pad_terms(data, terms) }
    end
  end

  def dashboard_theses(terms)
    terms ? Thesis.where(grad_date: terms) : Thesis.all
  end

  def student_contribution_counts(terms)
    student_ids = User.where(role: 'basic', admin: [false, nil]).reorder(nil)
                      .select('CAST(users.id AS TEXT)')
    PaperTrail::Version.joins('INNER JOIN theses ON theses.id = versions.item_id')
                       .where(item_type: 'Thesis', item_id: Thesis.where(grad_date: terms).select(:id),
                              whodunnit: student_ids)
                       .group('theses.grad_date').distinct.count('versions.item_id')
  end

  def data_multiple_records(association, table, terms)
    theses = dashboard_theses(terms).joins(association)
    multiple_ids = theses.group('theses.id').having("COUNT(#{table}.id) > 1").select(:id)
    dashboard_theses(terms).where(id: multiple_ids).group(:grad_date).count
  end

  def populate_category(array)
    # This builds out the initial set of a category of rows, based on a provided array (like
    # Thesis.publication_statuses).
    # Sample input (array of publication statuses)
    # ["Not ready for publication", "Publication review", "Pending publication", "Published"]
    # Sample output (hash ready for population)
    # {"Not ready for publication"=>{}, "Publication review"=>{}, "Pending publication"=>{}, "Published"=>{}}
    output = {}
    array.each do |item|
      output[item] = {}
    end
    output
  end

  def student_initiated_record?(record)
    record.versions.present? && record.versions.first.whodunnit && record.versions.first.whodunnit != 'registrar' &&
      User.find_by(id: record.versions.first.whodunnit).student?
  end
end
