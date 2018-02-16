const Transformer = require('./transformer')

module.exports = class Haskell {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    this.transformer.execute('stack __SOURCE__')
  }
}
