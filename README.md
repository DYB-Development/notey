# Notey

Notey is the notification layer for multi-tenant Rails apps. It sits on top of
[Noticed](https://github.com/excid3/noticed) and supplies the parts Noticed
leaves to the host.

## What Noticed already does

- **Recipients.** A notifier declares `recipients`, and delivery inserts one
  `noticed_notifications` row per recipient.
- **In-app records.** Every notification is written to the database, with
  read/unread and seen/unseen state.
- **Channels.** Email, SMS through Twilio or Vonage, iOS, FCM, Action Push,
  Slack, Discord, Microsoft Teams, webhooks, and Action Cable.

## What Notey adds

- **Channels.** One registration per channel the application can send on, made
  once for the whole application rather than on every notification.
- **Preferences.** Which channels a person wants for each type, per account,
  with a page they set them on.
- **Digest windows.** A type set to daily or weekly is held back and sent as one
  email covering the window.
- **An inbox.** In-app notification pages scoped to the account the person is in.
- **Destinations.** An address and an encrypted credential per account per
  channel, so an account points a channel at its own workspace or endpoint.
- **Notification types.** A class describing what a notification carries and
  nothing about how it is sent.

## Installation

```ruby
gem "notey"
```

```bash
bundle install
bin/rails notey:install:migrations
bin/rails db:migrate
```

Mount the engine:

```ruby
# config/routes.rb
mount Notey::Engine => "/notey"
```

That gives you `/notey/preferences`, `/notey/notifications` and
`/notey/destinations`.

## Wiring

Notey owns its own tables and never owns your person or account records. Six
things connect it to yours.

### 1. Register the channels your application has

Every application has email and in-app without registering anything. Register a
channel for anything else you send on, once, for the whole application.

```ruby
# config/initializers/notey.rb
Notey.channel :sms, delivery_method: "Noticed::DeliveryMethods::TwilioMessaging", addressed: true
```

A registration names the channel, the delivery method that sends it, and whether
it needs an address before anything can go out on it. Nothing else names a
channel: a notification type does not, and a person's preferences offer exactly
what is registered.

### 2. Make your person model a recipient

```ruby
class User < ApplicationRecord
  include Notey::Recipient
end
```

### 3. Set the current person and account per request

```ruby
class ApplicationController < ActionController::Base
  before_action do
    Notey::Current.member = current_user
    Notey::Current.account_id = current_account&.id
  end
end
```

A read with no account set returns the declared defaults and an empty inbox,
never another account's rows.

### 4. Put the account on Noticed's rows

Notey reads the account from the Noticed event, because a delivery runs in a job
where the current account is gone. Noticed does not add that column, so your app
does.

```ruby
# a migration
add_column :noticed_events, :account_id, :bigint
add_column :noticed_notifications, :account_id, :bigint
```

```ruby
# config/initializers/noticed.rb
ActiveSupport.on_load :noticed_event do
  after_initialize { self.account_id ||= Notey::Current.account_id }

  def recipient_attributes_for(recipient)
    super.merge(account_id: account_id)
  end
end
```

### 5. Define a notification type

A notification type describes what the notification carries and says nothing
about channels. Notey decides which channels each recipient gets.

```ruby
class CommentNotification < Notey::Notification
  notey_type :comment

  required_params :comment_id

  def title
    "New comment"
  end

  def body
    "Someone replied to you"
  end
end
```

`notey_type` is the name a person's stored preferences are keyed by, so renaming
the class does not orphan what they chose. Send it by naming the recipients your
own code resolved:

```ruby
CommentNotification.notify(recipients, comment_id: comment.id)
```

Notey builds the delivery list from the registered channels each time, so a
channel registered later needs no change here. For each recipient and each
channel it answers three things before sending: the person wants that channel
for that type, their window is immediate, and they have an address if the
channel needs one.

### 6. Tell Notey where a notification lives

Digest emails link to each notification through a lambda you supply, so the link
points at your own page rather than one this engine picks.

```ruby
# config/initializers/notey.rb
Notey.notification_url = lambda do |notification|
  Rails.application.routes.url_helpers.notification_url(notification)
end
```

## Settings sections

Notey ships its screens as partials and their saving as action objects, so a
settings shell renders them inside its own page frame rather than linking away.
With [`bureau`](https://github.com/DYB-Development/bureau):

```ruby
# config/initializers/bureau.rb
Bureau.section :notifications, area: :user, title: "Notifications",
  renders: "notey/preferences", runs: "Notey::SavePreferences"

Bureau.section :notification_destinations, area: :account, title: "Notification destinations",
  renders: "notey/destinations", runs: "Notey::SaveDestination", capability: :configure_site
```

A section registered this way is served by the settings shell, so the shell's
own capability check guards it. A section that only links to a mounted path is
not guarded, because the shell never renders it.

## The inbox

The inbox is the same shape and is not a setting, so render it wherever a
person's notifications belong in your own pages:

```erb
<%= render "notey/inbox",
      person: current_user,
      account: current_account.id,
      submit_url: notifications_path %>
```

It lists the notifications that person received in that account, newest first,
marking the unread ones. Marking one read posts to the url you named, so the
person stays on your page, and the action behind it runs:

```ruby
Notey::MarkRead.new(person: current_user, account: current_account.id, values: params).call
```

It marks only a notification that person received in that account, so an id
from anywhere else does nothing.

`Notey::SavePreferences` and `Notey::SaveDestination` take `person:`, `account:`
and `values:`, and answer with an object responding to `ok?` and `message`. The
engine's own pages call the same two actions.

## Sending digests

A type set to daily or weekly sends nothing when it happens. Run the window on a
schedule — Notey does not register one:

```ruby
Notey::DigestRun.new(window: "daily").call
Notey::DigestRun.new(window: "weekly").call
```

Each run enqueues one job per person, so one failing send does not stop the
rest. A window is sent once even if the run overlaps itself; a send that fails
releases the window so it can be sent again.

## Deleting old delivery records

Notey writes one record per notification per channel that leaves the
application, and nothing deletes them on its own. Say how long to keep them:

```ruby
# config/initializers/notey.rb
Notey.attempt_retention = 90.days
```

Then run the deletion on a schedule, the way you run the digest windows:

```ruby
Notey::DeleteOldAttempts.new.call
```

Everything older than the period goes and everything inside it stays, so
running it twice leaves the same records as running it once. With no period set
it refuses to run rather than deleting nothing quietly.

## Destinations

A channel like email reaches a person at an address the app already holds. A
channel like SMS, a webhook, Slack or Discord does not, so somebody has to say
where it goes. Say so when you register the channel:

```ruby
Notey.channel :sms, delivery_method: "Noticed::DeliveryMethods::TwilioMessaging", addressed: true
```

**A person sets their own.** Their phone number, their endpoint. A notification
addressed to them goes only to an address they set — never to one the account
set.

```ruby
Bureau.section :my_notification_addresses, area: :user, title: "Where notifications reach me",
  renders: "notey/my_destinations", runs: "Notey::SaveMyDestination"
```

**An account sets its own**, for notifications that belong to the whole account
rather than to one person — a team Slack or Discord channel.

```ruby
Bureau.section :notification_destinations, area: :account, title: "Notification destinations",
  renders: "notey/destinations", runs: "Notey::SaveDestination", capability: :configure_site
```

Notey sends nothing on an addressed channel until the person has set an address.
The delivery method reads that address when it sends:

```ruby
class WebhookDeliveryMethod < Noticed::DeliveryMethod
  def deliver
    post_to Notey::Destinations.for(event.account_id, :webhook, member: recipient).address
  end
end
```

A credential is encrypted at rest, which needs Active Record encryption keys
configured in your app. A channel with no address set sends nothing on it.

**Nothing in this engine restricts who may set an account's address.** Register
it as a settings section so the shell's capability check guards it.

## Domain events

Notey does not depend on any event pipeline and holds no mapping from an event
to a notification. Your subscriber resolves who should hear about something and
calls the notification type.

```ruby
# app/subscribers/notey_notifications.rb
class NoteyNotifications < EventEngine::Subscribers::Base
  subscribes_to :comment_posted

  def handle(event)
    payload = event.payload.to_h.symbolize_keys

    Notey::Current.set(account_id: payload[:account_id]) do
      CommentNotification.notify(User.where(id: payload[:user_ids]), comment_id: payload[:comment_id])
    end
  end
end
```

Who receives a notification is decided outside notey; how each of them receives
it is decided inside.

## Development

After checking out the repo, run `bin/setup` to install dependencies, then
`bundle exec rake test` to run the tests and `bin/rubocop` for the linter.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
