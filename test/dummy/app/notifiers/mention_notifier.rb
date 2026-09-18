# frozen_string_literal: true

class MentionNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :mention

  deliver_by :test do |config|
    config.if = Notey.wanted(:mention, on: :test)
  end
end
