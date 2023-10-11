let string_of_location (Syntax.Location l) = Printf.sprintf "#%s" l

let exp_label = function
  | Syntax.Lookup l -> string_of_location l
  | Int i -> string_of_int i
  | Plus _ -> "+"
  | Minus _ -> "-"
  | Times _ -> "*"

let bexp_label = function
  | Syntax.Bool b -> string_of_bool b
  | Equal _ -> "="
  | Less _ -> "<"
  | Greater _ -> ">"
  | And _ -> "&&"
  | Or _ -> "||"

let cmd_label = function
  | Syntax.Assign _ -> ":="
  | IfThenElse _ -> "IF"
  | Seq _ -> ";"
  | Skip -> "SKIP"
  | WhileDo _ -> "WHILE"
  | PrintInt _ -> "PRINT"
  | Switch _ -> "SWITCH"
  | Fail -> "FAIL"
  | ForLoop _ -> "FOR"

let node_name ind = Printf.sprintf "node%d" ind

let node_str shape name label =
  Printf.sprintf "%s[label=%S;shape=%s];" name label shape

let connect name child = Printf.sprintf "%s -> %s;" name child

let rec tree_exp ind exp =
  let name = node_name ind in
  let ind = ind + 1 in
  let ind, direct, all =
    match exp with
    | Syntax.Lookup (Location _) -> (ind, [], [])
    | Int _ -> (ind, [], [])
    | Times (l, r) | Minus (l, r) | Plus (l, r) ->
        let ind, l, la = tree_exp ind l in
        let ind, r, ra = tree_exp ind r in
        (ind, [ l; r ], la @ ra)
  in
  let all = List.map (connect name) direct @ all in
  let all = node_str "oval" name (exp_label exp) :: all in
  (ind, name, all)

let rec tree_bexp ind bexp =
  let name = node_name ind in
  let ind = ind + 1 in
  let ind, direct, all =
    match bexp with
    | Syntax.Bool _ -> (ind, [], [])
    | Equal (l, r) | Less (l, r) | Greater (l, r) ->
        let ind, l, la = tree_exp ind l in
        let ind, r, ra = tree_exp ind r in
        (ind, [ l; r ], la @ ra)
    | And (l, r) | Or (l, r) ->
        let ind, l, la = tree_bexp ind l in
        let ind, r, ra = tree_bexp ind r in
        (ind, [ l; r ], la @ ra)
  in
  let all = List.map (connect name) direct @ all in
  let all = node_str "square" name (bexp_label bexp) :: all in
  (ind, name, all)

let rec tree_cmd ind cmd =
  let name = node_name ind in
  let ind = ind + 1 in
  let ind, direct, all =
    match cmd with
    | Syntax.Assign (l, exp) ->
        let ind, l, la = tree_exp ind (Lookup l) in
        let ind, r, ra = tree_exp ind exp in
        (ind, [ l; r ], la @ ra)
    | IfThenElse (bexp, c1, c2) ->
        let ind, l, la = tree_bexp ind bexp in
        let ind, t, ta = tree_cmd ind c1 in
        let ind, f, fa = tree_cmd ind c2 in
        (ind, [ l; t; f ], la @ ta @ fa)
    | WhileDo (bexp, c) ->
        let ind, l, la = tree_bexp ind bexp in
        let ind, t, ta = tree_cmd ind c in
        (ind, [ l; t ], la @ ta)
    | Seq (c1, c2) ->
        let ind, t, ta = tree_cmd ind c1 in
        let ind, f, fa = tree_cmd ind c2 in
        (ind, [ t; f ], ta @ fa)
    | PrintInt e ->
        let ind, l, a = tree_exp ind e in
        (ind, [ l ], a)
    | Skip -> (ind, [], [])
    | Switch (l1, l2) ->
        let ind, l1, la = tree_exp ind (Lookup l1) in
        let ind, l2, lb = tree_exp ind (Lookup l2) in
        (ind, [ l1; l2 ], la @ lb)
    | Fail -> (ind, [], [])
    | ForLoop (l, f, t, c) ->
        let ind, l, la = tree_exp ind (Lookup l) in
        let ind, f, fa = tree_exp ind f in
        let ind, t, ta = tree_exp ind t in
        let ind, c, ca = tree_cmd ind c in
        (ind, [ l; f; t; c ], la @ fa @ ta @ ca)
  in
  let all = List.map (connect name) direct @ all in
  let all = node_str "diamond" name (cmd_label cmd) :: all in
  (ind, name, all)

let ast_string cmd =
  let _, _, all = tree_cmd 0 cmd in
  Printf.sprintf "digraph G {\n  %s\n}\n" (String.concat "\n  " all)

let rec sum_upto n = if n = 0 then 0 else n + sum_upto (n - 1)
