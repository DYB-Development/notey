# frozen_string_literal: true

class NoteyNotifications < EventEngine::Subscribers::Base
  subscribes_to :thing_happened

  def handle(event)
    payload = event.payload.to_h.symbolize_keys

    Notey::Current.set(account_id: payload[:account_id]) do
      CommentNotification.notify(Member.where(id: payload[:member_ids]), comment_id: payload[:comment_id])
    end
  end
end
