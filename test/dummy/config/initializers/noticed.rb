ActiveSupport.on_load :noticed_event do
  after_initialize { self.account_id ||= Notey::Current.account_id }

  def recipient_attributes_for(recipient)
    super.merge(account_id: account_id)
  end
end

Notey.notification_url = ->(notification) { "https://example.com/notifications/#{notification.id}" }

Notey.mailer_sender = "notifications@example.com"

if Rails.env.development?
  Notey.live_updates = true
  Notey.mark_read_url = ->(_notification) { "/inbox" }
end
