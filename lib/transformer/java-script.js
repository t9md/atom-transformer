const Transformer = require('./transformer')

module.exports = class JavaScript {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  getEnv () {
    const NODE_PATH = '/usr/local/lib/node_modules'
    return Object.assign({}, process.env, {NODE_PATH})
  }

  async run () {
    this.transformer.run('babel-node --presets=stage-2 __SOURCE__ > __EDITOR__', this.getEnv())
  }

  async compile () {
    this.transformer.run('babel --presets=stage-2 __SOURCE__ > __EDITOR__.es6.js', this.getEnv())
  }
}
