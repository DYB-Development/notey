# frozen_string_literal: true

module Notey
  class Current < ActiveSupport::CurrentAttributes
    attribute :account_id
  end
end
