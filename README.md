# Notey

Notey is the notification layer for multi-tenant Rails apps. It sits on top of
[Noticed](https://github.com/excid3/noticed), which every app here already
depends on, and supplies the parts Noticed leaves to the host.

## What Noticed already does

- **Recipients.** A notifier declares `recipients`, and delivery inserts one
  `noticed_notifications` row per recipient.
- **In-app records.** Every notification is written to the database, with
  read/unread and seen/unseen state.
- **Channels.** Email, SMS through Twilio or Vonage, iOS, FCM, Action Push,
  Slack, Discord, Microsoft Teams, webhooks, and Action Cable.

## What Notey adds

- **Preferences.** Which channels a person wants for each notification type,
  stored rather than left to an `if:` lambda over a column the host invents.
- **Preference screens.** The pages a person sets those preferences on.
- **An inbox.** In-app notification screens scoped to the account the person is
  currently in, rather than one merged list across every account they belong to.
- **Digests.** Grouping notifications over a window instead of sending each one
  as it happens.

## Status

Nothing is built yet. The plan is filed as a `type:plan` issue on this repo.

## Development

After checking out the repo, run `bin/setup` to install dependencies, then
`bundle exec rake test` to run the tests and `bin/rubocop` for the linter.

## License

The gem is available as open source under the terms of the
[MIT License](https://opensource.org/licenses/MIT).
