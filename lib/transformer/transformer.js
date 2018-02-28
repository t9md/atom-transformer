'use babel'

const {TextEditor} = require('atom')
const fs = require('fs-plus')
const Path = require('path')
const temp = require('temp')
const os = require('os')
const {getAdjacentPane, promisedRunCommand} = require('../utils')
const {dirname} = require('path')
const Outlet = require('atom-outlet')
let outletManager

async function buildEditor (filePath) {
  const buffer = await atom.project.buildBuffer(filePath)
  const editor = new TextEditor({buffer, autoHeight: false})

  editor.setText('')
  editor.getAllowedLocations = () => ['center', 'bottom']
  editor.isModified = () => false
  editor.element.classList.add('transformer-outlet')
  atom.commands.add(editor.element, {
    'core:close': () => editor.destroy()
  })
  return editor
}

class OutletManager {
  constructor () {
    this.outletByFilePath = {}
  }

  async open (extension) {
    let outlet
    let filePath = Path.join(os.tmpdir(), 'transformer')
    if (extension) {
      filePath += `.${extension}`
    }

    outlet = this.outletByFilePath[filePath]
    console.log(outlet)
    if (outlet) {
      outlet.activate()
      return outlet.item
    }

    const editor = await buildEditor(filePath)

    outlet = new Outlet(editor)
    await outlet.open({
      where: atom.config.get('transformer.openLocation')
    })
    this.outletByFilePath[filePath] = outlet
    editor.onDidDestroy(() => {
      delete this.outletByFilePath[filePath]
    })
    return editor
  }
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
    if (!outletManager) {
      outletManager = new OutletManager()
    }
    return outletManager.open(extension)
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
