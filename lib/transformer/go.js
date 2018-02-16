const Transformer = require('./transformer')
const {dirname} = require('path')

module.exports = class Go {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: 'go',
      args: ['run', sourcePath],
      options: {cwd: dirname(sourcePath)}
    })
  }
}
