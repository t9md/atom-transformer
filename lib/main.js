const invoke = require('./invoke')

module.exports = {
  activate () {
    this.disposable = atom.commands.add('atom-text-editor', {
      'transformer:run' () {
        invoke(this.getModel(), 'run')
      },
      'transformer:compile' () {
        invoke(this.getModel(), 'compile')
      }
      // 'transformer:relocate-output' () {
      //   invoke(this.getModel(), 'compile')
      // }
    })
  },

  deactivate () {
    this.disposable.dispose()
  }
}
