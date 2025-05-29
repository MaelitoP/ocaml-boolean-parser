# Boolean Query Grammar Specification

This document details the formal grammar specification for a boolean query parser.

## BNF Grammar Specification
```ebnf
Query            ::= Expression EOF

Expression       ::= OrExpression

OrExpression     ::= AndExpression (OR AndExpression)*

AndExpression    ::= NotExpression (AND NotExpression)*

NotExpression    ::= NOT? AtomicExpression

AtomicExpression ::= Term
                   | FieldQuery  
                   | LPAREN Expression RPAREN

Term             ::= STRING
                   | QUOTED_STRING

FieldQuery       ::= IDENTIFIER COLON FieldValue

FieldValue       ::= STRING
                   | QUOTED_STRING
                   | NUMBER
                   | RangeValue

RangeValue       ::= LT NUMBER
                   | GT NUMBER  
                   | GTE NUMBER
                   | LTE NUMBER
                   | NUMBER DOTDOT NUMBER
```

## Lexical Elements
### Keywords & Operators
```ebnf
AND ::= 'AND' | '&&' | '&'
OR  ::= 'OR' | '||' | '|'
NOT ::= 'NOT' | '!' | '-'
```

### Punctuation
```ebnf
LPAREN    ::= '('
RPAREN    ::= ')'
COLON     ::= ':'
DOTDOT    ::= '..'
LT        ::= '<'
GT        ::= '>'
LTE       ::= '<='
GTE       ::= '>='
```

### Literals
```ebnf
STRING         ::= [a-zA-Z_][a-zA-Z0-9_]*
QUOTED_STRING  ::= '"' ([^"\\] | '\\' .)* '"'
                 | "'" ([^'\\] | '\\' .)* "'"
IDENTIFIER     ::= [a-zA-Z_][a-zA-Z0-9_]*
NUMBER         ::= [0-9]+ ('.' [0-9]+)?
```

### Whitespace and Comments
```ebnf
WHITESPACE    ::= [ \t\n\r]+
COMMENT       ::= '#' [^\n]* '\n'
```

## Operator Precedence Table

| Precedence | Operator | Associativity | Description |
|------------|----------|---------------|-------------|
| 1 (highest) | `NOT`, `!`, `-` | Right | Logical negation |
| 2 | `AND`, `&&`, `&` | Left | Logical conjunction |
| 3 (lowest) | `OR`, `\|\|`, `\|` | Left | Logical disjunction |

### Precedence Examples

```console
# Expression: NOT a OR b AND c
# Parsed as: (NOT a) OR (b AND c)
# Tree structure:
OR
├── NOT
│   └── a
└── AND
    ├── b
    └── c

# Expression: a AND b OR c AND d  
# Parsed as: (a AND b) OR (c AND d)
# Tree structure:
OR
├── AND
│   ├── a
│   └── b
└── AND
    ├── c
    └── d
```

## 4. Grammar Rules Explained

### Expression Hierarchy

The grammar uses a **stratified approach** to handle operator precedence correctly:

1. **OrExpression**: Handles lowest precedence OR operations
2. **AndExpression**: Handles medium precedence AND operations  
3. **NotExpression**: Handles highest precedence NOT operations
4. **AtomicExpression**: Base terms that cannot be further decomposed

### Recursive Structure

```ebnf
# This pattern handles left-associative operators:
AndExpression ::= NotExpression (AND NotExpression)*

# Equivalent to the left-recursive (but problematic):
# AndExpression ::= AndExpression AND NotExpression | NotExpression
```

### Parentheses Handling

```ebnf
AtomicExpression ::= LPAREN Expression RPAREN

# This allows arbitrary nesting:
# ((a OR b) AND (c OR d))
# (NOT (a AND b))
```
