Rails.application.configure do
  unless ENV["DISABLE_LOGRAGE"].present?
    config.lograge.enabled = true
  end

  config.lograge.custom_options = lambda do |event|
    exceptions = %w(controller action format id)
    {
      params: event.payload[:params].except(*exceptions),
      time: Time.now.utc().iso8601(3),
    }
  end

  # This is mostly only useful when central logging is set up
  config.lograge.custom_payload do |controller|
    {
      host: controller.request.host
    }
  end
end
