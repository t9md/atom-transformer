{CompositeDisposable} = require 'atom'
transformers = require './transformer'

Config =
  split:
    order: 0
    type: 'string'
    default: 'right'
    enum: [
      'right'
      'down'
    ]
    description: "Where output buffer to open"

module.exports =
  subscriptions: null
  config: Config

  activate: ->
    @subscriptions = new CompositeDisposable
    @subscribe atom.commands.add 'atom-text-editor',
      'transformer:run': => @transform('run')
      'transformer:compile': => @transform('compile')

  subscribe: (args...) ->
    @subscriptions.add(args...)

  deactivate: ->
    @subscriptions.dispose()

  getTransformer: ->
    editor = atom.workspace.getActiveTextEditor()
    className = editor.getGrammar().name
    if klass = transformers[className]
      new klass(editor)

  transform: (action) ->
    transformer = @getTransformer()
    transformer?.transform(action)
