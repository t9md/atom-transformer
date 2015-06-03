{CompositeDisposable, BufferedProcess} = require 'atom'
_    = require 'underscore-plus'
fs   = require 'fs'
path = require 'path'
temp = null

Config = {}

module.exports =
  subscriptions: null
  config: Config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'transform:here':           => @transform('here')
      'transform:coffee-run':     => @transform('there', 'run')
      'transform:coffee-compile': => @transform('there', 'compile')

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  surroundWord: (text, str) ->
    _.map text.split("\n"), (line) ->
      line.replace /([^ ]+)/g, str+"$1"+str
    .join("\n")

  writeTempfile: (text, cb) ->
    temp ?= require('temp').track()
    dir      = temp.mkdirSync "transformer"
    filePath = path.join(dir, "tempfile")

    fs.writeFileSync filePath, text
    cb filePath

  transform: (where, action) ->
    return unless editor = @getEditor()
    text = editor.getSelectedText() or editor.getText()

    grammar = editor.getGrammar()
    if grammar.name is 'CoffeeScript'
      switch action
        when 'compile'
          @transformCoffee text
        when 'run'
          console.log 'run'
          @runCoffee text
      return
    else
      text = @surroundWord text, '"'

    selection = editor.getLastSelection()
    switch where
      when 'here'
        if selection.isEmpty()
          editor.setText text
        else
          selection.insertText text
      when 'there'
        @there text
        selection.clear()

  runCoffee: (text) ->
    editor = @getEditor()
    editor.save()

    runFile = (command, args, cb, finish, options) ->
      stdout  = (output) -> cb output
      stderr  = (output) -> cb output
      exit    = (code)   -> finish(code)
      process = new BufferedProcess {command, args, options, stdout, stderr, exit}

    outfilePath = "/tmp/transform"
    options =
      searchAllPanes: true
      activatePane: false
      split: 'right'

    atom.workspace.open(outfilePath, options).done (outEditor) ->
      outEditor.setText '' # clear
      onData   = (data) -> outEditor.insertText data
      onFinish = (code) -> outEditor.save()
      runFile 'coffee', [editor.getURI()], onData, onFinish, cwd: path.dirname(editor.getURI())


  transformCoffee: (text) ->
    filePath = "/tmp/transform.js"
    options =
      searchAllPanes: true
      activatePane: false
      split: 'right'

    pane = atom.workspace.getActivePane()

    atom.workspace.open(filePath, options).done (editor) =>
      editor.setText '' # clear
      onData   = (data) -> editor.insertText data
      onFinish = (code) -> temp.cleanupSync(); editor.save()

      @compileCoffee text, onData, onFinish

  compileCoffee: (text, cb, finish) ->
    @writeTempfile text, (filePath) ->
      command = 'coffee'
      args    = ["-cbp","--no-header", filePath]
      stdout  = (output) -> cb output
      stderr  = (output) -> cb output
      exit    = (code)   -> finish(code)
      process = new BufferedProcess {command, args, stdout, stderr, exit}

  there: (text) ->
    editor = @getEditor()
    grammar = editor.getGrammar()
    filePath  = "/tmp/transform"

    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(filePath, options).done (editor) =>
      editor.insertText text
      editor.setGrammar grammar

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->
