const Transformer = require('./transformer')

module.exports = class CoffeeScript {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    this.transformer.execute('coffee __SOURCE__')
  }

  async compile () {
    this.transformer.execute('coffee -cbp --no-header __SOURCE__', {
      extension: 'js'
    })
  }
}
