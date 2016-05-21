# transformer

Transform something.

![gif](https://raw.githubusercontent.com/t9md/t9md/8adfa669f584361bf4c5c85b3b3431be002dd336/img/atom-transformer.gif)

# Development status

VERY Alpha.
Config parameter, command name might change without notification.  

# How to use

- `transformer:run`: run scripts
- `transformer:compile`: compile.

Unlike [preview](https://atom.io/packages/preview) or [script](https://atom.io/packages/script), this package write output to  normal TexEditor.  
So you can use default TextEditor feature without special supports.  
* e.g. search, copy&paste highlight LESS output with [pigments](https://atom.io/packages/pigments).

## Supported language

See [this file](https://github.com/t9md/atom-transformer/blob/master/lib/transformer.coffee).

# FAQ

## Command not found?

Configure `process.env.PATH` in you `init.coffee`.

e.g.

```coffeescript
process.env.PATH  = "/usr/local/bin:/usr/bin"
```
