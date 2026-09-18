# frozen_string_literal: true

class NoteyNotifications < EventEngine::Subscribers::Base
  subscribes_to :thing_happened

  def handle(event)
    Notey::EventDelivery.call(event)
  end
end
