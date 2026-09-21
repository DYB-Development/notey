# frozen_string_literal: true

module Notey
  class DeleteOldAttempts
    UNSET = "notey deletes delivery records older than attempt_retention, which is not set"

    def call
      raise MissingRetention, UNSET if retention.nil?

      Attempt.where(created_at: ...retention.ago).delete_all
    end

    private

    def retention
      Notey.attempt_retention
    end
  end
end
