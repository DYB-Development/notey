# frozen_string_literal: true

class ThingHappenedNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :comment

  recipients { Member.where(id: params[:member_ids]) }

  deliver_by :test do |config|
    config.if = Notey.wanted(:comment, on: :test)
  end
end
