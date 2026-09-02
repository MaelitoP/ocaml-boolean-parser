# Boolean Query Grammar Specification

This document is the formal specification of the boolean query language accepted by the parser. Every rule has exactly one reading; the examples table at the end is the fixture source for the lexer and parser tests.

## Grammar

```ebnf
Query            ::= Expression EOF

Expression       ::= OrExpression

OrExpression     ::= AndExpression (OR AndExpression)*

AndExpression    ::= NotExpression (AND NotExpression)*

NotExpression    ::= NOT NotExpression
                   | AtomicExpression

AtomicExpression ::= Term
                   | FieldQuery
                   | LPAREN Expression RPAREN

Term             ::= WORD
                   | QUOTED_STRING

FieldQuery       ::= WORD COLON FieldValue

FieldValue       ::= WORD
                   | QUOTED_STRING
                   | NUMBER
                   | RangeValue

RangeValue       ::= LT NUMBER
                   | GT NUMBER
                   | LTE NUMBER
                   | GTE NUMBER
                   | NUMBER DOTDOT NUMBER
```

Notes:

- A `WORD` followed by `COLON` is always the start of a `FieldQuery`; otherwise it is a `Term`. This is the only place where the parser needs two tokens of lookahead.
- `NUMBER` is not a `Term`. A bare number such as `2024` must be quoted (`"2024"`) to be searched as text.
- There is no implicit operator between adjacent atoms: `a b` is a syntax error.
- `N..M` is inclusive on both ends. The grammar does not require `N <= M`.

## Lexical Elements

The lexer turns the input into a token list, skipping whitespace and comments. Whitespace between any two tokens is insignificant, so `title : foo` and `title:foo` are the same query.

### Keywords and Operators

```ebnf
AND ::= 'AND' | '&&' | '&'
OR  ::= 'OR'  | '||' | '|'
NOT ::= 'NOT' | '!'  | '-'
```

Keywords are case-sensitive. `and`, `Or`, `not` are ordinary `WORD`s.

`-` is always `NOT`. It is never part of a word or a number, so `foo-bar` lexes as `WORD(foo) NOT WORD(bar)` and is a syntax error, and `-5` lexes as `NOT NUMBER(5)`.

### Punctuation

```ebnf
LPAREN ::= '('
RPAREN ::= ')'
COLON  ::= ':'
DOTDOT ::= '..'
LT     ::= '<'
GT     ::= '>'
LTE    ::= '<='
GTE    ::= '>='
```

A single `.` is not a token. Longest match applies: `<=` wins over `<`, `>=` over `>`, `&&` over `&`, `||` over `|`.

### Literals

```ebnf
WORD          ::= [a-zA-Z_][a-zA-Z0-9_]*
NUMBER        ::= [0-9]+ ('.' [0-9]+)?
QUOTED_STRING ::= '"' ( [^"\\] | ESCAPE )* '"'
                | "'" ( [^'\\] | ESCAPE )* "'"
ESCAPE        ::= '\\' .
```

`NUMBER` is unsigned. After the integer digits, a `.` immediately followed by a digit starts the fractional part; any other `.` is not part of the number. Hence `1..5` lexes as `NUMBER(1) DOTDOT NUMBER(5)` and `1.` lexes as `NUMBER(1)` followed by an unexpected character.

Inside a `QUOTED_STRING`, the escapes `\"`, `\'` and `\\` denote `"`, `'` and `\`. Any other backslash sequence is kept verbatim, both characters included: `"a\nb"` is the four-character text `a\nb`. Both quote kinds recognise all three escapes. A quoted string may contain newlines. A quoted string that reaches the end of input without its closing quote is a lexical error.

Any byte that cannot start a token (for example `@`, `.`, a lone `\`, or a non-ASCII byte outside a quoted string) is a lexical error.

### Whitespace and Comments

```ebnf
WHITESPACE ::= [ \t\n\r]+
COMMENT    ::= '#' [^\n]* ('\n' | EOF)
```

A comment starts at `#` wherever it appears outside a quoted string, including right after a word (`foo#bar` is the word `foo`), and runs to the end of the line or to the end of input.

## Operator Precedence

| Precedence  | Operator           | Associativity | Description         |
|-------------|--------------------|---------------|---------------------|
| 1 (highest) | `NOT`, `!`, `-`    | Right (prefix, chains: `NOT NOT a`) | Logical negation |
| 2           | `AND`, `&&`, `&`   | Left          | Logical conjunction |
| 3 (lowest)  | `OR`, `\|\|`, `\|` | Left          | Logical disjunction |

