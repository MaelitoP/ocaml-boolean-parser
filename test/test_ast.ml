open Boolean_parser

let ast = Alcotest.testable Ast.pp Ast.equal
let tree t = Format.asprintf "%a" Ast.pp_tree t

let test_equal () =
  let a = Ast.And (Word "a", Not (Field ("price", Between (1., 5.)))) in
  Alcotest.check ast "structurally equal" a
    (And (Word "a", Not (Field ("price", Between (1., 5.)))));
  Alcotest.(check bool)
    "different operand order" false
    (Ast.equal (And (Word "a", Word "b")) (And (Word "b", Word "a")));
  Alcotest.(check bool)
    "word versus phrase" false
    (Ast.equal (Word "a") (Phrase "a"))

let test_leaves () =
  List.iter
    (fun (expected, t) -> Alcotest.(check string) expected expected (tree t))
    [
      ("foo", Ast.Word "foo");
      ("\"hello \\\"w\\\"\"", Phrase "hello \"w\"");
      ("\"a\\\\b\"", Phrase "a\\b");
      ("title:foo", Field ("title", Word "foo"));
      ("title:\"foo bar\"", Field ("title", Phrase "foo bar"));
      ("price:5", Field ("price", Number 5.));
      ("price:5.5", Field ("price", Number 5.5));
      ("price:<5", Field ("price", Lt 5.));
      ("price:>5", Field ("price", Gt 5.));
      ("price:<=5", Field ("price", Lte 5.));
      ("price:>=5", Field ("price", Gte 5.));
      ("price:1..5", Field ("price", Between (1., 5.)));
    ]

let test_tree_not_or_and () =
  Alcotest.(check string)
    "NOT a OR b AND c" "OR\n├── NOT\n│   └── a\n└── AND\n    ├── b\n    └── c"
    (tree (Or (Not (Word "a"), And (Word "b", Word "c"))))

let test_tree_and_or_and () =
  Alcotest.(check string)
    "a AND b OR c AND d"
    "OR\n├── AND\n│   ├── a\n│   └── b\n└── AND\n    ├── c\n    └── d"
    (tree (Or (And (Word "a", Word "b"), And (Word "c", Word "d"))))

let test_tree_fields () =
  Alcotest.(check string)
    "NOT title:\"foo bar\" AND price:1..5"
    "AND\n├── NOT\n│   └── title:\"foo bar\"\n└── price:1..5"
    (tree
       (And
          ( Not (Field ("title", Phrase "foo bar")),
            Field ("price", Between (1., 5.)) )))

let () =
  Alcotest.run "ast"
    [
      ("equal", [Alcotest.test_case "equal" `Quick test_equal]);
      ( "pp_tree",
        [
          Alcotest.test_case "leaves" `Quick test_leaves;
          Alcotest.test_case "NOT a OR b AND c" `Quick test_tree_not_or_and;
          Alcotest.test_case "a AND b OR c AND d" `Quick test_tree_and_or_and;
          Alcotest.test_case "fields" `Quick test_tree_fields;
        ] );
    ]
