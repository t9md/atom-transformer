'use babel'

const fs = require('fs-plus')
const Path = require('path')
const temp = require('temp')
const os = require('os')
const {getAdjacentPane, promisedRunCommand} = require('../utils')
const {dirname} = require('path')
const createOutlet = require('atom-outlet').create
let outletManager

const outletByFilePath = {}

async function openOutlet (filePath) {
  let editor = outletByFilePath[filePath]
  if (editor) {
    editor.show()
  } else {
    editor = createOutlet({
      editorOptions: {
        buffer: await atom.project.buildBuffer(filePath)
      },
      classList: ['transformer-outlet'],
      defaultLocation: atom.config.get('transformer.openLocation'),
      split: atom.config.get('transformer.split'),
      extendsTextEditor: true
    })
    editor.onDidDestroy(() => {
      delete outletByFilePath[filePath]
    })
    await editor.open()
    outletByFilePath[filePath] = editor
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
    let filePath = Path.join(os.tmpdir(), 'transformer')
    if (extension) {
      filePath += `.${extension}`
    }
    return openOutlet(filePath)
  }

  async write (options) {
    options = Object.assign({}, options) // copy to not mutate original option
    const outputEditor = await this.openOutputEditor(options.extension)
    outputEditor.setText('')

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

  // [Meta]: just non-important sugar method
  async execute (commandLine, {extension, env} = {}) {
    const sourcePath = await this.saveSource()
    commandLine = commandLine.replace(/__SOURCE__/g, sourcePath).split(/\s+/g)
    const [command, ...args] = commandLine
    const options = {cwd: dirname(sourcePath)}
    if (env) {
      options.env = env
    }
    this.write({command, args, options, extension})
  }

  // [Meta]: just non-important sugar method
  async run (commandLine, env) {
    const parsed = this.parseCommandLine(commandLine)
    this.execute(parsed.commandLine, {extension: parsed.extension, env})
  }

  parseCommandLine (commandLine) {
    const regex = /^(.*)(\s*>\s*__EDITOR__)(?:\.(.*))?$/
    const match = commandLine.match(regex)
    return {
      originalCommandLine: commandLine,
      commandLine: match[1].trim(),
      output: match[2],
      extension: match[3],
      match: match
    }
  }
}
