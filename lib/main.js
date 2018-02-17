const invoke = require('./invoke')

const Config = {
  split: {
    order: 0,
    type: 'string',
    default: 'right',
    enum: ['right', 'down'],
    description: 'Where output buffer to open'
  }
}

module.exports = {
  config: Config,

  activate () {
    this.disposable = atom.commands.add('atom-text-editor', {
      'transformer:run' () {
        invoke(this.getModel(), 'run')
      },
      'transformer:compile' () {
        invoke(this.getModel(), 'compile')
      }
    })
  },

  deactivate () {
    this.disposable.dispose()
  }
}
