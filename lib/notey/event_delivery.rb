# frozen_string_literal: true

module Notey
  class EventDelivery
    def self.call(event)
      notifier = Notey.notifier_for(event.event_name)
      return if notifier.nil?

      payload = event.payload.to_h.symbolize_keys

      Current.set(account_id: payload[:account_id]) { notifier.with(**payload).deliver }
    end
  end
end
