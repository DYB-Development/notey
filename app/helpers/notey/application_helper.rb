module Notey
  module ApplicationHelper
    def chosen_channels(stored, notification_type)
      return Array(stored.channels).map(&:to_s) if stored

      Notey.catalog.default_channels_for(notification_type)
    end
  end
end
