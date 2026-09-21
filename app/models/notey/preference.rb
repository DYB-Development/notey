# frozen_string_literal: true

module Notey
  class Preference < ApplicationRecord
    belongs_to :member, polymorphic: true

    WINDOWS = %w[immediate daily weekly].freeze

    validates :digest_window, inclusion: { in: WINDOWS, message: "is not a window notey sends on" }

    validate :channels_offered_for_notification_type

    private

    def channels_offered_for_notification_type
      (Array(channels).map(&:to_s) - Notey.channels).each do |unoffered|
        errors.add(:channels, "is not a channel this application has: #{unoffered}")
      end
    end
  end
end
