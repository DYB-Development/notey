---
name: notey-develop
description: Use PROACTIVELY for naming a notifier's notification type, gating a delivery method on what a person wants, addressing a channel at the account, firing a notifier from a domain event, scheduling daily and weekly digest runs, reading a person's inbox, and reading their channels and window — MUST BE USED instead of hand-rolling preference checks, per-account delivery addresses, or a digest loop.
tools: Read, Write, Edit, Grep
scope: notifications — a catalog of notification types, per-person per-account channel preferences, digest windows, an in-app inbox, per-account destinations, and a mapping from domain events to notifiers
---

This local follows the steps below exactly and invents no others. Where a step
names a decision, put it to the developer and wait for an answer rather than
picking one.

## What notey is

notey is the notification layer for a multi-tenant Rails app on top of Noticed.
It holds which notification types exist, which channels each person wants in
each account they belong to, and whether they want them as they happen or in a
daily or weekly digest. Fire this local when a notifier is being written or
changed, when a domain event should send one, when digests need running, or when
the host's own code needs to read a person's notifications or their preferences.

This local assumes the gem is already hooked into the app; if it is not, that is
`notey-install`'s work and it comes first.

## Interface

- `notey_type` — declared inside a notifier class, names which of the catalog's
  notification types that class delivers.
- `Notey.wanted(type, on:)` — returns a condition for one delivery method that
  is true only when the person wants that type on that channel and wants it
  immediately.
- `Notey.deliver_on(event_name, notifier)` — maps a domain event to a notifier,
  so the notifier is delivered whenever that event fires.
- `Notey.destination_address(channel)` — returns the stored address for the
  channel on the account the notification belongs to.
- `Notey.addressed(channel)` — returns a condition that is true only when that
  account has a stored address for the channel.
- `Notey::DigestRun` — sends one window's digests, with `call` for everyone on
  that window and `deliver_to_member(member, account_id)` for one person in one
  account.
- `Notey::Inbox.for(member, account_id:)` — returns that person's notifications
  for that account, as a relation.
- `wants?(type, on:, account_id:)` — on the recipient model, true when that
  person wants that type on that channel in that account.
- `channels_for(type, account_id:)` — on the recipient model, the channels that
  person gets that type on in that account.
- `digest_window_for(type, account_id:)` — on the recipient model, `immediate`,
  `daily` or `weekly` for that type in that account.
- `Notey.reset!` — drops the catalog and the event-to-notifier mappings, for
  tests that declare their own.

## How to use it

1. Name the type at the top of each notifier class:

   ```ruby
   class CommentNotifier < Noticed::Event
     notey_type :comment
   end
   ```

   The name must be one the catalog declares, or the app raises when it boots
   with eager loading on. Two notifier classes may name the same type.

2. Gate every delivery method on what the person wants:

   ```ruby
   deliver_by :email do |config|
     config.if = Notey.wanted(:comment, on: :email)
   end
   ```

   Pass the same type the class names and the channel this delivery method
   sends on. Without this the delivery runs for everyone regardless of their
   preferences.

3. Leave the digest to notey. `Notey.wanted` is false when the person's window
   for that type is daily or weekly, so nothing sends at the time and the
   notification waits in their inbox for the next run. Never write a second
   condition for the window.

4. For a channel addressed at the account rather than at the person, read the
   stored address and skip the delivery when there is none:

   ```ruby
   deliver_by :webhook, class: "WebhookDeliveryMethod" do |config|
     config.url = Notey.destination_address(:webhook)
     config.if = Notey.addressed(:webhook)
   end
   ```

   Ask the developer which channels are addressed at the account, since the two
   kinds of channel are gated differently and only they know which is which. A
   channel can carry both conditions, one from step 2 and one from here.

5. Map a domain event to a notifier in an initializer, one line per mapping:

   ```ruby
   Notey.deliver_on :comment_posted, CommentNotifier
   ```

   The subscriber sets the account from the event's payload, delivers the
   notifier with the whole payload as its params, and puts back the account that
   was set before. An event with no mapping delivers nothing and raises nothing.
   Ask the developer which events map to which notifiers; nothing in the gem
   infers it. The payload must carry `account_id`, or the notification is stored
   against no account and never reaches an inbox.

6. Schedule the digest windows. notey registers no schedule of its own, so a
   window nobody runs never sends:

   ```ruby
   Notey::DigestRun.new(window: "daily").call
   Notey::DigestRun.new(window: "weekly").call
   ```

   Run daily once a day and weekly once a week; those are the only two windows a
   run accepts. Each run enqueues one job per person per account, so one failing
   send does not stop the rest. Ask the developer what schedules recurring work
   in this app — cron, a scheduler gem, or a platform scheduler — and at what
   hour each window should go out.

7. Read a person's notifications through the inbox rather than querying Noticed
   directly:

   ```ruby
   Notey::Inbox.for(current_user, account_id: current_account.id)
   ```

   It returns a relation, so chain `.unread`, `.order` and `.limit` onto it. With
   no account it returns an empty relation, never another account's rows.

8. Read a person's preferences from the host's own code when the app needs to
   branch on them:

   ```ruby
   user.wants?(:comment, on: :email, account_id: account.id)
   user.channels_for(:comment, account_id: account.id)
   user.digest_window_for(:comment, account_id: account.id)
   ```

   All three take the account from the current request when it is left out. All
   three read a person's stored row for that type, and fall back to the
   catalog's declared defaults when they have never stored one.

9. In tests that declare their own notification types or event mappings, call
   `Notey.reset!` in teardown. Both are held for the life of the process, so a
   test that skips this leaves its types and mappings in place for every test
   after it.

## Conventions

- **Every notifier names a type.** A notifier without one delivers, but no
  digest ever includes it, because a digest picks its rows by the type the
  notifier names.
- **Every delivery method carries a condition.** An ungated one ignores the
  person's channels and their window, which is the whole point of the gem.
- **Every channel the catalog offers is delivered by some notifier.** A channel
  the catalog offers that no notifier has a delivery method for raises when the
  app boots with eager loading on.
- **Only channels the catalog offers for that type may be gated on.** Gating on
  a channel the type does not offer makes a condition that is always false, and
  the delivery silently never runs.
- **A digest is mailed to the person's `email`.** A recipient model without one
  raises when its digest is sent, not when the run starts.
- **A run sends one window once.** Overlapping runs of the same window send one
  digest, and a send that fails releases the window so the next run picks it up
  again.
- **A digest covers the current day or week to the moment it runs**, so a run
  late in the period covers everything and a second run in the same period sends
  nothing.
- **A digest sends nothing when there is nothing to send** — no empty mail, and
  no row saying it went out.
- **Notifiers, event mappings and digest schedules all belong in the host's
  code**, never in the gem.
- **Out of scope.** Declaring the notification types and their channels, making
  a model a recipient, setting the current person and account, storing an
  account's addresses, and the pages a person picks their own channels on all
  belong to `notey-install`.
