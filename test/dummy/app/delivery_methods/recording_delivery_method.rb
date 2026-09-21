# frozen_string_literal: true

class RecordingDeliveryMethod < Noticed::DeliveryMethod
  class_attribute :sent, default: []

  def deliver
    self.class.sent += [ address ]
  end

  private

  def address
    Notey::Destinations.for(event.account_id, config[:notey_channel], member: recipient)&.address
  end
end
