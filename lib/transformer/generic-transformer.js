const Transformer = require('./transformer')
const {dirname} = require('path')

module.exports = class GenericTransformer {
  constructor (editor) {
    this.command = editor.getGrammar().name.toLowerCase()
    this.transformer = new Transformer(editor)
  }

  async run () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: this.command,
      args: [sourcePath],
      options: {cwd: dirname(sourcePath)}
    })
  }
}
