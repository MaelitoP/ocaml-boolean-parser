# Architecture

## Pipeline

```
string -> Lexer (ocamllex) -> tokens -> Parser (menhir) -> Ast -> Printer | Eval
```

The lexer turns the input into tokens, the parser builds an `Ast.t`, and the AST is consumed either by the printer (back to canonical query syntax or a box-drawing tree) or by the evaluator (against caller-supplied predicates). Lexing and parsing failures are converted once, in the library entry point, into an `Error.t` value carrying a message and byte offsets.

## Module map

Library `boolean_parser` in `lib/`, wrapped as `Boolean_parser`. Filled in as modules land.

| Module | Status | Role |
|--------|--------|------|
| `Ast` | done (T04) | `value` (field values: word, phrase, number, `<`, `>`, `<=`, `>=`, `N..M`) and `t` (word, phrase, field, `Not`, `And`, `Or`). No source locations, numbers as `float`. Derives `equal`, `pp`, `show` via ppx_deriving; `pp_tree` renders the box-drawing tree from the spec. |

Executable in `bin/`:

| Module | Status | Role |
|--------|--------|------|
| `Main` | placeholder | Prints `Hello, World!`. |

Tests in `test/`:

| File | Status | Role |
|------|--------|------|
| `test_ast.ml` | done (T04) | alcotest suite: `Ast.equal` and `pp_tree` on the spec leaf table and the three spec trees. The alcotest `testable` for `Ast.t` lives here, not in the library. |

## Build

- `dune-project`: `(lang dune 3.19)`, `(using menhir 3.0)`, `(cram enable)`, generates `ocaml-boolean-parser.opam`.
- Dependencies: `ocaml >= 5.1`, `menhir`, `ppx_deriving`, `alcotest` and `qcheck-alcotest` for tests.
- `lib/dune` preprocesses with `ppx_deriving.eq` and `ppx_deriving.show`; `test/dune` uses a `(tests (names ...))` stanza, one executable per module under test.
- `flake.nix` provides the compiler, dune, ocamlformat and every library above.
