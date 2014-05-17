# LogV Alpha
Developer tool for better real-time log visualization.

![Screenshot](https://github.com/igorshapiro/logv/raw/master/screenshots/log_sample.png)

**Note**: currently only *Rails* logs are supported. But you're welcome
to contribute a parser for your framework.

## Installation

```sh
npm install -g logv
```

## Usage

```sh
cat some.log | logv
```

or

```sh
rails s | logv
```

Press ESCape for command mode

## Commands

Available commands are:

  - show [list of constraints]
    - Example: show verb=GET path=~users
  - hide [list of contraints]
    - Example: hide verb=GET path=~status
  - reset
    - Resets the filters and shows last 1000 items
  - clear
    - Clears the list

## Features:

- Transforms all log records to Javascript objects, which allows you to
  - Include/exclude them based on attributes
  - query them
- Scopes
  - All logging for a single request can be rendered as 1 expandable line
- Custom highlighting of log records (like SQL, JSON, XML, stacktraces)
- Extendable - you can create a parser for your own log format
- Can run on your server/development machine
- Piping - just do
```sh
  rails s | logv
```
...and enjoy
