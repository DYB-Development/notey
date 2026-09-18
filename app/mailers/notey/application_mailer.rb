module Notey
  class ApplicationMailer < ActionMailer::Base
    default from: -> { Notey.mailer_sender }
    layout "mailer"
  end
end
