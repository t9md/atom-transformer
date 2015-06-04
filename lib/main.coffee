{CompositeDisposable} = require 'atom'
_            = require 'underscore-plus'
transformers = require './transformer'
path         = require 'path'
os           = require 'os'

Config = {}
module.exports =
  subscriptions: null
  config:        Config

  activate: (state) ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'transformer:here':    => @transform('here')
      'transformer:run':     => @transform('there', 'run')
      'transformer:compile': => @transform('there', 'compile')

  deactivate: ->
    @subscriptions.dispose()

  serialize: ->

  getEditor: ->
    atom.workspace.getActiveTextEditor()

  surroundWord: (text, str) ->
    _.map text.split("\n"), (line) ->
      line.replace /([^ ]+)/g, str+"$1"+str
    .join("\n")

  transform: (where, action) ->
    return unless editor = @getEditor()

    grammar     = editor.getGrammar()
    Transformer = transformers[grammar.name]

    if Transformer
      transformer = new Transformer(editor)
      transformer.transform action

    # else
    #   text = editor.getSelectedText() or editor.getText()
    #   text = @surroundWord text, '"'
    #
    # selection = editor.getLastSelection()
    # switch where
    #   when 'here'
    #     if selection.isEmpty()
    #       editor.setText text
    #     else
    #       selection.insertText text
    #   when 'there'
    #     @there text
    #     selection.clear()

  there: (text) ->
    editor = @getEditor()
    grammar = editor.getGrammar()
    filePath = path.join os.tmpdir(), 'transformer'

    options =
      searchAllPanes: true
      split: 'right'

    atom.workspace.open(filePath, options).done (editor) =>
      editor.insertText text
      editor.setGrammar grammar
