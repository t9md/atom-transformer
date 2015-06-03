{BufferedProcess} = require 'atom'
fs   = require 'fs'
path = require 'path'
temp = require 'temp'


class Transformer
  constructor: (@editor) ->
    selection = @editor.getLastSelection()
    @source = selection.isEmpty() and 'buffer' or 'selection'

  input: ->
    if @source is 'buffer'
      @editor.save()
      return
    else
      return @editor.getSelectedText()

  output: (filePath, callback) ->
    options =
      searchAllPanes: true
      activatePane: false
      split: 'right'

    atom.workspace.open(filePath, options).done (editor) =>
      # Clear existing text
      editor.setText ''
      callback editor

  runCommand: ({command, args, options, editor}) ->
    onData   = (data) -> editor.insertText data
    onFinish = (code) ->
      temp.cleanupSync() if @source is 'selection'
      editor.save()

    stdout  = (output) -> onData output
    stderr  = (output) -> onData output
    exit    = (code)   -> onFinish code
    new BufferedProcess {command, args, options, stdout, stderr, exit}

  writeTempfile: (text) ->
    temp.track()
    dir      = temp.mkdirSync "transformer"
    filePath = path.join(dir, "tempfile")
    fs.writeFileSync filePath, text
    return filePath

class CoffeeScript extends Transformer
  transform: (action) ->
    text = @input()

    switch @source
      when 'buffer'
        filePath = @editor.getURI()
      when 'selection'
        filePath = @writeTempfile text
    options = cwd: path.dirname(filePath)

    switch action
      when 'run'
        @output '/tmp/transform', (outEditor) =>
          @runCommand
            command: 'coffee'
            args: [filePath]
            options: options
            editor: outEditor

      when 'compile'
        console.log "Coffee compile"
        @output '/tmp/transform.js', (outEditor) =>
          @runCommand
            command: 'coffee'
            args: ["-cbp","--no-header", filePath]
            options: options
            editor: outEditor

class LESS extends Transformer
  transform: (action) ->

    text     = @editor.getSelectedText() or @editor.getText()
    filePath = @editor.getURI()

    @output '/tmp/transform.css', (outEditor) =>
      less = require 'less'
      resourcePath = atom.themes.resourcePath;
      atomVariablesPath = path.resolve resourcePath, 'static', 'variables'
      options =
        paths: ['.', atomVariablesPath]
        filename: filePath
      less.render text, options, (error, output) ->
        if error
          outEditor.insertText error.message
        else
          outEditor.insertText output.css
        outEditor.save()

module.exports =
  CoffeeScript: CoffeeScript
  LESS:         LESS
