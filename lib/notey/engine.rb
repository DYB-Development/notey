require "noticed"

module Notey
  class Engine < ::Rails::Engine
    isolate_namespace Notey
  end
end
