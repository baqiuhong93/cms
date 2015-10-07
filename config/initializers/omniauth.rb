# Change this omniauth configuration to point to your registered provider
# Since this is a registered application, add the app id and secret here
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :josh_id, "test", "test"
end
