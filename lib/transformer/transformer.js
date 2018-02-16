'use babel'

const fs = require('fs-plus')
const Path = require('path')
const temp = require('temp')
const os = require('os')
const {getAdjacentPane, promisedRunCommand} = require('../utils')
const {dirname} = require('path')

function activateOutputPane () {
  const activePane = atom.workspace.getActivePane()

  const pane = getAdjacentPane(activePane)
  if (pane) {
    pane.activate()
    return pane
  }

  switch (atom.config.get('transformer.split')) {
    case 'right':
      return activePane.splitRight()
    case 'down':
      return activePane.splitDown()
  }
}

async function openOutputEditor (extension) {
  let filePath
  const basePath = Path.join(os.tmpdir(), 'transformer')
  if (extension) {
    filePath = `${basePath}.${extension}`
  } else {
    filePath = basePath
  }

  const originalPane = atom.workspace.getActivePane()
  const pane = activateOutputPane()
  const options = {searchAllPanes: true, activatePane: false, pane}
  const editor = await atom.workspace.open(filePath, options)
  editor.setText('')
  editor.isModified = () => false
  if (atom.workspace.getActivePane() !== originalPane) {
    originalPane.activate()
  }
  return editor
}

function writeToTempfile (text, extname = '') {
  temp.track()
  const fileName = 'tempfile' + extname
  const filePath = Path.join(temp.mkdirSync('transformer'), fileName)
  fs.writeFileSync(filePath, text)
  return filePath
}

module.exports = class Transformer {
  constructor (editor) {
    this.editor = editor
  }

  // return filePath of saved sourcefile
  async saveSource () {
    const editor = this.editor

    let sourcePath
    if (editor.getLastSelection().isEmpty()) {
      if (editor.isModified()) {
        await editor.save()
      }
      sourcePath = editor.getPath()
    } else {
      let extname
      if (editor.getPath()) {
        extname = Path.extname(editor.getPath())
      }
      this.tempFile = writeToTempfile(editor.getSelectedText(), extname)
      sourcePath = this.tempFile
    }
    return sourcePath
  }

  openOutputEditor (extension) {
    return openOutputEditor(extension)
  }

  async write (options) {
    options = Object.assign({}, options) // copy to not mutate original option
    const outputEditor = await this.openOutputEditor(options.extension)

    if (options.extension) {
      delete options.extension
    }

    const write = data => outputEditor.insertText(data)
    await promisedRunCommand({
      command: options.command,
      args: options.args,
      options: options.options,
      stdout: write,
      stderr: write
    })

    if (this.tempFile) {
      temp.cleanupSync()
    }
  }

  // Meta, just non-important sugar method
  async execute (commandLine, {extension, env}) {
    const sourcePath = await this.saveSource()
    commandLine = commandLine.replace(/__SOURCE__/g, sourcePath).split(/\s+/g)
    const [command, ...args] = commandLine
    const options = {cwd: dirname(sourcePath)}
    if (env) {
      options.env = env
    }
    this.write({command, args, options, extension})
  }
}
