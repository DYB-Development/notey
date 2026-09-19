# frozen_string_literal: true

class InAppNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :comment

  deliver_by :in_app, class: "RecordingDeliveryMethod" do |config|
    config.if = Notey.wanted(:comment, on: :in_app)
  end
end
