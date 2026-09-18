# frozen_string_literal: true

module Notey
  module Recipient
    extend ActiveSupport::Concern

    included do
      has_many :notey_preferences, as: :member, class_name: "Notey::Preference", dependent: :destroy
    end

    def wants?(notification_type, on:, account_id: Current.account_id)
      channels_for(notification_type, account_id: account_id).include?(on.to_s)
    end

    def digest_window_for(notification_type, account_id: Current.account_id)
      stored_preference(notification_type, account_id)&.digest_window || "immediate"
    end

    def channels_for(notification_type, account_id: Current.account_id)
      stored = stored_preference(notification_type, account_id)
      return Notey.catalog.default_channels_for(notification_type) if stored.nil?

      Array(stored.channels).map(&:to_s)
    end

    private

    def stored_preference(notification_type, account_id)
      notey_preferences.find_by(account_id: account_id, notification_type: notification_type.to_s)
    end
  end
end
