# screencapload-crystal

Screencapload is a macOS command line tool that allows you to take a screenshot,
reduce its file weight while mian

## Installation

Right now, you have to build the app to use it. You also can benefit from
GraphicsMagick to automatically trim the image, optipng to reduce the screenshot's
weight, and pngquant to reduce the image to 256 colors so it is much faster to
download, display, etc.

To compile, run :

```shell
brew install crystal-lang 
crystal build --release src/screencapload.cr
```

To install optionnal depencies run :

```shell
brew install graphicsmagick optipng pngquant
```

## Usage

You need an imgur API key, either stored in ~/.imgur or passed as a command
line argument like so :

```shell
screencapload 123456789
```

## Development

This is a basic conversion of the original screencapload Ruby script into Crystal.

It is not meant to better or faster, because running the ruby version already take
about a few dozen milliseconds and this version won't offer anything more.

If you want to play wisth the code and run the app quickly, use :

```shell
brew install crystal-lang 
crystal run src/screencapload.cr
```

## Contributing

1. Fork it ( https://github.com/czj/screencapload-crystal/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [czj](https://github.com/czj) Clément Joubert - creator, maintainer
