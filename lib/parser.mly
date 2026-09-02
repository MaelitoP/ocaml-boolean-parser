%start <Ast.t> query
%type <Ast.value> value

%left OR
%left AND
%nonassoc NOT

%%

query:
  | e = expr EOF { e }

expr:
  | l = expr OR r = expr { Ast.Or (l, r) }
  | l = expr AND r = expr { Ast.And (l, r) }
  | NOT e = expr { Ast.Not e }
  | a = atom { a }

atom:
  | w = WORD { Ast.Word w }
  | s = QUOTED_STRING { Ast.Phrase s }
  | name = WORD COLON v = value { Ast.Field (name, v) }
  | LPAREN e = expr RPAREN { e }

value:
  | w = WORD { Ast.Word w }
  | s = QUOTED_STRING { Ast.Phrase s }
  | n = NUMBER { Ast.Number n }
  | LT n = NUMBER { Ast.Lt n }
  | GT n = NUMBER { Ast.Gt n }
  | LTE n = NUMBER { Ast.Lte n }
  | GTE n = NUMBER { Ast.Gte n }
  | lo = NUMBER DOTDOT hi = NUMBER { Ast.Between (lo, hi) }
