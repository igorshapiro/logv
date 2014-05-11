ReadLine = require 'readline'
ttys = require 'ttys'
blessed = require 'blessed'
screen = blessed.screen({input: ttys.stdin})
program = blessed.program({input: ttys.stdin})

class UI
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
    logWidget = @logWidget

    # WORKAROUND: for some reason the 'action' event is fired twice
    # we use the count variable to prevent duplicate runs
    patchCount = 0
    logWidget.on 'action', ->
      if patchCount == 0
        selectedItem = logWidget.ritems[logWidget.selected]
        return unless selectedItem.__items
        if selectedItem.__expanded
          for subItem in selectedItem.__items
            logWidget.removeItem(subItem.__uiElement)
          selectedItem.__expanded = false
        else
          for i in [selectedItem.__items.length - 1..1] by -1
            item = selectedItem.__items[i]
            item.__uiElement = logWidget.add(item, logWidget.selected)
          selectedItem.__expanded = true
        screen.render()
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

    screen.key 'escape', ->
      cmdWidget = blessed.textarea({
        top: screen.height - 1
        height: 1
        width: "100%"
        # keys: true
        bg: 'grey'
        inputOnFocus: true
      })
      screen.append(cmdWidget)
      cmdWidget.focus()
      cmdWidget.readInput((x)-> console.log(x))
      screen.render()

    screen.render()
    @itemsCount = 0

  appendItem: (item) =>
    @itemsCount += 1
    uiElement = @logWidget.add(item)
    item.__uiElement = uiElement
    screen.render()

  updateItem: (item) =>
    element = item.__uiElement
    element.setContent(@rules.shortFormat(item))
    screen.render()

module.exports = UI
