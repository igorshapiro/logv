events = require 'events'
Emitter = events.EventEmitter

class AbstractMatcher
  display: (@displayFunc) =>
    @
  createScope: =>
    @scope = 'open'
    @
  closeScope: =>
    @scope = 'close'
    @
  mergeWithCurrentScope: =>
    @merge = true
    @

class Matcher extends AbstractMatcher
  constructor: (@regex) ->
  as: (@logItemType, @logItemFunc) => @
  match: (line) =>
    m = line.match(@regex)
    return null unless m
    @logItemFunc(m)

class CustomMatcher extends AbstractMatcher
  constructor: (@logItemType, @logItemFunc) ->
  match: (line) =>
    @logItemFunc(line)

class Rules extends Emitter
  constructor: ->
    @matchers = []
  append: (matcher) =>
    @matchers.push(matcher)
    matcher
  otherwise: (matcher) =>
    @otherwiseMatcher = matcher
  addMetadata: (item, matcher) ->
    throw "Matcher not provided" unless matcher
    item.__scope = matcher.scope if matcher.createScope
    item.__merge = matcher.merge if matcher.merge
    item.__type = matcher.logItemType if matcher.logItemType
    item.__matcher = matcher
    item

  normalizeString: (s) ->
    s.replace(/\033\[[0-9;]*m/g, "")    # Remove terminal colors

  appendLine: (line) =>
    line = @normalizeString(line)
    for m in @matchers
      logItem = m.match(line)
      if logItem
        @emit('item', @addMetadata(logItem, m))
        return
    if @otherwiseMatcher
      item = @otherwiseMatcher.match(line)
      return unless item
      @emit('item', @addMetadata(item, @otherwiseMatcher))
  shortFormat: (logItem) ->
    return null unless logItem.__matcher.displayFunc
    logItem.__matcher.displayFunc(logItem)

module.exports = class DSL
  constructor: ->
    @rules = new Rules()
  match: (regex) =>
    @rules.append(new Matcher(regex))
  custom: (logItemType, logItemFunc) =>
    @rules.append(new CustomMatcher(logItemType, logItemFunc))
  otherwise: (logItemType, logItemFunc) =>
    @rules.otherwise(new CustomMatcher(logItemType, logItemFunc))
  build: ->
    @rules
