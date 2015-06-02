{CompositeDisposable, BufferedProcess} = require 'atom'
_    = require 'underscore-plus'
path = require 'path'

# scope2extname = require './scope2extname'

expandPath = (str) ->
  if str.substr(0, 2) == '~/'
    str = (process.env.HOME or process.env.HOMEPATH or process.env.HOMEDIR or process.cwd()) + str.substr(1);
  path.resolve str

Config = {}

module.exports =
  subscriptions: null
  config: Config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'transform:here':  => @transform('here')
      'transform:there': => @transform('there')

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  surroundWord: (text, str) ->
    _.map text.split("\n"), (line) ->
      line.replace /([^ ]+)/g, str+"$1"+str
    .join("\n")

  transform: (where) ->
    return unless editor = @getEditor()
    text = editor.getSelectedText() or editor.getText()

    grammar = editor.getGrammar()

    if grammar.name is 'CoffeeScript'
      text = @transformCoffee(text)
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

    console.log text

  transformCoffee: (text) ->
    command = 'coffee -s'
    args = ['-s']
    stdout = (output) -> console.log(output)
    exit = (code) -> console.log("ps -ef exited with #{code}")
    process = new BufferedProcess({command, args, stdout, exit})
    "HOGE"

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

  getSupportedScopeNames: ->
    atom.grammars.getGrammars().map (grammar) -> grammar.scopeName

  detectCursorScope: ->
    supportedScopeNames = @getSupportedScopeNames()

    cursor = @getActiveTextEditor().getLastCursor()
    scopesArray = cursor.getScopeDescriptor().getScopesArray()
    scope = _.detect scopesArray.reverse(), (scope) ->
      scope in supportedScopeNames
    scope

  overrideGrammarForPath: (filePath, scopeName) ->
    return if @grammarOverriddenPaths[filePath] is scopeName
    atom.grammars.clearGrammarOverrideForPath filePath
    atom.grammars.setGrammarOverrideForPath filePath, scopeName
    @grammarOverriddenPaths[filePath] = scopeName

  getActiveTextEditor: ->
    atom.workspace.getActiveTextEditor()

  determineFilePath: (scopeName, URI) ->
    rootDir  = expandPath atom.config.get('try.root')
    basename = atom.config.get('try.basename')

    # Strategy
    # Determine appropriate filename extension in following order.
    #  1. From scope2extname table
    #  2. Original filename's extension
    #  3. ScopeName itself.
    ext  = scope2extname[scopeName]
    ext ?= (path.extname URI).substr(0)
    ext ?= scopeName
    path.join rootDir, "#{basename}.#{ext}"

  paste: ->
    editor    = @getActiveTextEditor()
    URI       = editor.getURI()
    selection = editor.getLastSelection()
    scopeName = @detectCursorScope()
    filePath  = @determineFilePath scopeName, URI
    @overrideGrammarForPath filePath, scopeName

    options = searchAllPanes: atom.config.get('try.searchAllPanes')
    if atom.config.get('try.split') isnt 'none'
      options.split = atom.config.get 'try.split'

    atom.workspace.open(filePath, options).done (editor) =>
      switch atom.config.get('try.pasteTo')
        when 'top'    then editor.moveToTop()
        when 'bottom' then editor.moveToBottom()

      unless selection.isEmpty()
        editor.insertText selection.getText(),
          select: atom.config.get('try.select')
          autoIndent: atom.config.get('try.autoIndent')

        selection.clear() if atom.config.get('try.clearSelection')
