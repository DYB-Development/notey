# frozen_string_literal: true

class FailingDeliveryMethod < Noticed::DeliveryMethod
  class_attribute :failing, default: true
  class_attribute :sent, default: []

  def deliver
    raise "the provider refused it" if self.class.failing

    self.class.sent += [ notification.id ]
  end
end
