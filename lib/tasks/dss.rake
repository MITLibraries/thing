namespace :dss do
  desc 'Runs job to process DSS output queue'
  task process_output_queue: :environment do
    DspacePublicationResultsJob.perform_now
  end

  desc 'Publishes a single thesis to DSS'
  task :publish_thesis_by_id, [:thesis_id] => :environment do |_t, args|
    if args.thesis_id
      Rails.logger.info("Beginning manual publishing of thesis #{args.thesis_id}")
      thesis = Thesis.find(args.thesis_id)

      # Our publication job expects to be only sent theses that are ready to be published so we need to check here
      # `Publication review` is the normal status for theses entering this process, but we also allow
      # `Pending publication` to allow us to bump jobs that didn't make it to the SQS queue for any reason.
      if ['Publication review', 'Pending publication'].include?(thesis.publication_status)
        DspacePublicationJob.perform_now(thesis)
      else
        Rails.logger.info("Thesis status of #{thesis.publication_status} is not publishable.")
      end
    else
      Rails.logger.info('No thesis ID provided')
    end
  end
end
