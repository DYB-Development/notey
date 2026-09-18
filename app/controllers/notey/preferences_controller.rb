# frozen_string_literal: true

module Notey
  class PreferencesController < ApplicationController
    def show
      @notifications = Notey.catalog.notifications
    end
  end
end
