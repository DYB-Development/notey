# frozen_string_literal: true

class MentionNotification < Notey::Notification
  notey_type :mention

  required_params :mention_id
end
