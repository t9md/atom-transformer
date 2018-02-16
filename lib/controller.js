const _ = require('underscore-plus')
const fs = require('fs-plus')

function isSupportedGrammar (grammar) {
  return grammar.scopeName.startsWith('source') || grammar.scopeName === 'text.html.php'
}

const GRAMMAR_TRANSLATE_TABLE = {
  'Babel ES6 JavaScript': 'JavaScript'
}

module.exports = class Controller {
  static invoke (editor, action) {
    const tranceformer = this.getInstance(editor)
    if (tranceformer) {
      if (typeof tranceformer[action] === 'function') {
        tranceformer[action]()
      }
    }
  }

  static getInstance (editor) {
    const grammar = editor.getGrammar()
    if (!isSupportedGrammar(grammar)) {
      return
    }

    const grammarName = GRAMMAR_TRANSLATE_TABLE[grammar.name] || grammar.name
    const dashName = _.dasherize(grammarName)

    let filePath = `${__dirname}/transformer/${dashName}.js`
    if (!fs.existsSync(filePath)) {
      filePath = `${__dirname}/transformer/generic-transformer`
    }
    const Klass = require(filePath)
    return new Klass(editor)
  }
}
