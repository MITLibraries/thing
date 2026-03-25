Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :session
  strategy :default

  feature :maintenance_mode,
    default: ENV.fetch('MAINTENANCE_MODE', false),
    description: "Put application in maintenance mode, disabling file transfer uploads."

  feature :dspace_v8_metadata,
    default: ENV.fetch('DSPACE_V8_METADATA', false),
    description: "Use DSpace 8 metadata format instead of DSpace 6 metadata format."
end
