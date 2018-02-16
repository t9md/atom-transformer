{BufferedProcess} = require 'atom'
fs = require 'fs-plus'
path = require 'path'
temp = require 'temp'
os = require 'os'
less = null
_ = require 'underscore-plus'

getBaseName = (file) ->
  path.basename(file, path.extname(file))

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
        text = @editor.getSelectedText()
        extname = path.extname(@editor.getPath())
        @sourcePath = @tempFile = @writeToTempfile(text, extname)
    @cwd = path.dirname(@sourcePath)

  cleanupTemp: ->
    temp.cleanupSync() if @tempFile

  writeToTempfile: (text, extname=null) ->
    temp.track()
    dir = temp.mkdirSync("transformer")
    fileName = 'tempfile'
    fileName = "#{fileName}#{extname}" if extname
    filePath = path.join(dir, fileName)
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

    originalPane = atom.workspace.getActivePane()
    @activateAdjacentPane(atom.config.get('transformer.split'))
    options = {searchAllPanes: true, activatePane: false}
    atom.workspace.open(filePath, options).then (editor) ->
      editor.setText('') # Clear existing text
      editor.isModified = -> false
      originalPane.activate()
      return editor # pass editor to next Promise::then

  runCommand: ({command, args, options, stdout, stderr, exit}) ->
    new Promise (resolve) ->
      exit ?= (code) -> resolve()
      # env =
      # options.env = Object.assign({}, process.env)
      NODE_PATH = '/usr/local/lib/node_modules'
      options.env = Object.assign({}, process.env, {NODE_PATH})
      options = {command, args, options, stdout, stderr, exit}
      new BufferedProcess(options)

  transform: (action) ->
    switch action
      when 'run' then @run()
      when 'compile' then @compile()

  run: ->
    runCommand = (editor) =>
      command = @getCommand()
      args = @args ? [@sourcePath]
      options = {@cwd}
      stdout = stderr = (data) -> editor.insertText(data)
      @runCommand({command, args, options, stdout, stderr})

    cleanupTemp = @cleanupTemp.bind(this)

    @openResultEditor()
      .then(runCommand)
      .then(cleanupTemp)

  compile: ->
    @run()

class CoffeeScript extends Transformer
  command: 'coffee'
  compile: ->
    @extension = 'js'
    @args = ["-cbp", "--no-header", @sourcePath]
    super

class JavaScript extends Transformer
  command: 'babel-node'
  initialize: ->
    @args = ["--presets=stage-2", @sourcePath]

  compile: ->
    @command = 'babel'
    @extension = 'es6.js'
    super

class Go extends Transformer
  initialize: ->
    @args = ['run', @sourcePath]

class Haskell extends Transformer
  command: 'stack'

class OCaml extends Transformer
  compile: ->
    @extension = 'js'

    dirName = path.dirname(@sourcePath)
    outputFile = path.join(dirName, getBaseName(@sourcePath) + ".js")

    compile = =>
      command = 'bsc'
      args = ["-I", ".", "-c", @sourcePath]
      options = {@cwd}
      stdout = stderr = ->
      @runCommand({command, args, options, stdout, stderr})

    openResultEditor = @openResultEditor.bind(this)

    writeToBuffer = (editor) =>
      command = 'cat'
      args = [outputFile]
      options = {@cwd}
      stdout = stderr = (data) -> editor.insertText(data)
      @runCommand({command, args, options, stdout, stderr})

    cleanup = =>
      @cleanupTemp()
      baseName = getBaseName(@sourcePath)
      dirName = path.dirname(@sourcePath)
      fs.removeSync(path.join(dirName, "#{baseName}.cmi"))
      fs.removeSync(path.join(dirName, "#{baseName}.cmj"))

    compile()
      .then(openResultEditor)
      .then(writeToBuffer)
      .then(cleanup)

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
  OCaml
  Haskell
}
