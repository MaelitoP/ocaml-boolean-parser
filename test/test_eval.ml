open Boolean_parser
open Ast

type doc = { words : string list; text : string; price : float }

let doc = { words = ["red"; "shoe"]; text = "red running shoe"; price = 42. }

let field name value =
  match (name, value) with
    | "price", Number n -> doc.price = n
    | "price", Lt n -> doc.price < n
    | "price", Gt n -> doc.price > n
    | "price", Lte n -> doc.price <= n
    | "price", Gte n -> doc.price >= n
    | "price", Between (lo, hi) -> lo <= doc.price && doc.price <= hi
    | _ -> false

let eval =
  Eval.eval
    ~word:(fun w -> List.mem w doc.words)
    ~phrase:(String.equal doc.text) ~field

let cases =
  [
    (Word "red", true);
    (Word "blue", false);
    (Phrase "red running shoe", true);
    (Phrase "red", false);
    (Field ("price", Number 42.), true);
    (Field ("price", Number 41.), false);
    (Field ("price", Lt 50.), true);
    (Field ("price", Lt 42.), false);
    (Field ("price", Gt 40.), true);
    (Field ("price", Gt 42.), false);
    (Field ("price", Lte 42.), true);
    (Field ("price", Lte 41.), false);
    (Field ("price", Gte 42.), true);
    (Field ("price", Gte 43.), false);
    (Field ("price", Between (40., 42.)), true);
    (Field ("price", Between (43., 50.)), false);
    (Field ("color", Word "red"), false);
    (Not (Word "blue"), true);
    (Not (Word "red"), false);
    (And (Word "red", Word "shoe"), true);
    (And (Word "red", Word "blue"), false);
    (Or (Word "blue", Word "shoe"), true);
    (Or (Word "blue", Word "sock"), false);
    (Or (Not (Word "red"), And (Word "shoe", Field ("price", Lt 50.))), true);
  ]

let check_cases () =
  List.iter
    (fun (ast, expected) ->
      Alcotest.(check bool) (Printer.to_string ast) expected (eval ast))
    cases

let short_circuit () =
  let word = function
    | "t" -> true
    | "f" -> false
    | w -> Alcotest.failf "evaluated %s" w
  in
  let unreachable _ = Alcotest.fail "evaluated a non-word term" in
  let eval =
    Eval.eval ~word ~phrase:unreachable ~field:(fun _ -> unreachable)
  in
  Alcotest.(check bool) "f AND boom" false (eval (And (Word "f", Word "boom")));
  Alcotest.(check bool) "t OR boom" true (eval (Or (Word "t", Word "boom")))

let () =
  Alcotest.run "eval"
    [
      ( "eval",
        [
          Alcotest.test_case "connectives and field values" `Quick check_cases;
          Alcotest.test_case "short-circuit" `Quick short_circuit;
        ] );
    ]
