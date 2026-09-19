# frozen_string_literal: true

module Notey
  class Catalog
    Notification = Struct.new(:channels, :default, keyword_init: true)

    def initialize
      @notifications = {}
      @addressed = []
    end

    def addressed(*channels)
      return @addressed if channels.empty?

      @addressed |= channels.map(&:to_s)
    end

    def notification(name, channels: [], default: [])
      @notifications[name.to_s] = Notification.new(
        channels: Array(channels).map(&:to_s),
        default: Array(default).map(&:to_s)
      )
    end

    def notifications
      @notifications
    end

    def channels
      @notifications.values.flat_map(&:channels).uniq
    end

    def declared?(notification_type)
      @notifications.key?(notification_type.to_s)
    end

    def channels_for(notification_type)
      declared(notification_type)&.channels || []
    end

    def default_channels_for(notification_type)
      declared(notification_type)&.default || []
    end

    private

    def declared(notification_type)
      @notifications[notification_type.to_s]
    end
  end
end
