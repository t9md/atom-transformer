const Transformer = require('./transformer')

module.exports = class Go {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    this.transformer.execute('go run __SOURCE__')
  }
}
