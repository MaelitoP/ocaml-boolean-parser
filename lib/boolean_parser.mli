module Ast = Ast
module Loc = Loc
module Error = Error
module Tokens = Tokens
module Lexer = Lexer
module Printer = Printer

val parse : string -> (Ast.t, Error.t) result
