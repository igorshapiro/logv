#!/usr/bin/env coffee

# For debugging:
# npm install -g node-inspector
# coffee -c -m src/**/*.coffee && cat sample | node-debug src/logv.js
# rm src/**/*.js src/**/*.map

# Profiling:
# npm install -g tick
# cat sample | coffee --nodjs --prof src/logv.coffee
# node-tick-processor v8.log


sys = require 'sys'
events = require 'events'
Emitter = events.EventEmitter
byline = require 'byline'
colors = require 'colors'
Type = require 'type-of-is'
rules = (require './rules').rails
UI = require './ui'

class LogStream extends Emitter
  constructor: (stream) ->
    @buffer = ""
    @lineStream = byline.createStream(stream, {encoding: 'utf8'})

    @lineStream.on 'data', (line) =>
      rules.appendLine(line)

BUFFER_SIZE = 1000
buffer = []

ui = new UI(rules)
filters = []

parseCmd = (s) ->
  match = s.match /^(show|hide) (.*)$/
  return null unless match
  cmd = {command: match[1]}
  cmd.constraints = for expr in match[2].split(' ')
    expr_match = expr.match /^(\w+)(\=|\!\=)(.*)$/
    {
      left: expr_match[1],
      operator: expr_match[2],
      right: expr_match[3]
    }
  return cmd

matches = (obj, constraints) ->

# console.log(parseCmd('hide type=exception path!=http://localhost/api/v1/'))
# process.exit(0)

ui.on('command', (cmd) ->
  debugger
  if cmd == 'clear'
    ui.setItems([])
    return
  if cmd == 'reset'
    ui.setItems(buffer)
    return
)

currentScope = null
logStream = new LogStream(process.stdin)
rules.on 'item', (x) ->
  _scope = currentScope
  action = "append"
  # debugger if x.__type == "activerecord"

  if x.__scope == 'open'
    x.__parentScope = currentScope
    currentScope = x
  else if x.__scope == 'close'
    currentScope = currentScope.__parentScope if currentScope
  else if currentScope && !x.__merge
    x.__parentScope = currentScope
    currentScope.__items = [] unless currentScope.__items
    currentScope.__items.push(x)
    action = "update"

  if x.__merge
    _scope[k] = v for k,v of x when !k.match(/^(__|text$)/)
    _scope.text = rules.shortFormat(_scope)
    action = "update"
  else
    x.text = rules.shortFormat(x)

  if action == "update"
    ui.updateItem(_scope)
  else
    buffer.push(x)
    buffer.splice(0, 1) if buffer.length > BUFFER_SIZE
    ui.appendItem(x)
