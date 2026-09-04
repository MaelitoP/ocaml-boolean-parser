let rec eval ~word ~phrase ~field (query : Ast.t) =
  match query with
    | Word w -> word w
    | Phrase p -> phrase p
    | Field (name, value) -> field name value
    | Not q -> not (eval ~word ~phrase ~field q)
    | And (l, r) -> eval ~word ~phrase ~field l && eval ~word ~phrase ~field r
    | Or (l, r) -> eval ~word ~phrase ~field l || eval ~word ~phrase ~field r
