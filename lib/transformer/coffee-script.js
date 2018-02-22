const Transformer = require('./transformer')

module.exports = class CoffeeScript {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    this.transformer.run('coffee __SOURCE__ > __EDITOR__')
  }

  async compile () {
    this.transformer.run('coffee -cbp --no-header __SOURCE__ > __EDITOR__.js')
  }
}
