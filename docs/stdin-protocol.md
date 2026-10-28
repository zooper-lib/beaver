# The stdin protocol

The contract editors and other tools use to format a buffer. It is the only interface between Beaver and an editor.

```
beaver --stdin [--stdin-name <path>] [--range L1:C1-L2:C2]
```

## Whole document in, whole document out

Beaver reads the complete document from stdin and, on success, writes the complete result to stdout in one piece, exit 0. It never writes partial output: on any error stdout is empty and a diagnostic goes to stderr.

| Outcome | Stdout | Exit |
|---|---|---|
| Formatted | the whole document | 0 |
| `--stdin-name` matches an exclusion pattern | the input, unchanged and unparsed | 0 |
| Malformed or out-of-bounds `--range` | empty | 64 |
| Syntax error (anywhere in the document) or invalid ignore directives | empty | 65 |
| Verification failed | empty | 70 |
| Invalid configuration | empty | 78 |

## `--stdin-name`

The path the buffer belongs to. It is used for configuration discovery (as if formatting that file), exclusion matching and diagnostics. Beaver never reads the file at that path, so unsaved edits are formatted as they are in the buffer. Without it, configuration is discovered from the working directory.

## `--range`

`--range L1:C1-L2:C2` limits what may change. Lines and columns are 1-based, columns count UTF-16 code units (what editors report), the start is inclusive and the end exclusive. Line endings may be `\n` or `\r\n`; positions refer to the characters an editor shows. A reversed range, a position past the end of a line or the document, or a position between the two halves of a surrogate pair is a usage error (exit 64). `--range` requires `--stdin`.

The selection is expanded to the smallest run of complete units that covers it, trying in turn statements, class members and top-level declarations. A selection inside one argument formats the enclosing statement; one spanning two methods formats both. An empty selection (start equals end) formats the unit at that position, or returns the document unchanged if the position is in whitespace between units. Beaver never refuses a range.

Everything outside the expanded units is byte-identical to the input, including formatting that does not follow the configuration. The whole document is still parsed and the whole output verified; ignored regions (see [directives](directives.md)) stay unchanged inside a range.

Examples, each also a test in `packages/zooper_beaver/test/`:

- `--range 2:1-2:2` on `var  a=1;` / `var  b=2;` (two lines) formats only the second statement: `var  a=1;` / `var b = 2;` (`cli_test.dart`).
- `--range 2:1-1:1` is reversed: exit 64, empty stdout (`cli_test.dart`).
- `--range 3:5-5:11` selects from line 3 column 5 up to, not including, line 5 column 11 (`range_test.dart`).

## Protocol version

`beaver --version` prints `beaver <formatter version> (protocol <n>)`. The protocol version covers this contract: the flags above, the coordinate rules, the output and exit-code rules. It increases only for a breaking change to the contract, never because formatting output changed. The current protocol version is 1. Editor plugins declare the protocol version they speak and refuse a binary that reports another (see [versioning](versioning.md)).
