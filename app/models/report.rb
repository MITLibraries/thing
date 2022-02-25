class Report
  delegate :url_helpers, to: 'Rails.application.routes'

  def card_empty_theses(collection)
    {
      'value' => collection.count,
      'verb' => 'has',
      'label' => 'no attached files'
    }
  end

  def card_files(collection, term)
    subset = collection.joins(:files_attachments)
    {
      'value' => subset.pluck(:id).uniq.count,
      'verb' => 'has',
      'label' => 'files attached',
      'note' => 'Only theses with a status of "Not ready for publication" and "Publication review" will be visible '\
                'in the processing queue.',
      'link' => {
        'url' => url_helpers.thesis_select_path(graduation: term),
        'text' => "See #{subset.where('publication_status != ?', 'Published').pluck(:id).uniq.count} unpublished "\
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
      'verb' => 'has',
      'label' => 'multiple authors'
    }
  end

  def card_multiple_degrees(collection)
    {
      'value' => collection.joins(:degrees).group('theses.id').having('COUNT(degrees.id) > 1').length,
      'verb' => 'has',
      'label' => 'multiple degrees'
    }
  end

  def card_multiple_departments(collection)
    {
      'value' => collection.joins(:departments).group('theses.id').having('COUNT(departments.id) > 1').length,
      'verb' => 'has',
      'label' => 'multiple departments'
    }
  end

  def card_overall(collection, term)
    searchterm = term if term != 'all'
    {
      'value' => collection.count,
      'verb' => 'thesis record',
      'link' => {
        'url' => url_helpers.admin_theses_path(search: searchterm),
        'text' => 'See all in admin dashboard'
      }
    }
  end

  def card_student_contributions(collection)
    {
      'value' => collection.map(&:student_contributed?).count(true),
      'verb' => 'has',
      'label' => 'had metadata contributed by students'
    }
  end

  def data_category_copyright_holder
    category = []
    rows = populate_category(Copyright.pluck(:holder))
    Thesis.all.joins(:copyright).group(:holder).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_category_department
    category = []
    rows = populate_category(Department.pluck(:name_dw))
    Thesis.all.joins(:files_attachments).joins(:departments).group(:name_dw).group(:grad_date).distinct.count
          .each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_category_license
    category = []
    rows = populate_category(License.pluck(:display_description))
    Thesis.all.joins(:license).group(:display_description).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_category_publication_status
    category = []
    rows = populate_category(Thesis.publication_statuses)
    Thesis.all.group(:publication_status).group(:grad_date).count.each do |item|
      rows[item[0][0]][item[0][1]] = item[1]
    end
    rows.each do |row|
      category.push({
                      label: row[0],
                      data: pad_terms(row[1])
                    })
    end
    category
  end

  def data_files_attached_to_theses
    {
      label: 'Files attached to theses',
      data: pad_terms(Thesis.all.joins(:files_attachments).group(:grad_date).count)
    }
  end

  def data_issues
    {
      label: 'Flagged with issues',
      data: pad_terms(Thesis.all.group(:grad_date).where('issues_found = ?', true).count)
    }
  end

  def data_multiple_authors
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(t.id) as pop
      FROM (
        SELECT theses.id, theses.grad_date, count(theses.id) as authors
        FROM theses
        INNER JOIN authors a on theses.id = a.thesis_id
        GROUP BY theses.id
        HAVING count(a.id) > 1
      ) AS t
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Multiple authors',
      data: pad_terms(row_data)
    }
  end

  def data_multiple_degrees
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(t.id) as pop
      FROM (
        SELECT theses.id, theses.grad_date, count(theses.id) as authors
        FROM theses
        INNER JOIN degree_theses link ON theses.id = link.thesis_id
        INNER JOIN degrees d on link.degree_id = d.id
        GROUP BY theses.id
        HAVING count(d.id) > 1
      ) AS t
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Multiple degrees',
      data: pad_terms(row_data)
    }
  end

  def data_multiple_departments
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(t.id) as pop
      FROM (
        SELECT theses.id, theses.grad_date, count(theses.id) as authors
        FROM theses
        INNER JOIN department_theses link ON theses.id = link.thesis_id
        INNER JOIN departments d on link.department_id = d.id
        GROUP BY theses.id
        HAVING count(d.id) > 1
      ) AS t
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Multiple departments',
      data: pad_terms(row_data)
    }
  end

  def data_student_contributions
    row_data = {}
    terms = Thesis.all.pluck(:grad_date).uniq.sort
    terms.each do |term|
      row_data[term] = Thesis.where('grad_date = ?', term).includes(:versions).map(&:student_contributed?).count(true)
    end
    {
      label: 'Students contributing',
      data: pad_terms(row_data)
    }
  end

  def data_thesis_records
    {
      label: 'Thesis records',
      data: pad_terms(Thesis.all.group(:grad_date).count)
    }
  end

  def data_theses_with_files
    row_data = {}
    query = <<~SQL
      SELECT t.grad_date, count(distinct t.id) AS pop
      FROM theses t
      INNER JOIN active_storage_attachments a ON t.id = a.record_id
      WHERE a.record_type = 'Thesis'
      GROUP BY t.grad_date;
    SQL
    ActiveRecord::Base.connection.exec_query(query).each do |item|
      row_data[Date.parse(item['grad_date'])] = item['pop']
    end
    {
      label: 'Theses with files',
      data: pad_terms(row_data)
    }
  end

  def index_data
    output = {}
    output['summary'] = []
    output['summary'].push data_thesis_records
    output['summary'].push data_theses_with_files
    output['summary'].push data_files_attached_to_theses
    output['summary'].push data_issues
    output['summary'].push data_student_contributions
    output['summary'].push data_multiple_authors
    output['summary'].push data_multiple_degrees
    output['summary'].push data_multiple_departments
    output['publication-status'] = []
    output['publication-status'].push(*data_category_publication_status)
    output['copyright'] = []
    output['copyright'].push(*data_category_copyright_holder)
    output['license'] = []
    output['license'].push(*data_category_license)
    output['departments'] = []
    output['departments'].push(*data_category_department)
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
      'summary' => 'This table presents a summary of thesis records by their copyright status. The second column '\
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
      'summary' => 'This table presents a summary of which departments have how many theses for the selected term. '\
                   'The second column shows the programs at MIT which grant degrees, while the first column shows how '\
                   'many theses have come from that program during this period.',
      'note' => 'Please note: total theses indicated by this table may be greater than the overall number of theses '\
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
      'summary' => 'This table presents a summary of which Creative Commons license has been selected by the author, '\
                   'for those theses for which the author retains copyright. The second column gives the specific CC '\
                   'license selected, while the first column shows how many theses have selected it.',
      'note' => 'Please note: theses for which the author does not claim copyright will have "Undefined" in this '\
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
      'summary' => 'This table presents a summary of thesis records by their publication status. The second column '\
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

  def pad_terms(data)
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
    Thesis.pluck(:grad_date).uniq.sort.each do |term|
      output[term] = 0
      output[term] = data[term] if data.include? term
    end
    output
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
