class CommandBase
  constructor: (@buffer, @ui) ->

class ResetCommand extends CommandBase
  execute: -> @ui.setItems(@buffer)

class ClearCommand extends CommandBase
  execute: -> @ui.setItems([])

class FilterCommandBase extends CommandBase
  constructor: (@buffer, @ui, cmdString) ->
    super(@buffer, @ui)

    match = cmdString.match /^\w+ (.*)$/
    throw "Unknown command: #{cmdString}" unless match

    @constraints = for expr in match[1].split(' ')
      expr_match = expr.match /^(\w+)(\=|\!\=)(.*)$/
      {
        left: expr_match[1],
        operator: expr_match[2],
        right: expr_match[3]
      }

  matchConstraint: (item, c) ->
    return item[c.left] == c.right if c.operator == '='
    return item[c.left] != c.right if c.operator == '!='
    return false

  isMatch: (item)->
    (c for c in @constraints when @matchConstraint(item, c)).length > 0

class ShowCommand extends FilterCommandBase
  execute: -> @ui.setItems(item for item in @buffer when @isMatch(item))

class HideCommand extends FilterCommandBase
  execute: -> @ui.setItems(item for item in @buffer when !@isMatch(item))

class CommandParser
  constructor: (@buffer, @ui) ->

  parse: (s) ->
    return new ResetCommand(@buffer, @ui) if s == 'reset'
    return new ClearCommand(@buffer, @ui) if s == 'clear'
    return new ShowCommand(@buffer, @ui, s) if s.match(/^show\s/)
    return new HideCommand(@buffer, @ui, s) if s.match(/^hide\s/)

module.exports = CommandParser
