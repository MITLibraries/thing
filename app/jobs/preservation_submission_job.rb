class PreservationSubmissionJob < ActiveJob::Base
  require 'net/http'
  require 'uri'

  queue_as :default

  def perform(theses)
    Rails.logger.info("Preparing to send #{theses.count} theses to preservation")
    results = { total: theses.count, processed: 0, errors: [] }
    theses.each do |thesis|
      Rails.logger.info("Thesis #{thesis.id} is now being prepared for preservation")
      payload = thesis.archivematica_payloads.create!
      preserve_payload(payload)
      Rails.logger.info("Thesis #{thesis.id} has been sent to preservation")
      results[:processed] += 1
    rescue StandardError, Aws::Errors => e
      preservation_error = "Thesis #{thesis.id} could not be preserved: #{e}"
      Rails.logger.info(preservation_error)
      results[:errors] << preservation_error
    end
    ReportMailer.preservation_results_email(results).deliver_now if results[:total].positive?
  end

  private

  def preserve_payload(payload)
    post_payload(payload)
    payload.preservation_status = 'preserved'
    payload.preserved_at = DateTime.now
    payload.save!
  end

  def post_payload(payload)
    s3_url = ENV.fetch('APT_LAMBDA_URL', nil)
    uri = URI.parse(s3_url)
    request = Net::HTTP::Post.new(uri, { 'Content-Type' => 'application/json' })
    request.body = payload.payload_json

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    validate_response(response)
  end

  def validate_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to post Archivematica payload to APT: #{response.code} #{response.body}"
    end

    result = JSON.parse(response.body)
    unless result['success'] == true
      raise "APT failed to create a bag: #{response.body}"
    end
  end
end
