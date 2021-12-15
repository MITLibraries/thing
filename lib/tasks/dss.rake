namespace :dss do
  desc 'Runs job to process DSS output queue'
  task process_output_queue: :environment do
    DspacePublicationResultsJob.perform_now
  end
end
