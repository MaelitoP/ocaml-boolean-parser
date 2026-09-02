type value =
  | Word of string
  | Phrase of string
  | Number of float
  | Lt of float
  | Gt of float
  | Lte of float
  | Gte of float
  | Between of float * float
[@@deriving eq, show]

type t =
  | Word of string
  | Phrase of string
  | Field of string * value
  | Not of t
  | And of t * t
  | Or of t * t
[@@deriving eq, show]

let quote s =
  let b = Buffer.create (String.length s + 2) in
  Buffer.add_char b '"';
  String.iter
    (fun c ->
      if c = '"' || c = '\\' then Buffer.add_char b '\\';
      Buffer.add_char b c)
    s;
  Buffer.add_char b '"';
  Buffer.contents b

let number_to_string n =
  let s = Printf.sprintf "%.15g" n in
  if float_of_string s = n then s else Printf.sprintf "%.17g" n

let value_to_string : value -> string = function
  | Word w -> w
  | Phrase p -> quote p
  | Number n -> number_to_string n
  | Lt n -> "<" ^ number_to_string n
  | Gt n -> ">" ^ number_to_string n
  | Lte n -> "<=" ^ number_to_string n
  | Gte n -> ">=" ^ number_to_string n
  | Between (lo, hi) -> number_to_string lo ^ ".." ^ number_to_string hi

let rec pp_node ppf prefix = function
  | Word w -> Format.pp_print_string ppf w
  | Phrase p -> Format.pp_print_string ppf (quote p)
  | Field (name, v) -> Format.fprintf ppf "%s:%s" name (value_to_string v)
  | Not e ->
      Format.pp_print_string ppf "NOT";
      pp_children ppf prefix [e]
  | And (l, r) ->
      Format.pp_print_string ppf "AND";
      pp_children ppf prefix [l; r]
  | Or (l, r) ->
      Format.pp_print_string ppf "OR";
      pp_children ppf prefix [l; r]

and pp_children ppf prefix = function
  | [] -> ()
  | [last] ->
      Format.fprintf ppf "@\n%s└── " prefix;
      pp_node ppf (prefix ^ "    ") last
  | child :: rest ->
      Format.fprintf ppf "@\n%s├── " prefix;
      pp_node ppf (prefix ^ "│   ") child;
      pp_children ppf prefix rest

let pp_tree ppf t = pp_node ppf "" t
