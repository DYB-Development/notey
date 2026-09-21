# frozen_string_literal: true

module Notey
  class Channels
    Decision = Struct.new(:channels, :window, keyword_init: true)

    def self.decision_for(member, notification_type, account_id:)
      return Decision.new(channels: [], window: "immediate") unless Notey.notification_types.include?(notification_type.to_s)

      stored = stored_for(member, notification_type, account_id)

      Decision.new(
        channels: stored ? Array(stored.channels).map(&:to_s) : Notey.default_channels,
        window: stored&.digest_window || "immediate"
      )
    end

    def self.for(member, notification_type, account_id:)
      decision_for(member, notification_type, account_id: account_id).channels
    end

    def self.window_for(member, notification_type, account_id:)
      decision_for(member, notification_type, account_id: account_id).window
    end

    def self.channels_of(preference, _notification_type)
      return Array(preference.channels).map(&:to_s) if preference

      Notey.default_channels
    end

    def self.window_of(preference)
      preference.digest_window || "immediate"
    end

    def self.stored_for(member, notification_type, account_id)
      member.notey_preferences.find_by(account_id: account_id, notification_type: notification_type.to_s)
    end
    private_class_method :stored_for
  end
end
