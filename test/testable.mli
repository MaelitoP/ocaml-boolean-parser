val ast : Boolean_parser.Ast.t Alcotest.testable
val error : Boolean_parser.Error.t Alcotest.testable

val parsed :
  (Boolean_parser.Ast.t, Boolean_parser.Error.t) result Alcotest.testable

val err : string -> int -> int -> ('a, Boolean_parser.Error.t) result
