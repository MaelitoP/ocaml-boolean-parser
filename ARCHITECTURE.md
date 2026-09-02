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
| (none yet) | | The library is declared in `lib/dune` and has no modules. |

Executable in `bin/`:

| Module | Status | Role |
|--------|--------|------|
| `Main` | placeholder | Prints `Hello, World!`. |

Tests in `test/`:

| File | Status | Role |
|------|--------|------|
| `test_ocaml_boolean_parser.ml` | placeholder | Empty test executable. |

## Build

- `dune-project`: `(lang dune 3.19)`, `(using menhir 3.0)`, `(cram enable)`, generates `ocaml-boolean-parser.opam`.
- Dependencies: `ocaml >= 5.1`, `menhir`, `ppx_deriving`, `alcotest` and `qcheck-alcotest` for tests.
- `flake.nix` provides the compiler, dune, ocamlformat and every library above.
