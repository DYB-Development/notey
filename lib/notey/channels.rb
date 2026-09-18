# frozen_string_literal: true

module Notey
  class Channels
    Decision = Struct.new(:channels, :window, keyword_init: true)

    def self.decision_for(member, notification_type, account_id:)
      return Decision.new(channels: [], window: "immediate") unless Notey.catalog.declared?(notification_type)

      stored = stored_for(member, notification_type, account_id)

      Decision.new(
        channels: stored ? Array(stored.channels).map(&:to_s) : Notey.catalog.default_channels_for(notification_type),
        window: stored&.digest_window || "immediate"
      )
    end

    def self.for(member, notification_type, account_id:)
      decision_for(member, notification_type, account_id: account_id).channels
    end

    def self.window_for(member, notification_type, account_id:)
      decision_for(member, notification_type, account_id: account_id).window
    end

    def self.stored_for(member, notification_type, account_id)
      member.notey_preferences.find_by(account_id: account_id, notification_type: notification_type.to_s)
    end
    private_class_method :stored_for
  end
end
