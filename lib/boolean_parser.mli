module Ast = Ast
module Loc = Loc
module Error = Error
module Tokens = Tokens
module Lexer = Lexer

val parse : string -> (Ast.t, Error.t) result
