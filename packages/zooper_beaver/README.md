# zooper_beaver

A configurable, line-width-aware formatter for Dart. Every formatting decision is a documented rule in a project-local `.beaver.yaml`.

The package is `zooper_beaver`; the executable it installs is `beaver`.

## Install

```sh
dart install zooper_beaver@<version>
```

`dart pub global activate zooper_beaver` also works.

## Use

```sh
beaver .                 # format in place
beaver --check lib       # list unformatted files, exit 1 if any
beaver --stdin --stdin-name lib/a.dart < lib/a.dart
```

Every configuration key and value, with the output it produces: [`example/`](https://github.com/zooper-lib/beaver/tree/main/example).

## License

MIT, see `LICENSE`.
