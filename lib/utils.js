const os = require('os')
const {BufferedProcess} = require('atom')

function getAdjacentPane (basePane) {
  const parent = basePane.getParent()
  if (parent && parent.getChildren) {
    const children = parent.getChildren()
    const index = children.indexOf(basePane)

    let pane
    pane = children[index + 1]
    if (pane && pane.constructor.name === 'Pane') {
      return pane
    }

    pane = children[index - 1]
    if (pane && pane.constructor.name === 'Pane') {
      return pane
    }
  }
}

function runCommand (options) {
  const bufferedProcess = new BufferedProcess(options)
  bufferedProcess.onWillThrowError(({error, handle}) => {
    if (error.code === 'ENOENT' && error.syscall.indexOf('spawn') === 0) {
      console.log('ERROR')
    }
    handle()
  })
  return bufferedProcess
}

function promisedRunCommand (options) {
  return new Promise(resolve => {
    if (options.exit) {
      const originalExit = options.exit
      options.exit = code => resolve(originalExit(code))
    } else {
      options.exit = resolve
    }
    runCommand(options)
  })
}

async function openResultEditor () {
  let filePath
  const basePath = Path.join(os.tmpdir(), 'transformer')
  if (this.extension) {
    filePath = `${basePath}.${this.extension}`
  } else {
    filePath = basePath
  }

  const originalPane = atom.workspace.getActivePane()
  const pane = this.activateOutputPane()
  const options = {searchAllPanes: true, activatePane: false, pane}
  const editor = await atom.workspace.open(filePath, options)
  editor.setText('')
  editor.isModified = () => false
  if (atom.workspace.getActivePane() !== originalPane) {
    originalPane.activate()
  }
  return editor
}

module.exports = {
  getAdjacentPane,
  promisedRunCommand
}
