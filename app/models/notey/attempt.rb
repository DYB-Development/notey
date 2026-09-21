# frozen_string_literal: true

module Notey
  class Attempt < ApplicationRecord
    belongs_to :notification, class_name: "Noticed::Notification"
  end
end
