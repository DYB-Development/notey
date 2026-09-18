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
      Channels.window_for(self, notification_type, account_id: account_id)
    end

    def channels_for(notification_type, account_id: Current.account_id)
      Channels.for(self, notification_type, account_id: account_id)
    end
  end
end
