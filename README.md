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

Optionally, add `hey.bc` to your local `bash_completion.d` directory:

```
cp hey.bc /usr/local/etc/bash_completion.d/hey
. /usr/local/etc/bash_completion.d/hey
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

## Mark an event as done

```
hey end
```

Sets the most recent event's `end_time` to `CURRENT_TIMESTAMP` if and only if the current `end_time` is `null`.

## Bulk rename events

```
hey rename <old_name> <new_name> [event_id]
```

Changes the `name` field of **all** events where `name = <old_name>`.

If `event_id` is specified then only the record corresponding to the id is updated and only if the `name` field is equal to the `<old_name>`.

## Delete event

```
hey delete <event_id>
```

Permanently deletes the record where `event_id = <event_id>`.

## Delete events by name

```
hey kill <name>
```

Permanently deletes **all** events where `name = <name>`.

## Generate reports of events

```
hey report <report_type>
```

|report_type|description|
|-----------|-----------|
| `count`   | Count of number of events in the database |
| `names`   | Tabular results of events by name |
| `hourly`  | Tabular results of events by hour of the day |
| `daily`   | Tabular results of events by day of the week |
