open Boolean_parser

let render (source, message, start, stop) =
  Error.to_string ~source { Error.message; loc = { Loc.start; stop } }

let check cases () =
  List.iter
    (fun (((source, _, _, _) as input), expected) ->
      Alcotest.(check string) source expected (render input))
    cases

let cases =
  [
    ( ("a @ b", "unexpected character '@'", 2, 3),
      "1:3: unexpected character '@'\na @ b\n  ^" );
    ( ("a OR OR b", "syntax error", 5, 7),
      "1:6: syntax error\na OR OR b\n     ^^" );
    (("a AND", "syntax error", 5, 5), "1:6: syntax error\na AND\n     ^");
    (("a AND # c\nOR b", "syntax error", 10, 12), "2:1: syntax error\nOR b\n^^");
    ( ("\"ab\ncd", "unterminated quoted string", 0, 6),
      "1:1: unterminated quoted string\n\"ab\n^^^" );
  ]

let () =
  Alcotest.run "error"
    [
      ( "to_string",
        [Alcotest.test_case "excerpt and caret" `Quick (check cases)] );
    ]
