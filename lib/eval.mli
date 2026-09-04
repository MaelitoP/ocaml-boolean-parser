val eval :
  word:(string -> bool) ->
  phrase:(string -> bool) ->
  field:(string -> Ast.value -> bool) ->
  Ast.t ->
  bool
