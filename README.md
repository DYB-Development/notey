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

- **A catalog.** One declaration naming every notification type, the channels it
  may be delivered on, and the channels a person gets by default.
- **Preferences.** Which channels a person wants for each type, per account,
  with a page they set them on.
- **Digest windows.** A type set to daily or weekly is held back and sent as one
  email covering the window.
- **An inbox.** In-app notification pages scoped to the account the person is in.
- **Destinations.** An address and an encrypted credential per account per
  channel, so an account points a channel at its own workspace or endpoint.
- **Domain events.** A mapping from an event your app already publishes to the
  notifier that should deliver it.

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

### 1. Declare the catalog

Nothing works until a type is declared. A preference for an undeclared type is
refused, a channel the catalog does not offer for a type is refused, and a
notifier naming an undeclared type raises when the app boots.

```ruby
# config/initializers/notey.rb
Notey.catalog do
  notification :comment, channels: %w[email sms], default: %w[email]
  notification :mention, channels: %w[email], default: []
end
```

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

### 5. Point your notifiers at the catalog

Each notifier names its type, and each delivery method asks whether the
recipient wants that channel.

```ruby
class CommentNotifier < Noticed::Event
  include Notey::Notifier
  notey_type :comment

  deliver_by :email do |config|
    config.mailer = "CommentMailer"
    config.if = Notey.wanted(:comment, on: :email)
  end
end
```

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

Notey ships its two pages as partials and their saving as action objects, so a
settings shell renders them inside its own chrome rather than linking away.
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

## Destinations

An account stores an address and a credential per channel on
`/notey/destinations`, and a notifier reads them through the options Noticed
already evaluates:

```ruby
deliver_by :webhook do |config|
  config.url = Notey.destination_address(:webhook)
  config.if = Notey.addressed(:webhook)
end
```

The credential is encrypted at rest, which needs Active Record encryption keys
configured in your app. A channel with no destination for that account sends
nothing on it.

**Nothing in this engine restricts who may set a destination.** Gate
`/notey/destinations` in your own app.

## Domain events

Notey does not depend on any event pipeline. It holds the mapping from an event
name to a notifier, and your app owns the one class that knows both.

```ruby
# config/initializers/notey.rb
Notey.deliver_on :comment_posted, CommentNotifier
```

```ruby
# app/subscribers/notey_notifications.rb
class NoteyNotifications < EventEngine::Subscribers::Base
  subscribes_to :comment_posted

  def handle(event)
    Notey::EventDelivery.call(event)
  end
end
```

`Notey::EventDelivery.call` takes anything answering `event_name` and `payload`,
sets the account from the payload for the delivery, and restores the account it
found. An event with no mapping does nothing.

## Development

After checking out the repo, run `bin/setup` to install dependencies, then
`bundle exec rake test` to run the tests and `bin/rubocop` for the linter.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
