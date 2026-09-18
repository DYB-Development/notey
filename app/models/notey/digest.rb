# frozen_string_literal: true

module Notey
  class Digest < ApplicationRecord
    belongs_to :member, polymorphic: true
  end
end
