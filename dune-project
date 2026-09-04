(lang dune 3.19)

(name ocaml-boolean-parser)

(using menhir 3.0)

(cram enable)

(generate_opam_files true)

(source
 (github MaelitoP/ocaml-boolean-parser))

(authors "Maël LE PETIT <maelito.contact@gmail.com>")

(maintainers "Maël LE PETIT <maelito.contact@gmail.com>")

(license MIT)

(package
 (name ocaml-boolean-parser)
 (synopsis "Boolean query parser for OCaml")
 (description "Parser, printer and evaluator for a small boolean search query language")
 (depends
  (ocaml
   (>= 5.1))
  menhir
  ppx_deriving
  (alcotest :with-test)
  (qcheck-alcotest :with-test)))
