const Transformer = require('./transformer')

module.exports = class GenericTransformer {
  constructor (editor) {
    this.command = editor
      .getGrammar()
      .name.toLowerCase()
      .split(/\s+/)
      .shift()
    this.transformer = new Transformer(editor)
  }

  async run () {
    this.transformer.execute(`${this.command} __SOURCE__`)
  }
}
