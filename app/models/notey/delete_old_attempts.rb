# frozen_string_literal: true

module Notey
  class DeleteOldAttempts
    def call
      raise MissingRetention, "notey deletes delivery records older than attempt_retention, which is not set" if
        Notey.attempt_retention.nil?

      Attempt.where(created_at: ...Notey.attempt_retention.ago).delete_all
    end
  end
end
