# frozen_string_literal: true

module Notey
  module Recipient
    extend ActiveSupport::Concern

    included do
      has_many :notey_preferences, as: :member, class_name: "Notey::Preference", dependent: :destroy
    end

    def wants?(notification_type, on:)
      channels_for(notification_type).include?(on.to_s)
    end

    def channels_for(notification_type)
      stored = notey_preferences.find_by(account_id: Current.account_id, notification_type: notification_type.to_s)
      return Notey.catalog.default_channels_for(notification_type) if stored.nil?

      Array(stored.channels).map(&:to_s)
    end
  end
end
