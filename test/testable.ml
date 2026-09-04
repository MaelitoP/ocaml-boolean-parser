open Boolean_parser

let ast = Alcotest.testable Ast.pp Ast.equal
let error = Alcotest.testable Error.pp Error.equal
let parsed = Alcotest.(result ast error)
let err message start stop = Error { Error.message; loc = { Loc.start; stop } }
