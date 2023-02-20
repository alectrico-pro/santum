require 'action_cable/subscription_adapter/redis'

ActionCable::SubscriptionAdapter::Redis.class_eval do
  cattr_accessor :redis_connector, default: ->(config) do
    ::Redis.new(config.except(:id, :adapter, :channel_prefix))
  end
end

