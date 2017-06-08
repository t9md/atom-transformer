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

grammarTranslateTable =
  'Babel ES6 JavaScript': 'JavaScript'

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

  isSupportedGrammar: (grammar) ->
    grammar.scopeName.startsWith('source') or grammar.scopeName is 'text.html.php'

  translateGrammarName: (grammar) ->
    if grammar.name of grammarTranslateTable
      grammarTranslateTable[grammar.name]
    else
      grammar.name

  getTransformer: ->
    editor = atom.workspace.getActiveTextEditor()
    grammar = editor.getGrammar()
    return unless @isSupportedGrammar(grammar)

    grammarName = @translateGrammarName(grammar)
    if klass = transformers[grammarName]
      new klass(editor)
    else
      # When specific transformer not found. Try with lowercased command
      # e.g. PHP -> php, Ruby -> ruby
      {Transformer} = transformers
      transformer = new Transformer(editor)
      transformer.setCommand(grammarName.toLowerCase())
      transformer

  transform: (action) ->
    transformer = @getTransformer()
    transformer?.transform(action)
