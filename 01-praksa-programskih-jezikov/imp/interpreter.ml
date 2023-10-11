exception Terminated of Syntax.state

let rec eval_exp st = function
  | Syntax.Int n -> n
  | Syntax.Lookup l -> List.assoc l st
  | Syntax.Plus (e1, e2) -> eval_exp st e1 + eval_exp st e2
  | Syntax.Minus (e1, e2) -> eval_exp st e1 - eval_exp st e2
  | Syntax.Times (e1, e2) -> eval_exp st e1 * eval_exp st e2

let rec eval_bexp st = function
  | Syntax.Bool b -> b
  | Syntax.Equal (e1, e2) -> eval_exp st e1 = eval_exp st e2
  | Syntax.Greater (e1, e2) -> eval_exp st e1 > eval_exp st e2
  | Syntax.Less (e1, e2) -> eval_exp st e1 < eval_exp st e2
  | Syntax.Or (a, b) ->
      (*
         We explicitly calcualte both branches of the expression to avoid short-circuiting.
      *)
      let a = eval_bexp st a in
      let b = eval_bexp st b in
      a || b
  | Syntax.And (a, b) ->
      let a = eval_bexp st a in
      let b = eval_bexp st b in
      a && b

let rec eval_cmd st = function
  | Syntax.Assign (l, e) ->
      let n = eval_exp st e in
      let st' = (l, n) :: List.remove_assoc l st in
      st'
  | Syntax.IfThenElse (b, c1, c2) ->
      if eval_bexp st b then eval_cmd st c1 else eval_cmd st c2
  | Syntax.Seq (c1, c2) ->
      let st' = eval_cmd st c1 in
      let st'' = eval_cmd st' c2 in
      st''
  | Syntax.Skip -> st
  | Syntax.WhileDo (b, c) ->
      if eval_bexp st b then
        let st' = eval_cmd st c in
        eval_cmd st' (Syntax.WhileDo (b, c))
      else st
  | Syntax.PrintInt e ->
      let n = eval_exp st e in
      let s = string_of_int n in
      print_endline s;
      st
  | Syntax.Fail -> raise (Terminated st)
  | Syntax.Switch (l1, l2) ->
      if l1 = l2 then st
      else
        let n1 = List.assoc l1 st in
        let n2 = List.assoc l2 st in
        let st = st |> List.remove_assoc l1 |> List.remove_assoc l2 in
        let st = (l1, n2) :: (l2, n1) :: st in
        st
  | Syntax.ForLoop (l, e1, e2, c) ->
      (*
           (* For loop can also be transformed into an equivalent while loop *)
           let while_loop =
                Syntax.Seq
                  ( Syntax.Assign (l, e1),
                    Syntax.WhileDo
                      ( Syntax.Less (Syntax.Lookup l, Syntax.Int (eval_exp st e2)),
                        Syntax.Seq
                          ( c,
                            Syntax.Assign
                              (l, Syntax.Plus (Syntax.Lookup l, Syntax.Int 1)) ) ) )
              in
              eval_cmd st while_loop *)
      let e1' = eval_exp st e1 in
      let e2 = eval_exp st e2 in
      let rec loop st e1 =
        if e1 < e2 then
          let st = eval_cmd st c in
          let st = (l, e1 + 1) :: List.remove_assoc l st in
          loop st (e1 + 1)
        else st
      in
      loop ((l, e1') :: List.remove_assoc l st) e1'

let run c =
  let st' = try eval_cmd [] c with Terminated st -> st in
  print_endline "[";
  List.iter
    (fun (Syntax.Location l, n) ->
      print_endline ("  #" ^ l ^ " := " ^ string_of_int n))
    st';
  print_endline "]"
