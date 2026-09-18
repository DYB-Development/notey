# frozen_string_literal: true

module Notey
  class ApplicationController < ActionController::Base
    helper KeystoneUiHelper, Notey::Engine.routes.url_helpers
  end
end
