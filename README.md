# hey-rb
Ruby-lang clone of https://github.com/masukomi/hey

Track who/what/why/when you get interrupted.

You will need Ruby and SQLite to use `hey-rb`:
- https://www.ruby-lang.org/
- https://www.sqlite.org/

# Setup
Install Ruby and SQLite if you haven't done so already. Homebrew is recommended for Mac users:

```
brew install sqlite
```

Add `hey.rb` to your path, for example:

```
cp hey.rb /usr/local/bin/hey
```

By default, `hey` stores a SQLite database at `~/interrups.db`. You can override the database location by setting the environment variable `INTERRUPT_TRACKER_DB`.

# Usage
<> brackets indicate a required argument.

[] brackets indicate an optional argument.

## Create an event

```
hey <name> [optional reason string]
```

Normalizes the `name` string by converting to lowercase and stripping leading and trailing whitespace. Sets the `start_time` field to `CURRENT_TIMESTAMP`.

## List all events

```
hey list
```

Lists all events in chronological order.

## Adding/revising reason of event

```
hey reason <event_id> [optional reason string]
```

Overwrites the original reason (if any); clears the existing reason if no reason is provided.

## Delete event

```
hey delete <event_id>
```

Permanently deletes the record where `event_id = <event_id>`.
