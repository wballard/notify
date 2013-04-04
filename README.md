# Overview #
Notify lets you send messages to users.

# Structure #
Notify uses a `maildir` layout thus:

```
root/
  user/
    cur/
    tmp/
    new/
  user2/
    ...
```


## Message Sending ##
Each individual message in simply a YAML file with no required
structure, though the `notify send` command will write out specific
properties.

Messages are written to `tmp` then renamed into `new`, making for atomic
visibility to receive. This way you don't have to worry abour file locks
or partly written files.

## Message Receiving ##

Messages are received by clients via `notify receive` which returns a
YAML array, nesting each message. It is intended that clients will set
up a file watcher, but you can just as well poll if you need to.
Received messages are moved into `cur`.

## File Naming ##
As a small iteration over classic maildir, new sent messages are written
with `time.pid.yaml`, using millisecond ticks as time rather than second
ticks. This allows slightly higher deliver speed without collision.
Messages are still written first to `tmp`, then renamed into `new`.

## Garbage Collection ##
From time to time, you can sweep away old messagse in `cur` with `notify
clear`.
