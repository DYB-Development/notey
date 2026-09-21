# frozen_string_literal: true

module Notey
  class SavePreferences
    def initialize(values:, person: nil, account: nil)
      @person = person
      @account_id = account.respond_to?(:id) ? account.id : account
      @values = values
    end

    def call
      refusal = chosen.filter_map { |notification_type, channels| store(notification_type, channels) }.first

      refusal || Kept.new
    end

    private

    def chosen
      @values.fetch(:preferences, {}).select { |type, _| Notey.notification_types.include?(type.to_s) }
    end

    def windows
      @values.fetch(:windows, {})
    end

    def store(notification_type, channels)
      preference = Preference.find_or_initialize_by(
        member: @person, account_id: @account_id, notification_type: notification_type.to_s
      )
      preference.channels = Array(channels).map(&:to_s).reject(&:blank?)
      preference.digest_window = windows.fetch(notification_type.to_s, "immediate")

      Refusal.new(preference.errors.full_messages.first) unless preference.save
    end
  end
end
