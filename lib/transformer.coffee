{BufferedProcess} = require 'atom'
fs   = require 'fs-plus'
path = require 'path'
temp = require 'temp'
os   = require 'os'

class Transformer
  needSave:  true
  command:   null
  args:      null
  options:   null
  tempFile:  null
  extension: null
  outFile:   path.join os.tmpdir(), 'transformer'

  constructor: (@editor) ->
    selection = @editor.getLastSelection()
    @source   = selection.isEmpty() and 'buffer' or 'selection'
    @save() if @needSave
    @command ?= @constructor.name.toLowerCase()
    @initialize()

  initialize: ->

  save: ->
    if @source is 'buffer'
      @editor.save() if @editor.isModified()
      @URI = @editor.getURI()
    else if @source is 'selection'
      @URI = @tempFile = @writeTempfile @editor.getSelectedText()
    @dir = path.dirname @URI

  output: (filePath, callback) ->
    unless atom.workspace.paneForURI(fs.absolute(filePath))?
      activePane = atom.workspace.getActivePane()
      switch atom.config.get('transformer.split')
        when 'up'    then activePane.splitUp()
        when 'down'  then activePane.splitDown()
        when 'right' then activePane.splitRight()
        when 'left'  then activePane.splitLeft()

    options =
      searchAllPanes: true
      activatePane: false

    atom.workspace.open(filePath, options).done (editor) ->
      # Clear existing text
      editor.setText ''
      callback editor

  runCommand: ({command, args, options, editor}) ->
    onData   = (data) -> editor.insertText data
    onFinish = (code) ->
      temp.cleanupSync() if @tempFile
      editor.save()

    stdout  = (output) -> onData output
    stderr  = (output) -> onData output
    exit    = (code)   -> onFinish code
    process = new BufferedProcess {command, args, options, stdout, stderr, exit}

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
      @args    ?= [@URI]
      @options ?= cwd: @dir
      @runCommand {@command, @args, @options, editor}

  compile: ->
    @run()

class CoffeeScript extends Transformer
  command: 'coffee'
  compile: ->
    @extension = 'js'
    @args = ["-cbp","--no-header", @URI]
    @run()

class Python extends Transformer

class Ruby extends Transformer

class JavaScript extends Transformer
  command: 'node'

class Go extends Transformer
  initialize: -> @args = ['run', @URI]

class LESS extends Transformer
  needSave: false
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
  CoffeeScript, LESS, Python, Go, JavaScript, Ruby
}