Left associativity means `a OR b OR c` parses as `(a OR b) OR c`.

### Precedence Examples

```console
# Expression: NOT a OR b AND c
# Parsed as: (NOT a) OR (b AND c)
OR
├── NOT
│   └── a
└── AND
    ├── b
    └── c

# Expression: a AND b OR c AND d
# Parsed as: (a AND b) OR (c AND d)
OR
├── AND
│   ├── a
│   └── b
└── AND
    ├── c
    └── d
```

## Tree Rendering

The tree printer uses the box-drawing layout above. Internal nodes are `OR`, `AND`, `NOT`. Leaves are rendered on one line:

| Leaf                       | Rendering            |
|----------------------------|----------------------|
| word `foo`                 | `foo`                |
| phrase `hello "w"`         | `"hello \"w\""` (always `"`-quoted, `"` and `\` escaped) |
| field with word value      | `title:foo`          |
| field with phrase value    | `title:"foo bar"`    |
| field with number          | `price:5`, `price:5.5` |
| field with range           | `price:<5`, `price:>5`, `price:<=5`, `price:>=5`, `price:1..5` |

Numbers are printed in the shortest form that round-trips (`5`, not `5.`).

```console
# Expression: NOT title:"foo bar" AND price:1..5
AND
├── NOT
│   └── title:"foo bar"
└── price:1..5
```

## Errors

Every error carries a message and a location. A location is a pair of byte offsets into the source, start inclusive and stop exclusive. An error at end of input has `start = stop = length of the input`.

Lexical errors:

| Message                        | Location                                   |
|--------------------------------|--------------------------------------------|
| `unexpected character '<c>'`   | the offending byte                         |
| `unterminated quoted string`   | from the opening quote to the end of input |

Syntax errors have the form `unexpected <token>, expected <what>`, where `<token>` is one of:

`AND`, `OR`, `NOT`, `'('`, `')'`, `':'`, `'..'`, `'<'`, `'>'`, `'<='`, `'>='`, `word '<text>'`, `quoted string`, `number <n>`, `end of input`

and `<what>` is one of:

| Expected                          | Emitted when the parser needs                     |
|-----------------------------------|---------------------------------------------------|
| `a term`                          | the start of an `AtomicExpression` or a `NOT`     |
| `an operator or end of input`     | `AND`, `OR`, `)` or `EOF` after a complete atom   |
| `')'`                             | the closing parenthesis of a group                |
| `a field value`                   | a `FieldValue` after `COLON`                      |
| `a number`                        | the `NUMBER` after `<`, `>`, `<=`, `>=` or `..`   |

The location of a syntax error is the location of the unexpected token. An input that contains no tokens at all (empty, whitespace or comments only) is reported as `empty query` at end of input.

## Examples

Trees are written with the AST constructors: `Word`, `Phrase`, `Field (name, value)`, `Not`, `And`, `Or`; field values are `Word`, `Phrase`, `Number`, `Lt`, `Gt`, `Lte`, `Gte`, `Between`.

### Valid inputs

| Input                       | Tree                                                     |
|-----------------------------|----------------------------------------------------------|
| `a`                         | `Word "a"`                                               |
| `_x1`                       | `Word "_x1"`                                             |
| `and`                       | `Word "and"`                                             |
| `"hello world"`             | `Phrase "hello world"`                                   |
| `'hello world'`             | `Phrase "hello world"`                                   |
| `"a\"b"`                    | `Phrase "a\"b"`                                          |
| `'it\'s'`                   | `Phrase "it's"`                                          |
| `"a\\b"`                    | `Phrase "a\\b"` (one backslash)                          |
| `"a\nb"`                    | `Phrase "a\\nb"` (backslash and `n` kept)                |
| `"line1`<br>`line2"`        | `Phrase "line1\nline2"`                                  |
| `a AND b`                   | `And (Word "a", Word "b")`                               |
| `a && b`                    | `And (Word "a", Word "b")`                               |
| `a & b`                     | `And (Word "a", Word "b")`                               |
| `a OR b`                    | `Or (Word "a", Word "b")`                                |
| `a \|\| b`                  | `Or (Word "a", Word "b")`                                |
| `a \| b`                    | `Or (Word "a", Word "b")`                                |
| `NOT a`                     | `Not (Word "a")`                                         |
| `!a`                        | `Not (Word "a")`                                         |
| `-a`                        | `Not (Word "a")`                                         |
| `NOT NOT a`                 | `Not (Not (Word "a"))`                                   |
| `!-a`                       | `Not (Not (Word "a"))`                                   |
| `a AND NOT b`               | `And (Word "a", Not (Word "b"))`                         |
| `a OR b OR c`               | `Or (Or (Word "a", Word "b"), Word "c")`                 |
| `a AND b AND c`             | `And (And (Word "a", Word "b"), Word "c")`               |
| `NOT a OR b AND c`          | `Or (Not (Word "a"), And (Word "b", Word "c"))`          |
| `a AND b OR c AND d`        | `Or (And (Word "a", Word "b"), And (Word "c", Word "d"))` |
| `a AND (b OR c)`            | `And (Word "a", Or (Word "b", Word "c"))`                |
| `NOT (a AND b)`             | `Not (And (Word "a", Word "b"))`                         |
| `((a))`                     | `Word "a"`                                               |
| `title:foo`                 | `Field ("title", Word "foo")`                            |
| `title : foo`               | `Field ("title", Word "foo")`                            |
| `title:"foo bar"`           | `Field ("title", Phrase "foo bar")`                      |
| `price:5`                   | `Field ("price", Number 5.)`                             |
| `price:5.5`                 | `Field ("price", Number 5.5)`                            |
| `price:<5`                  | `Field ("price", Lt 5.)`                                 |
| `price:>5`                  | `Field ("price", Gt 5.)`                                 |
| `price:<=5`                 | `Field ("price", Lte 5.)`                                |
| `price:>=5`                 | `Field ("price", Gte 5.)`                                |
| `price:1..5`                | `Field ("price", Between (1., 5.))`                      |
| `price:1.5..2.5`            | `Field ("price", Between (1.5, 2.5))`                    |
| `NOT title:foo`             | `Not (Field ("title", Word "foo"))`                      |
| `a AND b # trailing`        | `And (Word "a", Word "b")`                               |
| `a # comment`<br>`AND b`    | `And (Word "a", Word "b")`                               |
| `foo#bar`                   | `Word "foo"`                                             |

