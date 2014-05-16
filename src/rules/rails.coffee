colors = require 'colors'
moment = require('moment')
LogVDSL = require('./../dsl')

logv = new LogVDSL()

logv.match(/^\[([\d\s\:\.-]*)\] (\w*) ((.|\r\n)*)/)
  .as('log', (m) -> {severity: m[2], timestamp: m[1]})
  .display((x) -> "#{x.severity.red} #{x.timestamp}")

logv.match(/^Started (\w+) \"(.*)\"/)
  .as('request', (m) -> {verb: m[1], path: m[2]})
  .display((x) ->
    "#{x.verb.blue} #{x.path.yellow}" +
    (" #{x.controller.blue}##{x.action.red} (#{x.contentType.green})" if x.controller) +
    (" #{x.status.green} (#{x.code.green}) in #{x.time.red} #{x.units.red}" if x.status)
  )
  .createScope()

logv.match(/Rendered ([^\s]+)( within ([^\s]+))? \((.*)ms\)/)
  .as('request_rendered', (m) -> {view: m[1], layout: m[3], timeMillis: m[4]})
  .display((x) ->
    "  Rendered".blue + " #{x.view.yellow}" +
    (" (within #{x.layout.yellow})" if x.layout) +
    " (#{x.timeMillis} ms)".red
  )

logv.match(/^Processing by (.*)#(.*) as (\w+)/)
  .as('request_processing', (m) -> {controller: m[1], action: m[2], contentType: m[3]})
  .mergeWithCurrentScope()

logv.match(/^Completed (\d+) (.*?) in (\d+)(\w+)/)
  .as('request_completed', (m) -> {code: m[1], status: m[2], time: m[3], units: m[4]})
  .mergeWithCurrentScope()
  .closeScope()

logv.match(/(\w+)? (Load|SQL) \(([\d\.]+)ms\) (.*)/)
  .as('activerecord', (m) -> {model: m[1], time: m[3], query: m[4]})
  .display((x) ->
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
    if x.model then "  #{x.model.yellow}: #{highlighted}" else highlighted
  )

logv.custom('stacktrace', (line) ->
  regex = /\"(.*?)\:(\d+)\:in \`(.*?)\'\"/g
  stack_lines = []
  m = true
  while (m != null)
    m = regex.exec(line)
    stack_lines.push({file: m[1], line: m[2], method: m[3]}) if m

  return null unless stack_lines.length > 0

  {
    stacktrace: stack_lines
  }
).display((x) ->
  (for l in x.stacktrace
    "#{l.file.yellow}:#{l.line.blue}".underline + " in #{l.method.red}"
  ).join("\r\n")
)
# match()
#   .as('stacktrace')

logv.otherwise('regular', (line) -> {content: line})
  .display((x) -> "#{x.content}")

module.exports = logv.build()
