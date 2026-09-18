# frozen_string_literal: true

require "event_engine"
require "event_engine/subscribers"

module Notey
  class EventSubscriber < EventEngine::Subscribers::Base
    def handle(event)
      notifier = Notey.notifier_for(event.event_name)
      return if notifier.nil?

      payload = event.payload.to_h.symbolize_keys
      Current.account_id = payload[:account_id]

      notifier.with(**payload).deliver
    end
  end
end
