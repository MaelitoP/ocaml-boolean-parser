Tree format is the default:

  $ ocaml-boolean-parser 'NOT a OR b AND c'
  OR
  ├── NOT
  │   └── a
  └── AND
      ├── b
      └── c

Query format prints canonical syntax with minimal parentheses:

  $ ocaml-boolean-parser --format query 'a AND (b OR c) AND NOT title:"foo bar"'
  a AND (b OR c) AND NOT title:"foo bar"

Without a positional argument the query is read from stdin:

  $ printf 'price:1..5 # comment\nOR x' | ocaml-boolean-parser
  OR
  ├── price:1..5
  └── x

A syntax error is rendered on stderr with a caret and exits 1:

  $ ocaml-boolean-parser 'a AND'
  1:6: syntax error
  a AND
       ^
  [1]

Usage errors exit 2:

  $ ocaml-boolean-parser --format json a
  ocaml-boolean-parser: wrong argument 'json'; option '--format' expects one of: tree query.
  Usage: ocaml-boolean-parser [--format tree|query] [QUERY]
  Reads the query from stdin when QUERY is omitted.
    --format {tree|query} output as a box-drawing tree (default) or as canonical query syntax
    -help  Display this list of options
    --help  Display this list of options
  [2]

  $ ocaml-boolean-parser a b
  ocaml-boolean-parser: expects at most one QUERY.
  Usage: ocaml-boolean-parser [--format tree|query] [QUERY]
  Reads the query from stdin when QUERY is omitted.
    --format {tree|query} output as a box-drawing tree (default) or as canonical query syntax
    -help  Display this list of options
    --help  Display this list of options
  [2]
