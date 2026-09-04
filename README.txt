ocaml-boolean-parser is a small parser for boolean search queries.

It supports words, quoted phrases, field filters, numeric comparisons and ranges,
and the boolean operators AND, OR and NOT. The lexer is generated with ocamllex
and the grammar with menhir. The project exposes both an OCaml library and a
command-line tool.

The language is specified in specs/grammar.md. Its examples are also used as
test fixtures.

Boolean operators follow the usual precedence:

```
NOT
AND
OR
```

For example:

```
NOT a OR b AND c
```

is parsed as:

```
(NOT a) OR (b AND c)
```

AND, OR and NOT also have symbolic forms:

```
AND     &&  &
OR      ||  |
NOT     !   -
```

Keywords are case-sensitive, so and is an ordinary word.

Field queries use a colon:

```
title:foo
title:"foo bar"
price:5
price:<5
price:>=5
price:1..5
```

Ranges are inclusive on both ends.

Everything after # until the end of the line is a comment.

There is no implicit boolean operator. This is invalid:

```
a b
```

The parser is deliberately small. The lexer produces tokens, menhir builds an
AST, and callers can either print that AST or evaluate it with their own
predicates.

The library does not define what a word, phrase or field matches.

Parsing returns errors as values. Lexer and parser exceptions do not escape the
library API. Errors contain byte offsets and can be rendered with the source
line and a caret.

ARCHITECTURE.md describes the internal modules and the parser invariants.

Building

The development environment is provided by Nix. It contains OCaml, dune, menhir,
ocamlformat and the test dependencies, so no local opam switch is required.

With direnv:

```
direnv allow
```

Without direnv:

```
nix develop
```

Then:

```
dune build
dune test
```

Command-line usage

The CLI accepts one query as an argument and prints its AST:

```
dune exec ocaml-boolean-parser -- 'NOT a OR b AND c'

OR
├── NOT
│   └── a
└── AND
    ├── b
    └── c
```

Use --format query to print canonical query syntax instead:

```
dune exec ocaml-boolean-parser -- --format query \
    'a AND (b OR c) AND NOT title:"foo bar"'

a AND (b OR c) AND NOT title:"foo bar"
```

When no query argument is provided, input is read from stdin:

```
echo 'price:1..5 OR "new arrival"' | dune exec ocaml-boolean-parser

OR
├── price:1..5
└── "new arrival"
```

Parse errors are written to stderr and exit with status 1. Command-line usage
errors exit with status 2.

```
dune exec ocaml-boolean-parser -- 'a AND'

1:6: syntax error
a AND
     ^
```

Library usage

The dune library is boolean_parser and its wrapped module is Boolean_parser.

Boolean_parser.parse returns an AST or an error. Printer.to_string converts an
AST back to canonical query syntax. Eval.eval evaluates it using predicates
provided by the caller.

```
open Boolean_parser

let words = ["ocaml"; "parser"]
let title = "ocaml boolean parser"
let price = 7.5
let source = "parser AND price:<10 AND NOT draft"

let () =
  match parse source with
  | Error e ->
      prerr_endline (Error.to_string ~source e)
  | Ok ast ->
      print_endline (Printer.to_string ast);

      let matches =
        Eval.eval
          ~word:(fun word -> List.mem word words)
          ~phrase:(fun phrase -> String.equal phrase title)
          ~field:(fun name value ->
            match name, value with
            | "price", Ast.Lt limit -> price < limit
            | _ -> false)
          ast
      in

      Printf.printf "matches: %b\n" matches
```

The printer is tested against the parser with the property:

```
parse (Printer.to_string ast) = Ok ast
```

Generated ASTs are checked with QCheck in addition to the example-based lexer,
parser, evaluator and CLI tests.

Licensed under the MIT License.

