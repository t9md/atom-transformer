const Transformer = require('./transformer')
const {dirname} = require('path')
const less = require('less')
const Path = require('path')

module.exports = class Less {
  constructor (editor) {
    this.editor = editor
    this.transformer = new Transformer(editor)
  }

  async run () {
    const text = this.editor.getSelectedText() || this.editor.getText()

    const atomVariablesPath = Path.resolve(atom.themes.resourcePath, 'static', 'variables')
    const renderOptions = {paths: ['.', atomVariablesPath], filename: this.editor.getPath()}

    const outputEditor = await this.transformer.openOutputEditor('css')
    less.render(text, renderOptions, (error, output) => {
      outputEditor.insertText(error ? error.message : output.css)
    })
  }

  async compile () {
    this.run()
  }
}
