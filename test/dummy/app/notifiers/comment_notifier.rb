# frozen_string_literal: true

class CommentNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :comment

  deliver_by :test do |config|
    config.if = Notey.wanted(:comment, on: :test)
  end
end
