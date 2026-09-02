{
open Tokens

exception Error of Error.t

let fail message start stop = raise (Error { Error.message; loc = { Loc.start; stop } })
}

let digit = ['0'-'9']
let word = ['a'-'z' 'A'-'Z' '_'] ['a'-'z' 'A'-'Z' '0'-'9' '_']*
let number = digit+ ('.' digit+)?

rule token = parse
  | [' ' '\t' '\n' '\r']+ { token lexbuf }
  | '#' [^ '\n']* { token lexbuf }
  | "AND" | "&&" | "&" { AND }
  | "OR" | "||" | "|" { OR }
  | "NOT" | "!" | "-" { NOT }
  | "(" { LPAREN }
  | ")" { RPAREN }
  | ":" { COLON }
  | ".." { DOTDOT }
  | "<=" { LTE }
  | ">=" { GTE }
  | "<" { LT }
  | ">" { GT }
  | number as n { NUMBER (float_of_string n) }
  | word as w { WORD w }
  | ('"' | '\'') as quote
    { quoted quote (Lexing.lexeme_start lexbuf) (Buffer.create 16) lexbuf }
  | eof { EOF }
  | _ as c
    { fail (Printf.sprintf "unexpected character '%c'" c)
        (Lexing.lexeme_start lexbuf) (Lexing.lexeme_end lexbuf) }

and quoted quote start buf = parse
  | '\\' (['"' '\'' '\\'] as c) { Buffer.add_char buf c; quoted quote start buf lexbuf }
  | '\\' _ { Buffer.add_string buf (Lexing.lexeme lexbuf); quoted quote start buf lexbuf }
  | ('"' | '\'') as c
    { if c = quote then QUOTED_STRING (Buffer.contents buf)
      else (Buffer.add_char buf c; quoted quote start buf lexbuf) }
  | eof { fail "unterminated quoted string" start (Lexing.lexeme_end lexbuf) }
  | _ as c { Buffer.add_char buf c; quoted quote start buf lexbuf }
