open Boolean_parser
open Tokens
open Testable

let show_token = function
  | AND -> "AND"
  | OR -> "OR"
  | NOT -> "NOT"
  | LPAREN -> "LPAREN"
  | RPAREN -> "RPAREN"
  | COLON -> "COLON"
  | DOTDOT -> "DOTDOT"
  | LT -> "LT"
  | GT -> "GT"
  | LTE -> "LTE"
  | GTE -> "GTE"
  | WORD w -> Printf.sprintf "WORD %S" w
  | QUOTED_STRING s -> Printf.sprintf "QUOTED_STRING %S" s
  | NUMBER n -> Printf.sprintf "NUMBER %g" n
  | EOF -> "EOF"

let token =
  Alcotest.testable
    (fun ppf t -> Format.pp_print_string ppf (show_token t))
    ( = )

let tokens = Alcotest.(result (list token) error)

let tokenize source =
  let lexbuf = Lexing.from_string source in
  let rec go acc =
    match Lexer.token lexbuf with EOF -> List.rev acc | t -> go (t :: acc)
  in
  try Ok (go []) with Lexer.Error e -> Error e

let check cases () =
  List.iter
    (fun (input, expected) ->
      Alcotest.check tokens input expected (tokenize input))
    cases

let words =
  [
    ("a", Ok [WORD "a"]);
    ("_x1", Ok [WORD "_x1"]);
    ("and", Ok [WORD "and"]);
    ("Or", Ok [WORD "Or"]);
    ("ANDx", Ok [WORD "ANDx"]);
  ]

let phrases =
  [
    ("\"hello world\"", Ok [QUOTED_STRING "hello world"]);
    ("'hello world'", Ok [QUOTED_STRING "hello world"]);
    ("\"a\\\"b\"", Ok [QUOTED_STRING "a\"b"]);
    ("'it\\'s'", Ok [QUOTED_STRING "it's"]);
    ("\"it's\"", Ok [QUOTED_STRING "it's"]);
    ("\"a\\\\b\"", Ok [QUOTED_STRING "a\\b"]);
    ("\"a\\nb\"", Ok [QUOTED_STRING "a\\nb"]);
    ("\"line1\nline2\"", Ok [QUOTED_STRING "line1\nline2"]);
    ("\"# not a comment\"", Ok [QUOTED_STRING "# not a comment"]);
  ]

let operators =
  [
    ("a AND b", Ok [WORD "a"; AND; WORD "b"]);
    ("a && b", Ok [WORD "a"; AND; WORD "b"]);
    ("a & b", Ok [WORD "a"; AND; WORD "b"]);
    ("a OR b", Ok [WORD "a"; OR; WORD "b"]);
    ("a || b", Ok [WORD "a"; OR; WORD "b"]);
    ("a | b", Ok [WORD "a"; OR; WORD "b"]);
    ("NOT a", Ok [NOT; WORD "a"]);
    ("!a", Ok [NOT; WORD "a"]);
    ("-a", Ok [NOT; WORD "a"]);
    ("!-a", Ok [NOT; NOT; WORD "a"]);
    ("foo-bar", Ok [WORD "foo"; NOT; WORD "bar"]);
    ("-5", Ok [NOT; NUMBER 5.]);
    ("((a))", Ok [LPAREN; LPAREN; WORD "a"; RPAREN; RPAREN]);
  ]

let fields =
  [
    ("title:foo", Ok [WORD "title"; COLON; WORD "foo"]);
    ("title : foo", Ok [WORD "title"; COLON; WORD "foo"]);
    ("title:\"foo bar\"", Ok [WORD "title"; COLON; QUOTED_STRING "foo bar"]);
    ("price:5", Ok [WORD "price"; COLON; NUMBER 5.]);
    ("price:5.5", Ok [WORD "price"; COLON; NUMBER 5.5]);
    ("price:<5", Ok [WORD "price"; COLON; LT; NUMBER 5.]);
    ("price:>5", Ok [WORD "price"; COLON; GT; NUMBER 5.]);
    ("price:<=5", Ok [WORD "price"; COLON; LTE; NUMBER 5.]);
    ("price:>=5", Ok [WORD "price"; COLON; GTE; NUMBER 5.]);
    ("price:1..5", Ok [WORD "price"; COLON; NUMBER 1.; DOTDOT; NUMBER 5.]);
    ("price:1.5..2.5", Ok [WORD "price"; COLON; NUMBER 1.5; DOTDOT; NUMBER 2.5]);
  ]

let comments =
  [
    ("", Ok []);
    ("   ", Ok []);
    ("# only", Ok []);
    ("a AND b # trailing", Ok [WORD "a"; AND; WORD "b"]);
    ("a # comment\nAND b", Ok [WORD "a"; AND; WORD "b"]);
    ("foo#bar", Ok [WORD "foo"]);
  ]

let errors =
  [
    ("\"abc", err "unterminated quoted string" 0 4);
    ("'abc", err "unterminated quoted string" 0 4);
    ("a \"b\\", err "unterminated quoted string" 2 5);
    ("a @ b", err "unexpected character '@'" 2 3);
    ("1.", err "unexpected character '.'" 1 2);
    ("a . b", err "unexpected character '.'" 2 3);
    ("a \\ b", err "unexpected character '\\'" 2 3);
  ]

let () =
  Alcotest.run "lexer"
    [
      ( "tokens",
        [
          Alcotest.test_case "words" `Quick (check words);
          Alcotest.test_case "phrases" `Quick (check phrases);
          Alcotest.test_case "operators" `Quick (check operators);
          Alcotest.test_case "fields" `Quick (check fields);
          Alcotest.test_case "comments" `Quick (check comments);
        ] );
      ("errors", [Alcotest.test_case "errors" `Quick (check errors)]);
    ]
