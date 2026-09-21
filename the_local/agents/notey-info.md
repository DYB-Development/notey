---
name: notey-info
description: Use to learn what notey offers — notification types and the channels they allow, per-person per-account delivery preferences, digest windows, an in-app inbox, and per-account destinations.
tools: Read
scope: notifications — application-wide channel registrations, notification types that name no channel, per-person per-account channel preferences, digest windows, an in-app inbox, per-account destinations, and a record of what was sent on each channel that the host keeps for a period it sets
---

This local explains what notey is and which of its other two locals you need. It
changes nothing and gives no steps.

## What notey is

notey is the notification layer for a multi-tenant Rails app, built on top of
Noticed. Noticed delivers a notification on whatever channels a notifier
declares. notey decides which of those channels a given person actually gets,
per notification type and per account they belong to, stores that decision, and
gives them screens to change it. It also scopes the in-app inbox to the account
the person is currently in, holds notifications back into daily or weekly
digests when that is what the person asked for, keeps a per-account address for
channels that deliver to the account rather than to a person, and delivers a
notification when a domain event the host publishes says to.

Reach for it when the same person belongs to more than one account and wants
different notifications in each, when notifications should arrive grouped rather
than one at a time, or when a channel's address belongs to the account rather
than to the person. It is not worth reaching for to send one transactional email
to one address.

## Interface

The manifest declares no commands for this local, so nothing here is called.

Standing notey up in a host app — the tables, the engine, the declaration of
which notification types exist and which channels each one offers, the models
that receive and send, and the screens people set their own preferences on — is
the install local, `notey-install`.

Building on notey once it is installed — tying a notifier to a notification
type, delivering one when a domain event fires, holding a delivery back unless
the person wants it on that channel, addressing a channel from the account's
destination, reading the inbox, and running the digests — is the develop local,
`notey-develop`.

## How to use it

Two questions settle which local you need. If the host app does not yet have
notey's tables, engine and declared notification types, you are installing, and
`notey-install` owns every step of that. If it does and you are adding a new
notification, changing when an existing one goes out, or reading what a person
has already been sent, you are building, and `notey-develop` owns it.

## Conventions

- **Notification type** — the name of one kind of notification, as a string. It
  is the unit everything else is keyed by: a person's preference and the name a
  notification type declares.
- **Channel** — a named way of delivering, such as email or a chat webhook,
  registered once for the whole application. Email and in-app exist without
  being registered; anything else exists only if the application registered it.
  Every registered channel is offered for every notification type.
- **Member** — the person a preference belongs to. It is polymorphic, so a host
  app names whichever model of its own receives notifications.
- **Account** — the tenant. Preferences, notifications, digests and destinations
  are all scoped to one, so the same person in two accounts has two independent
  sets of preferences and two separate inboxes.
- **Preference** — one stored row per member, per account, per notification
  type, holding the channels chosen and the digest window.
- **Digest window** — `immediate`, `daily` or `weekly`. Immediate sends as the
  notification happens; the other two hold it for a grouped email covering the
  current day or week.
- **Destination** — one address per account per channel, with an optional stored
  credential, optionally owned by one person. A notification for a person uses
  the address that person set, never the account's.
- **Inbox** — the notifications a member has received within one account, which
  is what the in-app list reads and what a digest gathers from.
- **Notification type** — the class describing what one notification carries and
  what a person reads on it. It names no channel, because notey builds the
  delivery list from the registered channels and decides each one against the
  recipient's stored preference.
- **Attempt** — one row per notification per outbound channel, claimed before the
  send and marked after, holding whether it was sent and what a failure said. It
  is what answers why one person was not reached, and it is what stops the same
  channel sending twice for the same notification. The host says how long these
  are kept and runs the deletion that enforces it.
