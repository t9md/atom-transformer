const Transformer = require('./transformer')
const {dirname} = require('path')

module.exports = class CoffeeScript {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: 'coffee',
      args: [sourcePath],
      options: {cwd: dirname(sourcePath)}
    })
  }

  async compile () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: 'coffee',
      args: ['-cbp', '--no-header', sourcePath],
      options: {cwd: dirname(sourcePath)},
      extension: 'js'
    })
  }
}
