# frozen_string_literal: true

module Notey
  class Preference < ApplicationRecord
    belongs_to :member, polymorphic: true
  end
end
