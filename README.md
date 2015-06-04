# transformer

Transform anything!

![gif](https://raw.githubusercontent.com/t9md/t9md/8adfa669f584361bf4c5c85b3b3431be002dd336/img/atom-transformer.gif)

# Development status

Alpha  

# How to use

Currently you can use.

* `transformer:run` to run scripts
* `transformer:compile` to compile.

Unlike [preview](https://atom.io/packages/preview) or [script](https://atom.io/packages/script), this package write output to  normal TexiEditor.  
So you can use default TextEditor feature without special supports.  
* e.g. search, copy&paste highlight LESS output with [pigments](https://atom.io/packages/pigments).

## Supports

## Run
* CoffeeScript
* LESS
* Python
* Go
* JavaScript

## Compile
* CoffeeScript`
* `LESS`

# Concepts

Followings are all could be abstracted as string `transformation` to another string.

* `run` and get output of `stdio`
* `compile`
* `transcompile`
* `rendering`
* `upcase`, `lowercase`, `urlencode`, `lot13` etc.

And transformation is achieved by following steps.

1. input
2. transformation
3. get output
4. (optional) post output

So what this package is aiming at is provide basic framework to easily transform string to another form.

# TODO
