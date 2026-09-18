# frozen_string_literal: true

module Notey
  class PreferencesController < ApplicationController
    def show
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
