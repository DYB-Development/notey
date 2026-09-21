# frozen_string_literal: true

module Notey
  module RecordsAttempt
    extend ActiveSupport::Concern

    included do
      around_deliver :record_attempt
    end

    def outbound?
      true
    end

    def record_attempt
      channel = config[:notey_channel]
      return yield if channel.blank? || !outbound?

      attempt = claim_attempt(channel)
      return if attempt.nil?

      begin
        yield
        attempt.update!(state: "sent")
      rescue StandardError => error
        attempt.update!(state: "failed", failure: error.message)
        raise
      end
    end

    def claim_attempt(channel)
      Attempt.create!(notification: notification, channel: channel)
    rescue ActiveRecord::RecordNotUnique
      nil
    end
  end
end
