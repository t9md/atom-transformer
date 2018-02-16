const Transformer = require('./transformer')

module.exports = class OCaml {
  constructor (editor) {
    this.transformer = new Transformer(editor)
  }

  async run () {
    throw new Error('FIXME! see ./transformer/ocaml.js')
  }
  async compile () {
    throw new Error('FIXME! see ./transformer/ocaml.js')
  }

  originalCompile () {
    // [FIXME]
    // this.extension = 'js'
    //
    // let dirName = Path.dirname(this.sourcePath)
    // const outputFile = Path.join(dirName, getBaseName(this.sourcePath) + '.js')
    //
    // const compile = () => {
    //   let stderr
    //   const command = 'bsc'
    //   const args = ['-I', '.', '-c', this.sourcePath]
    //   const options = {cwd: this.cwd}
    //   const stdout = (stderr = function () {})
    //   return this.runCommand({command, args, options, stdout, stderr})
    // }
    //
    // const openResultEditor = this.openResultEditor.bind(this)
    //
    // const writeToBuffer = editor => {
    //   let stderr
    //   const command = 'cat'
    //   const args = [outputFile]
    //   const options = {cwd: this.cwd}
    //   const stdout = (stderr = data => editor.insertText(data))
    //   return this.runCommand({command, args, options, stdout, stderr})
    // }
    //
    // const cleanup = () => {
    //   this.cleanupTemp()
    //   const baseName = getBaseName(this.sourcePath)
    //   dirName = Path.dirname(this.sourcePath)
    //   fs.removeSync(Path.join(dirName, `${baseName}.cmi`))
    //   return fs.removeSync(Path.join(dirName, `${baseName}.cmj`))
    // }
    //
    // return compile()
    //   .then(openResultEditor)
    //   .then(writeToBuffer)
    //   .then(cleanup)
  }
}
