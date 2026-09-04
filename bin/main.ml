open Boolean_parser

let usage =
  "Usage: ocaml-boolean-parser [--format tree|query] [QUERY]\n\
   Reads the query from stdin when QUERY is omitted."

let print_tree = ref true
let query = ref None

let set_query q =
  match !query with
    | None -> query := Some q
    | Some _ -> raise (Arg.Bad "expects at most one QUERY")

let speclist =
  [
    ( "--format",
      Arg.Symbol (["tree"; "query"], fun f -> print_tree := f = "tree"),
      " output as a box-drawing tree (default) or as canonical query syntax" );
  ]

let () =
  Arg.parse speclist set_query usage;
  let source =
    match !query with Some q -> q | None -> In_channel.input_all stdin
  in
  match Boolean_parser.parse source with
    | Ok ast ->
        if !print_tree then Format.printf "%a@." Ast.pp_tree ast
        else print_endline (Printer.to_string ast)
    | Error error ->
        prerr_endline (Error.to_string ~source error);
        exit 1
