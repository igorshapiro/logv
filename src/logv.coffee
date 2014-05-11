# For debugging:
# npm install -g node-inspector
# coffee -c -m src/**/*.coffee
# cat sample | node-debug src/logv.js

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

ui = new UI(rules)

currentScope = null
logStream = new LogStream(process.stdin)
rules.on 'item', (x) ->
  _scope = currentScope
  action = if x.__merge then "update" else "append"
  x.text = rules.shortFormat(x)

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

  if action == "update"
    _scope[k] = v for k,v of x when !k.match(/^__/)
    ui.updateItem(_scope)
  else
    ui.appendItem(x)
