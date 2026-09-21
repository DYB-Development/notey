# frozen_string_literal: true

module Notey
  module RecordsAttempt
    extend ActiveSupport::Concern

    included do
      around_deliver :record_attempt
    end

    def record_attempt
      channel = config[:notey_channel]
      return yield if channel.blank?

      attempt = Attempt.create!(notification: notification, channel: channel)
      yield
      attempt.update!(state: "sent")
    end
  end
end
