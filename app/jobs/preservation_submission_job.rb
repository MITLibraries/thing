class PreservationSubmissionJob < ActiveJob::Base
  require 'net/http'
  require 'uri'

  queue_as :default

  # Custom error class for 502 Bad Gateway responses from APT
  class APTBadGatewayError < StandardError; end

  # Retry up to 10 times for transient 502 Bad Gateway responses. These 502 errors are generally caused by the lambda
  # entering `Inactive` state after a long period of inactivity, which can take several minutes to recover from.
  # We are using a fixed wait time of 5 minutes between retries to give the lambda time to warm up, rather than
  # retrying immediately with exponential backoff as we expect the first few retries to fail in that scenario so this
  # longer time is more effective.
  retry_on APTBadGatewayError, wait: 5.minutes, attempts: 10

  def perform(theses)
    Rails.logger.info("Preparing to send #{theses.count} theses to preservation")
    results = { total: theses.count, processed: 0, errors: [] }
    theses.each do |thesis|
      Rails.logger.info("Thesis #{thesis.id} is now being prepared for preservation")
      payload = thesis.archivematica_payloads.create!
      preserve_payload(payload)
      Rails.logger.info("Thesis #{thesis.id} has been sent to preservation")
      results[:processed] += 1
    rescue StandardError => e
      # Explicitly re-raise the 502-specific error so ActiveJob can retry it.
      raise e if e.is_a?(APTBadGatewayError)

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

    # If the remote endpoint returns 502, raise a APTBadGatewayError so ActiveJob can retry.
    if response.code.to_s == '502'
      Rails.logger.warn("Received 502 from APT for payload #{payload.id}; raising for retry")
      raise APTBadGatewayError, 'APT returned 502 Bad Gateway'
    end

    validate_response(response)
  end

  def validate_response(response)
    unless response.is_a?(Net::HTTPSuccess)
      raise "Failed to post Archivematica payload to APT: #{response.code} #{response.body}"
    end

    result = JSON.parse(response.body)
    return if result['success'] == true

    raise "APT failed to create a bag: #{response.body}"
  end
end
