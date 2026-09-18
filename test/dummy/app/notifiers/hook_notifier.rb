# frozen_string_literal: true

class HookNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :comment

  deliver_by :recording, class: "RecordingDeliveryMethod" do |config|
    config.url = Notey.destination_address(:recording)
    config.if = Notey.addressed(:recording)
  end
end
