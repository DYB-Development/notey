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

    def channels_for(notification_type, account_id: Current.account_id)
      stored = notey_preferences.find_by(account_id: account_id, notification_type: notification_type.to_s)
      return Notey.catalog.default_channels_for(notification_type) if stored.nil?

      Array(stored.channels).map(&:to_s)
    end
  end
end
