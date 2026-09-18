---
name: notey-install
description: Use to hook notey into a project — installing its tables, mounting its engine, declaring the notification catalog, making a model a recipient, setting the current person and account, putting the account on Noticed's rows, supplying a notification url, checking the catalog against the notifiers, and reaching the preferences, inbox and destinations pages.
tools: Bash, Read, Edit
scope: notifications — a catalog of notification types, per-person per-account channel preferences, digest windows, an in-app inbox, per-account destinations, and a mapping from domain events to notifiers
---

This local follows the steps below exactly and invents no others. Where a step
names a decision, put it to the developer and wait for an answer rather than
picking one.

## What notey is

notey is the notification layer for a multi-tenant Rails app on top of Noticed.
Hook it in when the same person belongs to more than one account and should get
different notifications in each.

## Interface

- `bin/rails notey:install:migrations` — copies notey's six migrations into the
  host's `db/migrate`.
- `mount Notey::Engine` — in the host's `config/routes.rb`, putting notey's
  three pages under a path the host chooses.
- `Notey.catalog` — declares every notification type, the channels each type may
  be delivered on, and the channels a person gets before they have stored
  anything.
- `Notey::Recipient` — included in the host model that receives notifications,
  which gives that model its stored preferences.
- `Notey::Notifier` — included in each Noticed event class, which registers it
  so notey can check it when the app boots.
- `Notey::Current` — holds the person and the account id for the current
  request, and every preference read, preference save and inbox read goes
  through it.
- `Notey.notification_url=` — takes a lambda returning the host's own url for
  one notification, used to link the rows in a digest email.
- `Notey.check!` — raises when a notifier names a type the catalog does not
  hold, or the catalog offers a channel no notifier delivers on, and notey runs
  it itself after initialization when the app eager loads.
- `/notey/preferences` — the page a person picks their channels and their
  immediate, daily or weekly window on, per notification type.
- `/notey/notifications` — the person's inbox for the account they are in, 25
  rows newest first with an unread count, and a button that marks one read.
- `/notey/destinations` — the page an account's address and credential are
  stored on, one pair per channel the catalog offers.

The three paths assume the engine is mounted at `/notey`; a different mount path
moves all three.

## How to use it

1. Add `gem "notey"` to the host's `Gemfile` and run `bundle install`.

2. Run `bin/rails notey:install:migrations` and then `bin/rails db:migrate`.
   This creates `notey_preferences`, `notey_digests` and `notey_destinations` in
   the host's database.

3. Mount the engine in the host's `config/routes.rb`:

   ```ruby
   mount Notey::Engine => "/notey"
   ```

   Ask the developer which path to mount at if the app already has a convention
   for engine paths, since the path prefixes all three pages.

4. Declare the catalog in `config/initializers/notey.rb`:

   ```ruby
   Notey.catalog do
     notification :comment, channels: %w[email sms], default: %w[email]
   end
   ```

   Ask the developer which notification types exist, which channels each one
   offers, and which of those channels apply before a person has chosen — there
   is no default for any of the three. Declare only channels a notifier in the
   app actually delivers on, or the app will refuse to boot at step 10.

5. Include the recipient concern in the model that receives notifications:

   ```ruby
   class User < ApplicationRecord
     include Notey::Recipient
   end
   ```

   Ask the developer which model that is. It must respond to `email`, because
   that is the address a digest is sent to.

6. Set the current person and account on every request, in the host's
   `ApplicationController`:

   ```ruby
   before_action do
     Notey::Current.member = current_user
     Notey::Current.account_id = current_account&.id
   end
   ```

   Ask the developer what supplies the signed-in person and the current account
   in this app, since both names above are guesses about the host. A read with
   no account set returns the catalog's default channels and an empty inbox,
   never another account's rows, and a save on the preferences page fails
   because a stored preference needs an account.

7. Add the account to Noticed's own rows with a host migration:

   ```ruby
   add_column :noticed_events, :account_id, :bigint
   add_column :noticed_notifications, :account_id, :bigint
   ```

   Then fill them in `config/initializers/noticed.rb`:

   ```ruby
   ActiveSupport.on_load :noticed_event do
     after_initialize { self.account_id ||= Notey::Current.account_id }

     def recipient_attributes_for(recipient)
       super.merge(account_id: account_id)
     end
   end
   ```

   Without these columns the inbox is empty and every digest is, because a
   delivery runs in a job where the current account is gone.

8. Include the notifier concern in each Noticed event class that delivers one of
   the catalog's types:

   ```ruby
   class CommentNotifier < Noticed::Event
     include Notey::Notifier
   end
   ```

   Naming which type the class delivers, and gating each delivery method on what
   the person wants, are `notey-develop`'s steps rather than this local's.

9. Point digest links at the host's own pages in
   `config/initializers/notey.rb`:

   ```ruby
   Notey.notification_url = lambda do |notification|
     Rails.application.routes.url_helpers.notification_url(notification)
   end
   ```

   Ask the developer which of their pages shows one notification. With nothing
   set, a digest still sends and its rows are plain text instead of links.

10. Boot the app with eager loading on and watch it raise or come up. notey runs
    `Notey.check!` itself at that point; call it directly in a test or a console
    to check the same thing without a boot.

11. Decide the pages' layout. They render in notey's own layout, which loads
    notey's stylesheet and nothing of the host's, unless the host defines
    `app/views/layouts/notey/application.html.erb`, which takes precedence over
    the engine's copy. Ask the developer whether these pages should carry the
    app's navigation.

12. Set up destinations only if a channel in the catalog is addressed at the
    account rather than at a person. The stored credential is encrypted, so
    Active Record encryption keys must be configured in the host's credentials
    (`bin/rails db:encryption:init` generates a set) or saving a destination
    raises. Ask the developer whether any channel needs this before doing it.

## Conventions

- **Check each page while signed in with an account set.** `/notey/preferences`
  lists one panel per declared type, `/notey/notifications` lists that person's
  notifications for the current account, and `/notey/destinations` lists one
  address and credential field per channel the catalog offers.
- **A preferences page that will not save is the symptom of a missing account.**
  Reads fall back to the catalog's default channels when
  `Notey::Current.account_id` is nil and a save is refused, so check step 6
  before anything else.
- **Boot with eager loading after every catalog change.** The catalog and the
  notifiers are checked against each other only then, and an empty catalog
  skips the check entirely.
- **Authentication on the three pages is the host's.** Its controllers inherit
  from the host's `ApplicationController`, so the host's own filters run and
  notey adds no authorization of its own — restricting who may set an account's
  destinations is the host's to write.
- **Digest emails send from `from@example.com`** and notey exposes no setting
  that changes it.
- **Re-run `bin/rails notey:install:migrations` after upgrading the gem.** It
  copies only the migrations the host does not already have.
- **Out of scope.** Scheduling the digest runs, tying a notifier to a
  notification type, delivering one when a domain event fires, and reading the
  inbox from the host's own code all belong to `notey-develop`.
