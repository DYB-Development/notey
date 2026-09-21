# frozen_string_literal: true

module Notey
  class DeleteOldAttempts
    def call
      Attempt.where(created_at: ...Notey.attempt_retention.ago).delete_all
    end
  end
end
