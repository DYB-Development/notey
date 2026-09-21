---
name: notey-develop
description: Use PROACTIVELY for defining a notification type, sending one to the recipients your own code resolved, sending one when a domain event fires, addressing a channel at a person, scheduling daily and weekly digest runs, reading a person's inbox, and reading their channels and window — MUST BE USED instead of hand-rolling preference checks, per-person delivery addresses, or a digest loop.
tools: Read, Write, Edit, Grep
scope: notifications — application-wide channel registrations, notification types that name no channel, per-person per-account channel preferences, digest windows, an in-app inbox, per-account destinations, and a record of what was sent on each channel
---

This local follows the steps below exactly and invents no others. Where a step
names a decision, put it to the developer and wait for an answer rather than
picking one.

## What notey is

notey is the notification layer for a multi-tenant Rails app on top of Noticed.
It holds which channels the application can send on, which channels each person
wants in each account they belong to, and whether they want them as they happen
or in a daily or weekly digest. Fire this local when a notification type is
being written or changed, when a domain event should send one, when digests need
running, or when the host's own code needs to read a person's notifications or
their preferences.

This local assumes the gem is already hooked into the app; if it is not, that is
`notey-install`'s work and it comes first.

## Interface

- `Notey::Notification` — the class a notification type inherits, which builds
  its delivery list from the registered channels and decides each one itself.
- `notey_type` — declared inside a notification type, names the key a person's
  stored preferences are held under, so renaming the class keeps them.
- `required_params` — declared inside a notification type, names the information
  a caller must pass, and a call that omits any of it is refused.
- `notify(recipients, **information)` — sends one notification to the recipients
  the caller resolved, recording one row for each.
- `Notey.channel(name, delivery_method:, addressed:)` — registers one channel
  the application can send on, for the whole application.
- `Notey::Destinations.for(account_id, channel, member:)` — returns the stored
  destination for that person on that channel, which a delivery method reads to
  learn where to send.
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
- `Notey.reset!` — drops the registered channels and notification types, for
  tests that register their own.

## How to use it

1. Write a notification type that says nothing about channels:

   ```ruby
   class CommentNotification < Notey::Notification
     notey_type :comment

     required_params :comment_id

     def title
       "New comment"
     end
   end
   ```

   Ask the developer what information the notification carries and what a person
   should read on it. Two types may name the same `notey_type`, and renaming the
   class keeps the preferences people have already stored.

2. Send it by naming the recipients your own code resolved:

   ```ruby
   CommentNotification.notify(recipients, comment_id: comment.id)
   ```

   Working out who should receive it, and removing duplicates from that list, is
   the caller's and never notey's. The call is refused before anything is
   recorded when it omits information the type requires.

3. Write no condition on any channel. notey builds the delivery list from the
   registered channels and answers three things per recipient per channel before
   sending: the person wants that channel for that type, their window is
   immediate, and they have an address if the channel needs one. A type that
   tries to gate its own channels is doing notey's job twice.

4. For a channel that needs an address, read it inside the delivery method:

   ```ruby
   class WebhookDeliveryMethod < Noticed::DeliveryMethod
     def deliver
       post_to Notey::Destinations.for(event.account_id, :webhook, member: recipient).address
     end
   end
   ```

   notey has already refused the delivery when no address is set, so the lookup
   never comes back empty here. Ask the developer which channels need an address,
   since that is named once on the registration and only they know which.

5. Send from a domain event in the host's own subscriber:

   ```ruby
   def handle(event)
     payload = event.payload.to_h.symbolize_keys

     Notey::Current.set(account_id: payload[:account_id]) do
       CommentNotification.notify(User.where(id: payload[:user_ids]), comment_id: payload[:comment_id])
     end
   end
   ```

   notey holds no mapping from an event to a notification and depends on no event
   pipeline. The subscriber resolves the recipients and sets the account, because
   a delivery runs in a job where the current account is gone. Without
   `account_id` the notification is stored against no account and never reaches
   an inbox.

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
   three read a person's stored row for that type, and fall back to email and
   in-app when they have never stored one.

9. In tests that register their own channels or notification types, call
   `Notey.reset!` in teardown. Both are held for the life of the process, so a
   test that skips this leaves its channels and types in place for every test
   after it.

## Conventions

- **Every notification type names a `notey_type`.** Without one no digest ever
  includes it, because a digest picks its rows by that name.
- **No notification type names a channel.** Channels are registered once for the
  whole application, and a type that declares one is describing something it
  does not decide.
- **Every registered channel is offered for every type.** A type cannot be kept
  off a channel, so a channel nobody should get for a given notification is a
  channel that should not be registered.
- **Email and in-app exist without being registered.** An application that
  registers nothing can still send on both.
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
- **Notification types, subscribers and digest schedules all belong in the
  host's code**, never in the gem.
- **Out of scope.** Registering the channels the application has, making a model
  a recipient, setting the current person and account, storing an account's
  addresses, and the pages a person picks their own channels on all belong to
  `notey-install`.
