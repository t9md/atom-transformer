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
    this.transformer.run(`${this.command} __SOURCE__ > __EDITOR__`)
  }
}
