const Transformer = require('./transformer')

module.exports = class Haskell {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    this.transformer.run('stack __SOURCE__ > __EDITOR__')
  }
}
