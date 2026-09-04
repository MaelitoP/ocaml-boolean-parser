open QCheck2
open Boolean_parser.Ast

let lower = Gen.char_range 'a' 'z'

let word =
  Gen.map2
    (fun first rest -> String.make 1 first ^ rest)
    (Gen.oneof [lower; Gen.return '_'])
    (Gen.string_size
       ~gen:(Gen.oneof [lower; Gen.char_range '0' '9'; Gen.return '_'])
       (Gen.int_bound 5))

let phrase = Gen.string_size ~gen:Gen.printable (Gen.int_bound 8)
let number = Gen.map (fun n -> float_of_int n /. 100.) (Gen.int_bound 100_000)

let value =
  Gen.oneof_weighted
    [
      (2, Gen.map (fun w : value -> Word w) word);
      (1, Gen.map (fun p : value -> Phrase p) phrase);
      (2, Gen.map (fun n -> Number n) number);
      (1, Gen.map (fun n -> Lt n) number);
      (1, Gen.map (fun n -> Gt n) number);
      (1, Gen.map (fun n -> Lte n) number);
      (1, Gen.map (fun n -> Gte n) number);
      (1, Gen.map2 (fun lo hi -> Between (lo, hi)) number number);
    ]

let leaf =
  Gen.oneof_weighted
    [
      (3, Gen.map (fun w -> Word w) word);
      (1, Gen.map (fun p -> Phrase p) phrase);
      (2, Gen.map2 (fun name v -> Field (name, v)) word value);
    ]

let ast =
  Gen.sized
  @@ Gen.fix (fun self n ->
      if n = 0 then leaf
      else (
        let sub = self (n / 2) in
        Gen.oneof_weighted
          [
            (1, leaf);
            (1, Gen.map (fun e -> Not e) sub);
            (2, Gen.map2 (fun l r -> And (l, r)) sub sub);
            (2, Gen.map2 (fun l r -> Or (l, r)) sub sub);
          ]))
