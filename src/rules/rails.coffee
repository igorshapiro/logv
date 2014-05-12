colors = require 'colors'
events = require 'events'
Emitter = events.EventEmitter
moment = require('moment')

class RailsLogParser extends Emitter
  appendLine: (line, scope) ->
    SIMPLE_LOG_LINE = /^\[([\d\s\:\.-]*)\] (\w*) ((.|\r\n)*)/
    match = line.match(SIMPLE_LOG_LINE)
    if match
      @emit('item', {
        __scope: false,
        __type: 'log'
        severity: match[2],
        timestamp: match[1]
      })
      return

    REQUEST_START = /^Started (\w+) \"(.*)\"/
    match = line.match(REQUEST_START)
    if match
      @emit('item', {
        __scope: "open",
        __type: 'request',
        verb: match[1]
        path: match[2]
      })
      return

    REQUEST_RENDER = /Rendered ([^\s]+)( within ([^\s]+))? \((.*)ms\)/
    match = line.match(REQUEST_RENDER)
    if match
      @emit('item', {
        __type: 'request_rendered',
        view: match[1]
        layout: match[3]
        timeMillis: match[4]
      })
      return

    REQUEST_PROCESSING = /^Processing by (.*)#(.*) as (\w+)/
    match = line.match(REQUEST_PROCESSING)
    if match
      @emit('item', {
        __type: "request_processing"
        __merge: true
        controller: match[1]
        action: match[2]
        contentType: match[3]
      })
      return

    REQUEST_END = /^Completed (\d+) (.*?) in (\d+)(\w+)/
    match = line.match(REQUEST_END)
    if match
      @emit('item', {
        __scope: "close"
        __type: 'request_completed'
        __merge: true
        code: match[1],
        status: match[2]
        time: match[3]
        units: match[4]
      })
      return

    ACTIVERECORD_LOG = /(\w+)? (Load|SQL) \(([\d\.]+)ms\) (.*)/
    match = line.match(ACTIVERECORD_LOG)
    if match
      @emit('item', {
        __type: 'activerecord'
        model: match[1]
        time: match[3]
        query: match[4]
      })
      return

    STACKTRACE = /\"(.*?)\:(\d+)\:in \`(.*?)\'\"/g
    match = true
    stack_items = []
    while (match != null)
      match = STACKTRACE.exec(line)
      stack_items.push({
        file: match[1]
        line: match[2]
        method: match[3]
      }) if match
    if stack_items.length > 0
      @emit('item', {
        __type: 'stacktrace',
        stacktrace: stack_items
      })
      return

    @emit('item', {
      __type: 'regular'
      content: line
    })

  shortFormat: (x) ->
    return "#{x.severity.red} #{x.timestamp}" if x.__type == 'log'
    if x.__type == 'request'
      s = "#{x.verb.blue} #{x.path.yellow}"
      s = s + " #{x.controller.blue}##{x.action.red} (#{x.contentType.green})" if x.controller
      s = s + " #{x.status.green} (#{x.code.green}) in #{x.time.red} #{x.units.red}" if x.status
      return s
    if x.__type == 'request_rendered'
      s = "  Rendered".blue + " #{x.view.yellow}"
      s = s + " (within #{x.layout.yellow})" if x.layout
      s = s + " (#{x.timeMillis} ms)".red
      return s
    if x.__type == 'stacktrace'
      s = ""
      for l in x.stacktrace
        s += "#{l.file.yellow}:#{l.line.blue}".underline + " in #{l.method.red}\r\n" 
      return s
    if x.__type == 'activerecord'
      highlighted =
      x.query.replace(
        /\s(HAVING|LIMIT|DELETE|UPDATE|INSERT|SELECT|WHERE|FROM|GROUP|ORDER|LEFT OUTER JOIN|INNER JOIN|UNION)\s/g,
        "\r\n\t\t$1 ".blue
      ).replace(
        /\s(ASC|DESC)\s/g,
        " $1 ".blue
      ).replace(
        /\s(OR|AND|IS|NOT|\=|\<\>)\s/g,
        " $1 ".yellow
      ).replace(
        /\s(ON|AS|DISTINCT|NULL\s)/g,
        " $1 ".red
      )
      s = if x.model then "  #{x.model.yellow}: #{highlighted}" else highlighted
      return s
    return "#{x.content}" if x.__type == "regular"

module.exports = new RailsLogParser()
