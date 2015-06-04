{BufferedProcess} = require 'atom'
fs   = require 'fs'
path = require 'path'
temp = require 'temp'
os = require 'os'

class Transformer
  needSave:  false
  command:   null
  args:      null
  options:   null
  extension: null
  outFile:   path.join os.tmpdir(), 'transformer'

  constructor: (@editor) ->
    selection = @editor.getLastSelection()
    @source   = selection.isEmpty() and 'buffer' or 'selection'
    @save() if @needSave
    @initialize()

  save: ->
    if @source is 'buffer'
      @editor.save() if @editor.isModified()
      @URI = @editor.getURI()
    else if @source is 'selection'
      @URI = @writeTempfile @editor.getSelectedText()
    @dir = path.dirname @URI

  initialize: ->

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
      temp.cleanupSync() if (@source is 'selection') and @needSave()
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

  transform: (action) ->
    switch action
      when 'run'
        @run()
      when 'compile'
        @compile()

  getOutFilePath: ->
    if @extension
      "#{@outFile}.#{@extension}"
    else
      @outFile

  run: ->
    @output @getOutFilePath(), (editor) =>
      options =
        command: @command,
        args:    @args or [@URI]
        options: @options or {cwd: @dir}
        editor:  editor

      @runCommand options

  compile: ->
    @run()

class CoffeeScript extends Transformer
  needSave: true
  command:  'coffee'

  compile: ->
    @extension = 'js'
    @args = ["-cbp","--no-header", @URI]
    @run()

class Python extends Transformer
  needSave: true
  command:  'python'

class JavaScript extends Transformer
  needSave: true
  command:  'node'

class Go extends Transformer
  needSave: true
  command:  'go'

  initialize: ->
    @args = ['run', @URI]

class LESS extends Transformer
  transform: (action) ->
    text     = @editor.getSelectedText() or @editor.getText()
    filePath = @editor.getURI()
    @extension = 'css'

    @output @getOutFilePath(), (outEditor) =>
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

module.exports = {
  CoffeeScript, LESS, Python, Go, JavaScript
}
