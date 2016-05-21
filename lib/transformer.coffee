{BufferedProcess} = require 'atom'
fs = require 'fs-plus'
path = require 'path'
temp = require 'temp'
os = require 'os'
less = null
_ = require 'underscore-plus'

class Transformer
  needSave: true
  command: null
  args: null
  tempFile: null
  extension: null

  constructor: (@editor) ->
    @save() if @needSave
    @initialize?()

  setCommand: (@command) ->

  getCommand: ->
    @command ?= @constructor.name.toLowerCase()

  save: ->
    switch
      when @editor.getLastSelection().isEmpty()
        @editor.save() if @editor.isModified()
        @sourcePath = @editor.getPath()
      else
        @sourcePath = @tempFile = @writeToTempfile(@editor.getSelectedText())
    @cwd = path.dirname(@sourcePath)

  writeToTempfile: (text) ->
    temp.track()
    dir = temp.mkdirSync("transformer")
    filePath = path.join(dir, "tempfile")
    fs.writeFileSync(filePath, text)
    return filePath

  getAdjacentPaneForPane: (pane) ->
    return unless children = pane.getParent().getChildren?()
    index = children.indexOf(pane)
    options = {split: 'left', activatePane: false}

    _.chain([children[index-1], children[index+1]])
      .filter (pane) ->
        pane?.constructor?.name is 'Pane'
      .last()
      .value()

  activateAdjacentPane: (direction) ->
    activePane = atom.workspace.getActivePane()
    if pane = @getAdjacentPaneForPane(activePane)
      pane.activate()
    else
      pane = switch direction
        when 'right' then activePane.splitRight()
        when 'down' then activePane.splitDown()
    pane

  openResultEditor: ->
    filePath = do =>
      basePath = path.join(os.tmpdir(), 'transformer')
      if @extension
        "#{basePath}.#{@extension}"
      else
        basePath

    @activateAdjacentPane(atom.config.get('transformer.split'))
    options = {searchAllPanes: true, activatePane: false}
    atom.workspace.open(filePath, options).then (editor) ->
      editor.setText('') # Clear existing text
      editor.isModified = -> false
      editor # pass editor to next Promise::then

  runCommand: ({command, args, options, editor}) ->
    stdout = stderr = (data) -> editor.insertText(data)
    exit = (code) -> temp.cleanupSync() if @tempFile
    # console.log [command, args]
    options = {command, args, options, stdout, stderr, exit}
    new BufferedProcess(options)

  transform: (action) ->
    switch action
      when 'run' then @run()
      when 'compile' then @compile()

  run: ->
    @openResultEditor().then (editor) =>
      command = @getCommand()
      @args ?= [@sourcePath]
      options = {@cwd}
      @runCommand {command, @args, @options, editor}

  compile: ->
    @run()

class CoffeeScript extends Transformer
  command: 'coffee'
  compile: ->
    @extension = 'js'
    @args = ["-cbp", "--no-header", @sourcePath]
    super

class JavaScript extends Transformer
  command: 'node'
  initialize: ->
    @args = ["--harmony", @sourcePath]

class Go extends Transformer
  initialize: ->
    @args = ['run', @sourcePath]

class Less extends Transformer
  needSave: false
  extension: 'css'

  run: ->
    less ?= require('less')
    text = @editor.getSelectedText() or @editor.getText()

    atomVariablesPath = path.resolve(atom.themes.resourcePath, 'static', 'variables')
    renderOptions = {paths: ['.', atomVariablesPath], filename: @editor.getPath()}

    @openResultEditor().then (editor) ->
      less.render text, renderOptions, (error, output) ->
        editor.insertText(
          if error then error.message else output.css
        )

module.exports = {
  Transformer
  CoffeeScript
  JavaScript
  Less
  Go
}
