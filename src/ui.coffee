ReadLine = require 'readline'
ttys = require 'ttys'
blessed = require 'blessed'
screen = blessed.screen({input: ttys.stdin})
program = blessed.program({input: ttys.stdin})
events = require 'events'
Emitter = events.EventEmitter

class UI extends Emitter
  constructor: (@rules) ->
    @logWidget = blessed.list({
      scrollbar: { bg: 'blue' }
      hover: {bg: 'red'}
      parent: screen
      keys: true
      mouse: { wheeldown: (x, y) -> console.log y }
      scrollable: true
      top: 0
      selectedBg: 'yellow'
      height: screen.height - 1
      width: "100%"
    })

    # WORKAROUND: for some reason the 'action' event is fired twice
    # we use the count variable to prevent duplicate runs
    patchCount = 0
    @logWidget.on 'action', =>
      if patchCount == 0
        selectedItem = @logWidget.ritems[@logWidget.selected]
        return unless selectedItem && selectedItem.__items
        selectedItem.toggle()
        patchCount += 1
      else
        patchCount = 0

    statusWidget = blessed.box({
      top: screen.height - 1
      height: 1
      width: screen.width
      bg: "blue"
    })
    statusWidget.setContent("(q)uit")

    screen.append(@logWidget)
    screen.append(statusWidget)
    @logWidget.focus()

    screen.key 'q', ->
      process.exit(0);

    screen.key 'escape', =>
      cmdWidget = blessed.textbox({
        top: screen.height - 1
        height: 1
        width: "100%"
        # keys: true
        bg: 'grey'
        inputOnFocus: true
      })
      screen.append(cmdWidget)
      cmdWidget.on 'submit', (cmd) =>
        @emit('command', cmd)

      cmdWidget.focus()
      cmdWidget.readInput() #((x)-> console.log(x))
      screen.render()

    @screenRefreshLoop()
    @itemsCount = 0

  screenRefreshLoop: () =>
    screen.render()
    setTimeout(@screenRefreshLoop, 200)

  setItems: (items) =>
    @logWidget.setItems([])
    @appendItem(item) for item in items

  appendItem: (item) =>
    unless item.__uiInitialized
      item.__proto__ = LogItem.prototype
      item.__uiInitialized = true
    @itemsCount += 1
    uiElement = @logWidget.add(item)
    item.__uiElement = uiElement
    item.__uiContainer = @logWidget

  updateItem: (item) =>
    element = item.__uiElement
    element.setContent(item.text)

class LogItem
  collapse: ->
    for subItem in this.__items
      this.__uiContainer.removeItem(subItem.__uiElement)
    this.__expanded = false

  expand: ->
    for i in [this.__items.length - 1..1] by -1
      item = this.__items[i]
      item.__uiElement = this.__uiContainer.add(item, this.__uiContainer.selected)
    this.__expanded = true

  toggle: ->
    if this.__expanded then this.collapse() else this.expand()

module.exports = UI
