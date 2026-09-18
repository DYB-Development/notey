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
                 .each { |(member, account_id), _| DigestJob.perform_later(member, account_id, window) }
    end

    def deliver_to_member(member, account_id)
      deliver_to(member, account_id, preferences.where(member: member, account_id: account_id))
    end

    private

    attr_reader :window, :now

    def preferences
      Preference.where(digest_window: window)
    end

    def deliver_to(member, account_id, grouped)
      notifications = gathered(member, account_id, types_in_window(member, account_id, grouped))
      return if notifications.empty?

      digest = claim(member, account_id)
      return if digest.nil?

      send_digest(digest, member, notifications)
    end

    def send_digest(digest, member, notifications)
      DigestMailer.digest(member, notifications, window).deliver_now
      digest.update!(notifications_count: notifications.size, sent_at: Time.current)
    rescue StandardError
      digest.destroy
      raise
    end

    def claim(member, account_id)
      Digest.create!(member: member, account_id: account_id, digest_window: window, period_start: period_start)
    rescue ActiveRecord::RecordNotUnique
      nil
    end

    def types_in_window(member, account_id, grouped)
      grouped.map(&:notification_type).select do |notification_type|
        Channels.window_for(member, notification_type, account_id: account_id) == window
      end
    end

    def gathered(member, account_id, notification_types)
      Inbox.for(member, account_id: account_id)
        .includes(:event)
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
