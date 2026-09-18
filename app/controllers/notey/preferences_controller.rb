# frozen_string_literal: true

module Notey
  class PreferencesController < ApplicationController
    def show
      @notifications = Notey.catalog.notifications
      @stored = Preference.where(member: Current.member, account_id: Current.account_id)
                          .index_by(&:notification_type)
    end

    def update
      result = SavePreferences.new(person: Current.member, account: Current.account_id, values: submitted).call

      return redirect_to preferences_path if result.ok?

      show
      render :show, status: :unprocessable_content
    end

    private

    def submitted
      {
        preferences: params.fetch(:preferences, {}).permit!.to_h,
        windows: params.fetch(:windows, {}).permit!.to_h
      }
    end
  end
end
