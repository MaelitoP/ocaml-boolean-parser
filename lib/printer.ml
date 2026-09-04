open Ast

let prec = function
  | Or _ -> 1
  | And _ -> 2
  | Not _ -> 3
  | Word _ | Phrase _ | Field _ -> 4

let rec to_string = function
  | Word w -> w
  | Phrase p -> value_to_string (Phrase p)
  | Field (name, v) -> name ^ ":" ^ value_to_string v
  | Not e -> "NOT " ^ group (prec e < 3) e
  | And (l, r) -> group (prec l < 2) l ^ " AND " ^ group (prec r <= 2) r
  | Or (l, r) -> to_string l ^ " OR " ^ group (prec r <= 1) r

and group parens e = if parens then "(" ^ to_string e ^ ")" else to_string e
