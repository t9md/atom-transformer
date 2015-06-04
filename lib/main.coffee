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
      'transformer:run':     => @transform('there', 'run')
      'transformer:compile': => @transform('there', 'compile')

  deactivate: -> @subscriptions.dispose()
  serialize:  ->
  getEditor:  -> atom.workspace.getActiveTextEditor()

  transform: (where, action) ->
    return unless editor = @getEditor()
    
    if Transformer = transformers[editor.getGrammar().name]
      transformer = new Transformer(editor)
      transformer.transform action
