const Controller = require('./controller')

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
  activate () {
    this.disposable = atom.commands.add('atom-text-editor', {
      'transformer:run' () {
        Controller.invoke(this.getModel(), 'run')
      },
      'transformer:compile' () {
        Controller.invoke(this.getModel(), 'compile')
      }
    })
  },

  deactivate () {
    this.disposable.dispose()
  }
}
