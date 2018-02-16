const Transformer = require('./transformer')
const {dirname} = require('path')

module.exports = class Haskell {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: 'stack',
      args: [sourcePath],
      options: {cwd: dirname(sourcePath)}
    })
  }
}
