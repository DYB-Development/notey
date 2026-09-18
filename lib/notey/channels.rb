# frozen_string_literal: true

module Notey
  class Channels
    def self.for(member, notification_type, account_id:)
      return [] unless Notey.catalog.declared?(notification_type)

      stored = stored_for(member, notification_type, account_id)
      return Notey.catalog.default_channels_for(notification_type) if stored.nil?

      Array(stored.channels).map(&:to_s)
    end

    def self.window_for(member, notification_type, account_id:)
      stored_for(member, notification_type, account_id)&.digest_window || "immediate"
    end

    def self.stored_for(member, notification_type, account_id)
      member.notey_preferences.find_by(account_id: account_id, notification_type: notification_type.to_s)
    end
    private_class_method :stored_for
  end
end
