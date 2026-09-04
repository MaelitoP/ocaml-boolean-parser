# Architecture

## Pipeline

```text
string -> Lexer -> tokens -> Parser -> Ast -> Printer | Eval
```

The lexer is built with ocamllex and the parser with menhir.

`Boolean_parser.parse` is the public entry point. It returns either an `Ast.t` or an `Error.t`.

The AST can then be:

* rendered back to canonical query syntax with `Printer`
* rendered as a tree with `Ast.pp_tree`
* evaluated with caller-provided predicates through `Eval`

## Modules

| Module           | Role                                                |
| ---------------- | --------------------------------------------------- |
| `Loc`            | Byte offsets in the source input.                   |
| `Error`          | Public parse error with message and location.       |
| `Tokens`         | Token definitions shared by lexer and parser.       |
| `Lexer`          | Converts source text into tokens.                   |
| `Parser`         | Builds the AST and defines operator precedence.     |
| `Ast`            | Query representation and field values.              |
| `Printer`        | Converts an AST back to canonical query syntax.     |
| `Eval`           | Evaluates the AST using caller-provided predicates. |
| `Boolean_parser` | Public API and error boundary.                      |

The CLI lives in `bin/` and only handles input/output, formatting options and exit codes.

## Grammar

Boolean precedence is:

```text
NOT
AND
OR
```

`AND` and `OR` are left-associative.

The printer follows the same precedence rules and only adds parentheses when required to preserve the AST.

The main printer invariant is:

```text
parse (Printer.to_string ast) = Ok ast
```

This is covered with property-based tests.

## Errors

No lexer or parser exception escapes the library.

`Boolean_parser.parse` converts lexer and menhir failures into:

```ocaml
type Error.t = {
  message : string;
  loc : Loc.t;
}
```

Locations are byte offsets with an inclusive start and exclusive stop.

The input is fully lexed before parsing. This is intentional so lexical errors take precedence over syntax errors later discovered by the parser.

The AST does not keep source locations.

