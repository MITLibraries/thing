Flipflop.configure do
  # Strategies will be used in the order listed here.
  strategy :session
  strategy :default

  feature :maintenance_mode,
    default: ENV.fetch('MAINTENANCE_MODE', false),
    description: "Put application in maintenance mode, disabling file transfer uploads."
end
