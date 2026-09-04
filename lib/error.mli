type t = { message : string; loc : Loc.t } [@@deriving eq, show]

val to_string : source:string -> t -> string
