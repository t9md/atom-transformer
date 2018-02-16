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

module.exports = {
  getAdjacentPane,
  promisedRunCommand
}
