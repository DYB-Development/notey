# frozen_string_literal: true

class CommentNotifier < Noticed::Event
  deliver_by :test do |config|
    config.if = Notey.wanted(:comment, on: :test)
  end
end
