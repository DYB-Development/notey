# frozen_string_literal: true

module Notey
  class InApp < Noticed::DeliveryMethod
    def deliver
      LiveInbox.deliver(notification) if Notey.live_updates
    end

    def outbound?
      false
    end
  end
end
