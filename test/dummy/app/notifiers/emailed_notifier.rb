# frozen_string_literal: true

class EmailedNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :comment

  deliver_by :email, class: "RecordingDeliveryMethod" do |config|
    config.if = Notey.wanted(:comment, on: :email)
  end
end
