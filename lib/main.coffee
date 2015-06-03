{CompositeDisposable} = require 'atom'
_    = require 'underscore-plus'
transformers = require './transformer'
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

  transform: (where, action) ->
    return unless editor = @getEditor()
    text = editor.getSelectedText() or editor.getText()

    grammar     = editor.getGrammar()
    Transformer = transformers[grammar.name]

    if Transformer
      transformer = new Transformer(editor)
      transformer.transform action
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
