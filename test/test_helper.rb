# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [ File.expand_path("../test/dummy/db/migrate", __dir__) ]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "minitest/mock"
require "active_record/testing/query_assertions"

# Load fixtures from the engine
if ActiveSupport::TestCase.respond_to?(:fixture_paths=)
  ActiveSupport::TestCase.fixture_paths = [ File.expand_path("fixtures", __dir__) ]
  ActionDispatch::IntegrationTest.fixture_paths = ActiveSupport::TestCase.fixture_paths
  ActiveSupport::TestCase.file_fixture_path = File.expand_path("fixtures", __dir__) + "/files"
  ActiveSupport::TestCase.fixtures :all
end

class ActiveSupport::TestCase
  setup do
    RecordingDeliveryMethod.sent = []
    Noticed::DeliveryMethods::Test.delivered = []
    Rails.application.eager_load!
    [ CommentNotifier, MentionNotifier, HookNotifier, ThingHappenedNotifier, InAppNotifier, EmailedNotifier ].each do |notifier|
      Notey.register_notifier(notifier)
    end
    Notey.channel(:email)
    Notey.channel(:in_app)
    Notey.channel(:test, delivery_method: "Noticed::DeliveryMethods::Test")
    Notey.channel(:recording, delivery_method: "RecordingDeliveryMethod", addressed: true)
  end

  def notifier_delivering(notification_type, *channels)
    Class.new(Noticed::Event) do
      include Notey::Notifier
      notey_type notification_type

      channels.each do |channel|
        deliver_by channel, class: "RecordingDeliveryMethod" do |config|
          config.if = Notey.wanted(notification_type, on: channel)
        end
      end
    end
  end
end
