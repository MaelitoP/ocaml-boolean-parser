module Ast = Ast
module Loc = Loc
module Error = Error
module Tokens = Tokens
module Lexer = Lexer
module Printer = Printer

let lex source =
  let lexbuf = Lexing.from_string source in
  let rec go acc =
    let token = Lexer.token lexbuf in
    let loc =
      {
        Loc.start = Lexing.lexeme_start lexbuf;
        stop = Lexing.lexeme_end lexbuf;
      }
    in
    let acc = (token, loc) :: acc in
    if token = Tokens.EOF then List.rev acc else go acc
  in
  go []

let parse source =
  match lex source with
    | exception Lexer.Error error -> Error error
    | [(Tokens.EOF, loc)] -> Error { Error.message = "empty query"; loc }
    | tokens -> (
        let stream = ref tokens in
        let current = ref (List.hd tokens) in
        let next _ =
          match !stream with
            | [] -> Tokens.EOF
            | token :: rest ->
                current := token;
                stream := rest;
                fst token
        in
        match Parser.query next (Lexing.from_string "") with
          | ast -> Ok ast
          | exception Parser.Error ->
              Error { Error.message = "syntax error"; loc = snd !current })
