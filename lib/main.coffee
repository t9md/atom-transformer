{CompositeDisposable} = require 'atom'
transformers = require './transformer'

Config =
  split:
    order: 0
    type: 'string'
    default: 'right'
    enum: [
      'none'
      'left'
      'right'
      'up'
      'down'
    ]
    description: "Where output buffer to open"

module.exports =
  subscriptions: null
  config: Config

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscriptions.add atom.commands.add 'atom-workspace',
      'transformer:run': => @transform('there', 'run')
      'transformer:compile': => @transform('there', 'compile')

  deactivate: -> @subscriptions.dispose()
  getEditor:  -> atom.workspace.getActiveTextEditor()

  transform: (where, action) ->
    return unless editor = @getEditor()

    if Transformer = transformers[editor.getGrammar().name]
      transformer = new Transformer(editor)
      transformer.transform action
