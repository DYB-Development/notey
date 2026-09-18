# frozen_string_literal: true

module Notey
  class DigestRun
    PERIODS = { "daily" => :day, "weekly" => :week }.freeze

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

      digest = claim(member, account_id)
      return if digest.nil? || digest.sent_at.present?

      DigestMailer.digest(member, notifications, window).deliver_now
      digest.update!(notifications_count: notifications.size, sent_at: Time.current)
    end

    def claim(member, account_id)
      Digest.create!(member: member, account_id: account_id, digest_window: window, period_start: period_start)
    rescue ActiveRecord::RecordNotUnique
      Digest.find_by(member: member, account_id: account_id, digest_window: window, period_start: period_start)
    end

    def gathered(member, account_id, notification_types)
      Noticed::Notification
        .where(recipient: member, account_id: account_id)
        .where(created_at: period_start..now)
        .select { |notification| notification_types.include?(type_of(notification)) }
    end

    def type_of(notification)
      notification.event.class.try(:notey_notification_type)
    end

    def period_start
      @period_start ||= now.public_send("beginning_of_#{PERIODS.fetch(window)}")
    end
  end
end
