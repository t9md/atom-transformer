const Transformer = require('./transformer')
const {dirname} = require('path')

module.exports = class JavaScript {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  getEnv () {
    const NODE_PATH = '/usr/local/lib/node_modules'
    return Object.assign({}, process.env, {NODE_PATH})
  }

  async run () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: 'babel-node',
      args: ['--presets=stage-2', sourcePath],
      options: {cwd: dirname(sourcePath), env: this.getEnv()}
    })
  }

  async compile () {
    const sourcePath = await this.transformer.saveSource()
    this.transformer.write({
      command: 'babel',
      args: ['--presets=stage-2', sourcePath],
      options: {cwd: dirname(sourcePath), env: this.getEnv()},
      extension: 'es6.js'
    })
  }
}
