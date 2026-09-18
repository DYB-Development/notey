# frozen_string_literal: true

class RecordingDeliveryMethod < Noticed::DeliveryMethod
  class_attribute :sent, default: []

  def deliver
    self.class.sent += [ evaluate_option(:url) ]
  end
end
