# frozen_string_literal: true

module Notey
  class ApplicationController < ::ApplicationController
    helper KeystoneUiHelper, Notey::Engine.routes.url_helpers
  end
end
