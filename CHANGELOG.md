# Changelog

## Unreleased

- Nothing yet.

## 0.3.0

### Added

- `Notey.attempt_retention`, which says how long notey keeps the record of what
  it sent on each channel.
- `Notey::DeleteOldAttempts`, which deletes every record older than that period
  and refuses to run when no period is set. Nothing is deleted until the host
  runs it, and a host schedules it the way it schedules the digest windows.

### Fixed

- A person whose record holds no email address is skipped on email rather than
  sent to. Before this the send failed at the mail server, a failed delivery
  attempt was recorded against that person, and the job backend retried a send
  that could never succeed. One unreachable person also stopped the notification
  reaching everyone else on that channel.

## 0.2.0

An application now says once which channels it can send on, and a notification
type says nothing about channels at all. Upgrading from 0.1.0 means rewriting
every notifier as a notification type and replacing the catalog with channel
registrations; there is no deprecation path.

### Removed

- `Notey.catalog`. Register each channel with `Notey.channel` instead, once for
  the whole application.
- `Notey::Notifier` and its `notey_type` declaration. Inherit from
  `Notey::Notification` and declare `notey_type` there instead.
- `Notey.wanted`, `Notey.addressed` and `Notey.destination_address`. Notey now
  decides every channel itself, and a delivery method reads the address it sends
  to through `Notey::Destinations.for`.
- `Notey.deliver_on`, `Notey.notifier_for` and `Notey::EventDelivery`. A
  subscriber resolves its own recipients and calls the notification type.
- The boot checks for an undeclared type and for a channel nothing delivers on,
  replaced by a check that every registered channel can send.

### Added

- `Notey.channel`, which registers one channel the application can send on,
  naming the delivery method that sends it and whether it needs an address.
- Email and in-app on every application without registering anything.
- `Notey::Notification`, the class a notification type inherits, whose delivery
  list is built from the registered channels each time it is read.
- `notify`, which sends a notification to the recipients the caller resolved.
- `notey_attempts`, one row per notification per outbound channel, holding
  whether it was sent and what a failure said.
- `Notey::Attempt#send_again`, which sends one failed channel again and leaves
  the channels that already reached the person alone.
- A boot check that refuses a channel whose delivery method does not exist or
  needs an option notey does not supply.

### Changed

- A person's stored choice of a channel the application no longer has is
  ignored rather than attempted, and the stored row is kept.
- The preferences screen offers every registered channel, and the destination
  screens offer only the channels that need an address.

## 0.1.0

- First release.