### Invalid inputs

Locations are `start..stop` byte offsets.

| Input         | Location | Message                                                    |
|---------------|----------|------------------------------------------------------------|
| ``            | `0..0`   | `empty query`                                              |
| `   `         | `3..3`   | `empty query`                                              |
| `# only`      | `6..6`   | `empty query`                                              |
| `a b`         | `2..3`   | `unexpected word 'b', expected an operator or end of input` |
| `foo-bar`     | `3..4`   | `unexpected NOT, expected an operator or end of input`     |
| `5`           | `0..1`   | `unexpected number 5, expected a term`                     |
| `a AND`       | `5..5`   | `unexpected end of input, expected a term`                 |
| `AND a`       | `0..3`   | `unexpected AND, expected a term`                          |
| `a OR OR b`   | `5..7`   | `unexpected OR, expected a term`                           |
| `NOT`         | `3..3`   | `unexpected end of input, expected a term`                 |
| `(a`          | `2..2`   | `unexpected end of input, expected ')'`                    |
| `a)`          | `1..2`   | `unexpected ')', expected an operator or end of input`     |
| `()`          | `1..2`   | `unexpected ')', expected a term`                          |
| `a:b:c`       | `3..4`   | `unexpected ':', expected an operator or end of input`     |
| `title:`      | `6..6`   | `unexpected end of input, expected a field value`          |
| `title:AND`   | `6..9`   | `unexpected AND, expected a field value`                   |
| `price:-5`    | `6..7`   | `unexpected NOT, expected a field value`                   |
| `price:<`     | `7..7`   | `unexpected end of input, expected a number`               |
| `price:<foo`  | `7..10`  | `unexpected word 'foo', expected a number`                 |
| `price:1..`   | `9..9`   | `unexpected end of input, expected a number`               |
| `"abc`        | `0..4`   | `unterminated quoted string`                               |
| `a @ b`       | `2..3`   | `unexpected character '@'`                                 |
| `1.`          | `1..2`   | `unexpected character '.'`                                 |
| `a . b`       | `2..3`   | `unexpected character '.'`                                 |
