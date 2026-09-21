# frozen_string_literal: true

class FailingDeliveryMethod < Noticed::DeliveryMethod
  def deliver
    raise "the provider refused it"
  end
end
