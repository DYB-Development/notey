# frozen_string_literal: true

module Notey
  class PreferencesController < ApplicationController
    def show
      @notifications = Notey.catalog.notifications
    end

    def update
      saved = chosen.map { |notification_type, channels| store(notification_type, channels) }

      return redirect_to preferences_path if saved.all?

      show
      render :show, status: :unprocessable_content
    end

    private

    def chosen
      params.fetch(:preferences, {}).permit!.to_h.select { |type, _| Notey.catalog.declared?(type) }
    end

    def windows
      params.fetch(:windows, {}).permit!.to_h
    end

    def store(notification_type, channels)
      preference = Preference.find_or_initialize_by(
        member: Current.member,
        account_id: Current.account_id,
        notification_type: notification_type.to_s
      )
      preference.update(
        channels: Array(channels).map(&:to_s),
        digest_window: windows.fetch(notification_type.to_s, "immediate")
      )
    end
  end
end
