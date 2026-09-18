# frozen_string_literal: true

module Notey
  class DigestRun
    PERIODS = { "daily" => 1.day, "weekly" => 1.week }.freeze

    def initialize(window:, now: Time.current)
      @window = window.to_s
      @now = now
    end

    def call
      preferences.group_by { |preference| [ preference.member, preference.account_id ] }
                 .filter_map { |(member, account_id), grouped| deliver_to(member, account_id, grouped) }
    end

    private

    attr_reader :window, :now

    def preferences
      Preference.where(digest_window: window)
    end

    def deliver_to(member, account_id, grouped)
      notifications = gathered(member, account_id, grouped.map(&:notification_type))
      return if notifications.empty?

      DigestMailer.digest(member, notifications, window).deliver_now
      Digest.create!(member: member, account_id: account_id, digest_window: window,
        notifications_count: notifications.size, sent_at: Time.current)
    end

    def gathered(member, account_id, notification_types)
      Noticed::Notification
        .where(recipient: member, account_id: account_id)
        .where(created_at: since..now)
        .select { |notification| notification_types.include?(type_of(notification)) }
    end

    def type_of(notification)
      event_class = notification.event.class
      event_class.try(:notey_notification_type)
    end

    def since
      now - PERIODS.fetch(window)
    end
  end
end
