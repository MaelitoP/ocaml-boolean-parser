open Boolean_parser
open Ast

let ast = Alcotest.testable Ast.pp Ast.equal
let error = Alcotest.testable Error.pp Error.equal
let parsed = Alcotest.(result ast error)

let check cases () =
  List.iter
    (fun (tree, canonical) ->
      let printed = Printer.to_string tree in
      Alcotest.(check string) (Ast.show tree) canonical printed;
      Alcotest.check parsed canonical (Ok tree) (Boolean_parser.parse printed))
    cases

let a = Word "a"
let b = Word "b"
let c = Word "c"
let d = Word "d"

let terms =
  [
    (a, "a");
    (Word "_x1", "_x1");
    (Word "and", "and");
    (Phrase "hello world", "\"hello world\"");
    (Phrase "it's", "\"it's\"");
    (Phrase "say \"hi\"", "\"say \\\"hi\\\"\"");
    (Phrase "a\\b", "\"a\\\\b\"");
  ]

let operators =
  [
    (And (a, b), "a AND b");
    (Or (a, b), "a OR b");
    (Not a, "NOT a");
    (Not (Not a), "NOT NOT a");
    (And (a, Not b), "a AND NOT b");
    (Not (And (a, b)), "NOT (a AND b)");
    (Not (Or (a, b)), "NOT (a OR b)");
  ]

let precedence =
  [
    (Or (Or (a, b), c), "a OR b OR c");
    (Or (a, Or (b, c)), "a OR (b OR c)");
    (And (And (a, b), c), "a AND b AND c");
    (And (a, And (b, c)), "a AND (b AND c)");
    (Or (Not a, And (b, c)), "NOT a OR b AND c");
    (Or (And (a, b), And (c, d)), "a AND b OR c AND d");
    (And (a, Or (b, c)), "a AND (b OR c)");
    (And (Or (a, b), c), "(a OR b) AND c");
    (Not (And (Not a, b)), "NOT (NOT a AND b)");
  ]

let fields =
  [
    (Field ("title", Word "foo"), "title:foo");
    (Field ("title", Phrase "foo bar"), "title:\"foo bar\"");
    (Field ("price", Number 5.), "price:5");
    (Field ("price", Number 5.5), "price:5.5");
    (Field ("price", Lt 5.), "price:<5");
    (Field ("price", Gt 5.), "price:>5");
    (Field ("price", Lte 5.), "price:<=5");
    (Field ("price", Gte 5.), "price:>=5");
    (Field ("price", Between (1., 5.)), "price:1..5");
    (Field ("price", Between (1.5, 2.5)), "price:1.5..2.5");
    (Not (Field ("title", Word "foo")), "NOT title:foo");
  ]

let () =
  Alcotest.run "printer"
    [
      ( "to_string",
        [
          Alcotest.test_case "terms" `Quick (check terms);
          Alcotest.test_case "operators" `Quick (check operators);
          Alcotest.test_case "precedence" `Quick (check precedence);
          Alcotest.test_case "fields" `Quick (check fields);
        ] );
    ]
