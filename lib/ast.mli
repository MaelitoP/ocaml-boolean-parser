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

val pp_tree : Format.formatter -> t -> unit
