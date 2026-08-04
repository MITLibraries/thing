namespace :metadata do
  desc 'Generate a JSON export of a single published thesis for testing'
  task :json_export_thesis, [:thesis_id] => :environment do |_t, args|
    if args.thesis_id.blank?
      puts 'No thesis ID provided.'
      next
    end

    thesis = Thesis.find(args.thesis_id)

    if thesis.publication_status == 'Published'
      json_exporter = JsonExporter.new(thesis)
      json_data = json_exporter.to_hash

      puts "JSON Export for Thesis #{args.thesis_id}:"
      puts JSON.pretty_generate(json_data)
    else
      puts "Thesis status of #{thesis.publication_status} cannot be exported. Only published theses can be exported."
    end
  end

  desc 'Generate a JSON export batch for a specific term (e.g., "2024-June") and save to temp file'
  task :json_export_batch, %i[term output_file] => :environment do |_t, args|
    if args.term.blank?
      puts 'Usage: rake metadata:json_export_batch["2024-June","output.json"]'
      puts 'Term format: YYYY-Month (e.g., 2024-June, 2024-September)'
      next
    end

    year, month_name = args.term.split('-')
    query_date = Date.parse("1 #{month_name} #{year}")

    output_file = args.output_file || Rails.root.join("tmp/json_export_#{args.term}_#{DateTime.now.utc.strftime('%H_%M')}.json").to_s

    theses = Thesis.published.where(grad_date: query_date.all_month)

    if theses.any?
      json_batch = JsonBatch.new(theses, File.basename(output_file))
      json_file = json_batch.build
      FileUtils.cp(json_file.path, output_file)
      json_file.close
      puts "Exported #{theses.count} theses to: #{output_file}"
    else
      puts "No published theses found for #{args.term}"
    end
  end
end
