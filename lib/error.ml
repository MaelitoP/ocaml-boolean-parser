type t = { message : string; loc : Loc.t } [@@deriving eq, show]

let to_string ~source { message; loc = { Loc.start; stop } } =
  let line_start =
    match String.rindex_from_opt source (start - 1) '\n' with
      | Some i -> i + 1
      | None -> 0
  in
  let line_end =
    Option.value
      (String.index_from_opt source start '\n')
      ~default:(String.length source)
  in
  let line =
    1
    + String.fold_left
        (fun n c -> if c = '\n' then n + 1 else n)
        0
        (String.sub source 0 line_start)
  in
  let col = start - line_start + 1 in
  let width = max 1 (min stop line_end - start) in
  Printf.sprintf "%d:%d: %s\n%s\n%s%s" line col message
    (String.sub source line_start (line_end - line_start))
    (String.make (col - 1) ' ')
    (String.make width '^')
