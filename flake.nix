{
  description = "Boolean query parser for OCaml";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      forSystem =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          op = pkgs.ocamlPackages;
        in
        {
          default = pkgs.mkShell {
            packages = [
              op.ocaml
              op.dune_3
              op.findlib
              op.ocaml-lsp
              op.utop
              op.odoc
              pkgs.ocamlformat

              op.menhir
              op.ppx_deriving
              op.alcotest
              op.qcheck
              op.qcheck-alcotest
            ];
          };
        };
    in
    {
      devShells = nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" "x86_64-linux" ] forSystem;
    };
}
