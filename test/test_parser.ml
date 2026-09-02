open Boolean_parser
open Ast

let ast = Alcotest.testable Ast.pp Ast.equal
let error = Alcotest.testable Error.pp Error.equal
let parsed = Alcotest.(result ast error)
let err message start stop = Error { Error.message; loc = { Loc.start; stop } }
let syntax_error start stop = err "syntax error" start stop

let check cases () =
  List.iter
    (fun (input, expected) ->
      Alcotest.check parsed input expected (Boolean_parser.parse input))
    cases

let a = Word "a"
let b = Word "b"
let c = Word "c"
let d = Word "d"

let terms =
  [
    ("a", Ok a);
    ("_x1", Ok (Word "_x1"));
    ("and", Ok (Word "and"));
    ("\"hello world\"", Ok (Phrase "hello world"));
    ("'it\\'s'", Ok (Phrase "it's"));
    ("((a))", Ok a);
  ]

let operators =
  [
    ("a AND b", Ok (And (a, b)));
    ("a && b", Ok (And (a, b)));
    ("a & b", Ok (And (a, b)));
    ("a OR b", Ok (Or (a, b)));
    ("a || b", Ok (Or (a, b)));
    ("a | b", Ok (Or (a, b)));
    ("NOT a", Ok (Not a));
    ("!a", Ok (Not a));
    ("-a", Ok (Not a));
    ("NOT NOT a", Ok (Not (Not a)));
    ("!-a", Ok (Not (Not a)));
    ("a AND NOT b", Ok (And (a, Not b)));
    ("NOT (a AND b)", Ok (Not (And (a, b))));
  ]

let precedence =
  [
    ("a OR b OR c", Ok (Or (Or (a, b), c)));
    ("a AND b AND c", Ok (And (And (a, b), c)));
    ("NOT a OR b AND c", Ok (Or (Not a, And (b, c))));
    ("a AND b OR c AND d", Ok (Or (And (a, b), And (c, d))));
    ("a AND (b OR c)", Ok (And (a, Or (b, c))));
  ]

let fields =
  [
    ("title:foo", Ok (Field ("title", Word "foo")));
    ("title : foo", Ok (Field ("title", Word "foo")));
    ("title:\"foo bar\"", Ok (Field ("title", Phrase "foo bar")));
    ("title:'foo bar'", Ok (Field ("title", Phrase "foo bar")));
    ("price:5", Ok (Field ("price", Number 5.)));
    ("price:5.5", Ok (Field ("price", Number 5.5)));
    ("price:<5", Ok (Field ("price", Lt 5.)));
    ("price:>5", Ok (Field ("price", Gt 5.)));
    ("price:<=5", Ok (Field ("price", Lte 5.)));
    ("price:>=5", Ok (Field ("price", Gte 5.)));
    ("price:1..5", Ok (Field ("price", Between (1., 5.))));
    ("price:1.5..2.5", Ok (Field ("price", Between (1.5, 2.5))));
    ("NOT title:foo", Ok (Not (Field ("title", Word "foo"))));
  ]

let comments =
  [
    ("a AND b # trailing", Ok (And (a, b)));
    ("a # comment\nAND b", Ok (And (a, b)));
    ("foo#bar", Ok (Word "foo"));
  ]

let empty =
  [
    ("", err "empty query" 0 0);
    ("   ", err "empty query" 3 3);
    ("# only", err "empty query" 6 6);
  ]

let syntax_errors =
  [
    ("a b", syntax_error 2 3);
    ("foo-bar", syntax_error 3 4);
    ("5", syntax_error 0 1);
    ("a AND", syntax_error 5 5);
    ("AND a", syntax_error 0 3);
    ("a OR OR b", syntax_error 5 7);
    ("NOT", syntax_error 3 3);
    ("(a", syntax_error 2 2);
    ("a)", syntax_error 1 2);
    ("()", syntax_error 1 2);
    ("a:b:c", syntax_error 3 4);
    ("title:", syntax_error 6 6);
    ("title:AND", syntax_error 6 9);
    ("price:-5", syntax_error 6 7);
    ("price:<", syntax_error 7 7);
    ("price:<foo", syntax_error 7 10);
    ("price:1..", syntax_error 9 9);
  ]

let lexical_errors =
  [
    ("\"abc", err "unterminated quoted string" 0 4);
    ("a @ b", err "unexpected character '@'" 2 3);
    ("1.", err "unexpected character '.'" 1 2);
    ("a . b", err "unexpected character '.'" 2 3);
  ]

let () =
  Alcotest.run "parser"
    [
      ( "valid",
        [
          Alcotest.test_case "terms" `Quick (check terms);
          Alcotest.test_case "operators" `Quick (check operators);
          Alcotest.test_case "precedence" `Quick (check precedence);
          Alcotest.test_case "fields" `Quick (check fields);
          Alcotest.test_case "comments" `Quick (check comments);
        ] );
      ( "errors",
        [
          Alcotest.test_case "empty" `Quick (check empty);
          Alcotest.test_case "syntax" `Quick (check syntax_errors);
          Alcotest.test_case "lexical" `Quick (check lexical_errors);
        ] );
    ]
