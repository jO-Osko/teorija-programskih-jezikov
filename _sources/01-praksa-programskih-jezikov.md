---
jupytext:
  text_representation:
    extension: .md
    format_name: myst
    format_version: 0.12
    jupytext_version: 1.8.0
kernelspec:
  display_name: OCaml 4.11
  language: OCaml
  name: ocaml-jupyter
---

# Praksa programskih jezikov

```{code-cell}
:tags: [remove-cell, remove-stdout]

(* Ko se v Jupytru prvič požene OCaml, program Findlib izpiše neko sporočilo.
   Da se to sporočilo ne bi videlo v zapiskih, je tu ta celica, ki sproži izpis,
   vendar ima nastavljeno, da je v zapiskih v celoti skrita. *)
```

Da lahko začnemo raziskovati lastnosti programskih jezikov, potrebujemo primer takega jezika. To bo enostaven ukazni (oz. imperativni) programski jezik IMP, ki podpira aritmetične izraze (cela števila, spremenljivke, aritmetične operacije), logične izraze (logični konstanti ter primerjave aritmetičnih izrazov) ter ukaze (pogojne stavke, zanke, …).

## Sintaksa jezika

Prva stvar, ki jo moramo podati v definiciji programskega jezika, je njegova sintaksa - torej zapis vseh izrazov, ki jih jezik omogoča. Ločujemo med _konkretno sintakso_, ki definira zaporedja znakov, ki predstavljajo veljavne programe, ter _abstraktno sintakso_, ki možne izraze jezika predstavi z drevesno strukturo. Na primer, `1 + (2 * 3)` in `1+2*3` sta različna niza konkretne sintakse, ki oba predstavljata izraz abstraktne sintakse, predstavljen z drevesom

      +
     / \
    1   *
       / \
      2   3

ki ga na krajše pišemo kar kot $1 + (2 * 3)$, pri čemer matematična pisava nakazuje, da nas podrobnosti, kot so presledki, ne zanimajo.

### Konkretna sintaksa

Konkretno sintakso običajno podajamo v [Backus-Naurovi obliki (BNF)](https://en.m.wikipedia.org/wiki/Backus–Naur_form). Ker mora konkretno sintakso razumeti tudi računalnik, v njej upoštevamo tudi presledke, zamike, oklepaje, komentarje, …  Ta je sestavljena iz pravil, ki povedo, kakšne vrste simbolov lahko nastopajo v jeziku. Pravilo, ki podaja sintakso določenega simbola je oblike

    <simbol> ::= moznost1 | moznost2 | ...

kjer je vsaka izmed možnosti sestavljena iz enega ali več nizov ali drugih simbolov. Na primer, simbol za števko `<digit>` je lahko kateri koli izmed nizov `"0"`, `"1"`, …, `"9"`, številka pa je sestavljena iz ene ali več števk ter morebitnega predznaka:

    <digit> ::= "0" | "1" | ... | "9"
    <digits> ::= "" | <digit> <digits>
    <integer> ::= <digits> | "-" <digits>

Za programski jezik IMP bo konkretna sintaksa

    <space> ::= " " | "\n" | "\t" | "\r"
    <spaces> ::= "" | <spaces1>
    <spaces1> ::= <space> <spaces>

    <alpha> ::= "a" | "b" | ... | "z"
    <alphanum> ::= <alpha> | <digit>
    <alphanums> ::= "" | <alphanum> <alphanums>
    <ident> ::= <alpha> <alhpanums>
    <location> ::= "#" <ident>

    <exp> ::= <atomic_exp> <spaces> "+" <spaces> <atomic_exp>
           |  <atomic_exp> <spaces> "-" <spaces> <atomic_exp>
           |  <atomic_exp> <spaces> "*" <spaces> <atomic_exp>
           |  <atomic_exp>
    <atomic_exp> ::= <location>
                  |  <integer>
                  |  "(" <spaces> <exp> <spaces> ")"
    <bexp> ::= "true"
            |  "false"
            |  <exp> <spaces> "=" <spaces> <exp>
            |  <exp> <spaces> "<" <spaces> <exp>
            |  <exp> <spaces> ">" <spaces> <exp>
    <cmd> ::= "IF" <spaces1> <bexp> <spaces1> "THEN" <spaces1> <cmd> <spaces1> "ELSE" <spaces1> <cmd>
           |  "WHILE" <spaces1> <bexp> <spaces1> "DO" <spaces1> <cmd>
           |  <atomic_cmd> <spaces> ";" <spaces> <cmd>
    <atomic_cmd> ::= <location> <spaces> ":=" <spaces> <exp>
                  |  "SKIP"
                  |  "(" <spaces> <cmd> <spaces> ")"

Kaj predstavljajo zgoraj omenjeni simboli, si bomo ogledali pri abstraktni sintaksi jezika IMP, za idejo pa lahko vseeno podamo primer veljavnega programa v konkretni sintaksi:

    #fact := 1;
    WHILE #m > 0 DO (
        #fact := #fact * #m;
        #m := #m - 1
    )

Videti je, da program v pomnilniško lokacijo `#fact` shrani fakulteto števila, shranjenega v `#m`, vendar tega ne vemo, dokler ne podamo semantike jezika.

### Abstraktna sintaksa

Kot smo že videli, v abstraktni sintaksi možne izraze predstavimo z drevesi, katerih otroci predstavljajo njihove podizraze. Zaradi krajšega zapisa pa tudi abstraktno sintakso podamo v zapisu, podobnemu BNF, pri čemer nas podrobnosti, kot so oklepaji ali točen zapis spremenljivk in števil ne zanima.  Tako bomo predpostavili, da $n$ predstavlja poljubno celo število, $\ell$ pa poljubno pomnilniško lokacijo.

Kot smo že omenili, je jezik IMP sestavljen iz aritmetičnih izrazov, ki jih bomo označevali s spremenljivko $e$, logičnih izrazov, ki jih bomo označevali z $b$, ter ukazov, ki jih bomo označevali s $c$.

$$
  \begin{aligned}
    \text{aritmetični izraz } e &::=
      \ell \mid
      \intsym{n} \mid
      e_1 + e_2 \mid
      e_1 - e_2 \mid
      e_1 * e_2 \\
    \text{logični izraz } b &::=
      \true \mid
      \false \mid
      e_1 = e_2 \mid
      e_1 < e_2 \mid
      e_1 > e_2 \\
    \text{ukaz } c &::=
      \ifthenelse{b}{c_1}{c_2} \mid
      \whiledo{b}{c} \mid
      c_1 ; c_2 \mid
      \ell := e \mid
      \skip
  \end{aligned}
$$

Oglejmo si vse veljavne dele jezika, pri čemer bomo za vsakega neformalno povedali, kaj predstavlja. Aritmetični izrazi so sestavljeni iz branja vrednosti pomnilniških lokacij, celoštevilskih konstant (ki jih podčrtamo, da jih ločimo od celih števil) ter aritmetičnih operacij, logični izrazi pa so sestavljeni iz logičnih konstant ter primerjav. Ukazi so bolj zanimivi:

- pogojni ukaz, ki izvede $c_1$, kadar $b$ predstavlja resnično logično vrednost, oziroma $c_2$, kadar $b$ predstavlja neresnično logično vrednost;
- zanka `while` izvaja ukaz $c$, dokler $b$ predstavlja resnično logično vrednost;
- zaporedno izvajanje najprej izvede $c_1$ - ko (če) se ta konča, izvede še $c_2$;
- prirejanje izračuna aritmetični izraz $e$ ter njegovo vrednost zapiše v pomnilniško lokacijo $\ell$;
- zadnji ukaz ne naredi ničesar, uporabimo pa ga na primer takrat, kadar v pogojnem stavku želimo nekaj storiti le v eni izmed vej.

Zgornji program bi v abstraktni sintaksi lahko predstavili z ukazom

$$
  \begin{aligned}
    &\mathsf{fact} := \intsym{1}; \\
    &\whiledo{\mathsf{m} > \intsym{0}}{} \\
    &\quad \mathsf{fact} := \mathsf{fact} * \mathsf{m}; \\
    &\quad \mathsf{m} := \mathsf{m} - \intsym{1}
  \end{aligned}
$$

## Implementacija jezika

Običajno bi po sintaksi jezika formalno podali še njegovo semantiko, torej pomen posameznih delov. Ker za to še nimamo ustreznih matematičnih orodij, bomo ravnali podobno kot pri večini programskih jezikov: napisali bomo implementacijo, torej program, ki prebere ukaze, zapisane v konkretni sintaksi, ter jih na nek (po vsej sreči smiselen) način izvede. Nato pa bomo proglasili, da je pomen programa v IMPu tisto, kar implementacija z njim naredi. Implementacijo bomo napisali v programskem jeziku [OCaml](https://ocaml.org), ki je eden najprikladnejših jezikov za implementacije programskih jezikov. Končnica `ML` namreč pomeni _meta-language_ oziroma metajezik, torej jezik za opis jezikov.

### Implementacija abstraktne sintakse

Sintakso, ki je sestavljena iz treh vrst izrazov, bomo predstavili s tremi induktivnimi tipi. Pomnilniške lokacije bomo predstavili kar z nizi, vendar jih bomo zaradi lažjega razločevanja ovili s konstruktorjem.

```{code-cell}
:tags: [remove-output]

type location = Location of string

type exp =
  | Lookup of location
  | Int of int
  | Plus of exp * exp
  | Minus of exp * exp
  | Times of exp * exp

type bexp =
  | Bool of bool
  | Equal of exp * exp
  | Less of exp * exp
  | Greater of exp * exp

type cmd =
  | IfThenElse of bexp * cmd * cmd
  | WhileDo of bexp * cmd
  | Seq of cmd * cmd
  | Assign of location * exp
  | Skip
```

Na primer, aritmetična izraza $e_1 = (\intsym{6} * \intsym{7})$ in $e_2 = (\mathsf{m} - \intsym{1})$ bi predstavili z

```{code-cell}
let exp1 = Times (Int 6, Int 7)
let exp2 = Minus (Lookup (Location "m"), Int 1)
```

logični izraz $b = (\mathsf{m} > \intsym{0})$ z

```{code-cell}
let bexp = Greater (Lookup (Location "m"), Int 0)
```

ukaza $c_1 = (\mathsf{m} := e_2)$ in $c_2 = (\whiledo{b}{c_1})$ pa z

```{code-cell}
let cmd1 = Assign (Location "m", exp2)
let cmd2 = WhileDo (bexp, cmd1)
```

### Implementacija izvajanja

Pomen bomo najprej določili aritmetičnim izrazom, ki naj bi predstavljali cela števila. Ker izrazi lahko vsebujejo pomnilniške lokacije, mora funkcija za evalvacijo poleg izraza sprejeti tudi trenutno stanje pomnilnika, ki ga bomo predstavili kar s seznamom parov, ki danim lokacijam pripiše cela števila, na primer

```{code-cell}
let st1 = [(Location "m", 10); (Location "n", 0)]
let st2 = [(Location "m", 5)]
```

```{code-cell}
let rec eval_exp st = function
  | Lookup l -> List.assoc l st
  | Int n -> n
  | Plus (e1, e2) -> eval_exp st e1 + eval_exp st e2
  | Minus (e1, e2) -> eval_exp st e1 - eval_exp st e2
  | Times (e1, e2) -> eval_exp st e1 * eval_exp st e2
```

Tako na primer velja

```{code-cell}
eval_exp [] exp1
```

```{code-cell}
eval_exp st1 exp2
```

```{code-cell}
eval_exp st2 exp2
```

Podobno lahko definiramo funkcijo za evalvacijo logičnih izrazov, ki sprejme stanje in logični izraz ter vrne logično vrednost:

```{code-cell}
let eval_bexp st = function
  | Bool b -> b
  | Equal (e1, e2) -> eval_exp st e1 = eval_exp st e2
  | Less (e1, e2) -> eval_exp st e1 < eval_exp st e2
  | Greater (e1, e2) -> eval_exp st e1 > eval_exp st e2
```

```{code-cell}
eval_bexp st1 bexp
```

```{code-cell}
eval_bexp st2 bexp
```

Nazadnje definirajmo še funkcijo za evalvacijo ukazov. Funkcija sprejme stanje in ukaz, vrne pa končno vrednost stanja po izvršenem ukazu.

```{code-cell}
let rec eval_cmd st = function
  | IfThenElse (b, c1, c2) ->
      if eval_bexp st b then eval_cmd st c1 else eval_cmd st c2
  | WhileDo (b, c) ->
      (* eval_cmd st (IfThenElse (b, Seq (c, WhileDo (b, c)), Skip)) *)
      if eval_bexp st b then
        let st' = eval_cmd st c in
        eval_cmd st' (WhileDo (b, c))
      else st
  | Seq (c1, c2) ->
      let st' = eval_cmd st c1 in
      eval_cmd st' c2
  | Assign (l, e) -> (l, eval_exp st e) :: List.remove_assoc l st
  | Skip -> st
```

```{code-cell}
eval_cmd st1 cmd1
```

```{code-cell}
eval_cmd st2 cmd1
```

```{code-cell}
eval_cmd st1 cmd2
```

```{code-cell}
eval_cmd st2 cmd2
```

### Implementacija razčlenjevalnika

Razčlenjevalnikov običajno ne pišemo direktno, temveč se poslužimo posebnih orodij, ki sprejmejo definicijo jezika v zapisu podobnem BNF, ter iz nje samodejno ustvarijo program. V primeru OCamla sta taka programa [`ocamlyacc`](https://v2.ocaml.org/manual/lexyacc.html) in njegova naprednejša različica [Menhir](http://gallium.inria.fr/~fpottier/menhir/). Prav tako je sestavni del razčlenjevalnika _lekser_, ki zaporedje znakov najprej pretvori v zaporedje _leksemov_, kjer so zaporedne števke že združene v števila, ključne besede nadomeščene s posebnimi simboli, presledki in komentarji pa odstranjeni.

Mi pa bomo zato, da bomo ostali znotraj enega orodja in zraven ponovili še malo funkcijskega programiranja, ubrali bolj neposredno pot in uporabili [kombinatorje razčlenjevalnikov](https://en.wikipedia.org/wiki/Parser_combinator). Vsak razčlenjevalnik bo sestavljen iz manjših razčlenjevalnikov, od katerih bo vsak predelal del besedila. Poglejmo najprej, kakšne oblike bodo.

#### Tip razčlenjevalnikov `'a parser`

Recimo, da želimo razčlenjevalnik za cela števila. Začnimo z željo po funkciji `string -> int`, ki vzame vhodni niz ter vrne prebrano število, na primer iz niza `"42"` dobimo število `42`.

Ker vsak niz ne bo predstavljal števila, moramo najprej popraviti ti rezultata, da dobimo `string -> int option`. Tako bomo iz niza `"42"` dobili `Some 42`, iz niza `"abc"` pa `None`.

Razčlenjevalnike bomo združevali in vsak ne bo prebral celotnega niza, temveč samo njegov začetek, preostanek pa bo predal nadaljnjim razčlenjevalnikom. Zato ne vrnemo samo rezultata, temveč tudi preostali niz, zato je še boljši tip `string -> (int * string) option`. Tako bi razčlenjevalnik pri vhodu `"42abc"` vrnil `Some (42, "abc")`, pri vhodu `"42"` rezultat `Some (42, "")`, pri vhodu `"abc42"` pa `None`, saj začetek ne predstavlja števila.

Niz je veliko enostavneje brati postopoma, če ga poprej pretvorimo v zaporedje znakov. Za pretvorbo uporabljamo funkciji:

```{code-cell}
let explode str = List.init (String.length str) (String.get str)
let implode chrs = String.init (List.length chrs) (List.nth chrs)
```

```{code-cell}
explode "abc"
```

```{code-cell}
implode ['T'; 'P'; 'J']
```

Tudi tip razčlenjevalnikov spremenimo v `char list -> (int * char list) option`. Ker seveda ne bomo brali samo celih števil, celoten tip razčlenjevalnikov parametriziramo glede na tip prebranih vrednosti:

```{code-cell}

type 'a parser = char list -> ('a * char list) option
```

Zgoraj opisani razčlenjevalnik bi tako lahko definirali kot:

```{code-cell}
let parse_int : int parser =
  fun chrs ->
  let rec take_initial_digits =
    function
    | chr :: chrs when String.contains "0123456789" chr ->
        let digits, rest = take_initial_digits chrs in
        (chr :: digits, rest)
    | chrs -> ([], chrs)
  in
  match take_initial_digits chrs with
  | ([], chrs) -> None
  | (digits, chrs) ->
      Some (int_of_string (implode digits), chrs)
```

```{code-cell}
parse_int (explode "42abc")
```

```{code-cell}
parse_int (explode "42")
```

```{code-cell}
parse_int (explode "abc42")
```

Pri definiciji smo ročno dopisali tip `int parser`, saj bi nam OCaml sicer prikazoval ekvivalenten, vendar manj pregleden tip `char list -> (int * char list) option`. Za preglednejše testiranje si napišimo pomožno funkcijo `($$$) : 'a parser -> string -> ('a * string) option`, ki samodejno poskrbi za pretvorbo med nizi in zaporedji znakov.

```{code-cell}
let ( $$$ ) (parser : 'a parser) str =
  match parser (explode str) with
  | None -> None
  | Some (x, rest) -> Some (x, implode rest)
```

Funkciji damo simbolno ime `( $$$ )`, da jo lahko kličemo infiksno kot `parser $$$ niz`.

```{code-cell}
parse_int $$$ "42abc"
```

#### Osnovni razčlenjevalniki

Vse razčlenjevalnike pisati na tak način bi bilo precej nerodno. Raje si bomo definirali nekaj osnovnih, ki jih bomo združevali v večje. Prvi je razčlenjevalnik `fail`, ki vedno zavrne vhod:

```{code-cell}
let fail : 'a parser = fun _chrs -> None
```

```{code-cell}
fail $$$ "42abc"
```

Nato imamo funkcijo `return`, ki sprejme vrednost `v` in vrne razčlenjevalnik, ki ne glede na vhod vrne uspešno prebrano vrednost `v`, celoten vhod pa posreduje naprej.

```{code-cell}
let return v : 'a parser = fun chrs -> Some (v, chrs)
```

```{code-cell}
return 10 $$$ "42abc"
```

Prvi razčlenjevalnik, ki bo dejansko upošteval vhod, je `character`, ki prebere prvi znak, kadar obstaja, ostale pa pošlje naprej:

```{code-cell}
let character : char parser = function
  | [] -> None
  | chr :: chrs -> Some (chr, chrs)
```

```{code-cell}
character $$$ "42abc"
```

```{code-cell}
character $$$ ""
```

Nato imamo izbiro, ki najprej poskusi en razčlenjevalnik, če pa temu ne uspe, pa še drugega. Oba razčlenjevalnika morata seveda vračati vrednost enakega tipa.

```{code-cell}
let ( || ) (parser1 : 'a parser) (parser2 : 'a parser) : 'a parser =
 fun chrs ->
  match parser1 chrs with
  | None -> parser2 chrs
  | Some (v, chrs') -> Some (v, chrs')
```

```{code-cell}
(fail || character) $$$ "42abc"
```

```{code-cell}
(return 'X' || character) $$$ "42abc"
```

Nazadnje moramo znati razčlenjevalnike še združevati, kar storimo s funkcijo `>>=`, ki dva razčlenjevalnika veriži enega za drugim. V večini primerov bo drugi razčlenjevalnik odvisen od vrednosti, ki jo je prebral prvi. Na primer, če bomo najprej prebrali znak za začetek komentarja, bomo preskočili vse do konca vrstice, če pa bomo našli kaj drugega, pa bomo pričakovali veljaven ukaz. Tako je `parser1` razčlenjevalnik, ki vrne vrednost tipa `'a`, med tem ko `parser2` ni razčlenjevalnik, temveč funkcija `'a -> 'b parser`, ki vrne razčlenjevalnik odvisen od prebranega rezultata.

```{code-cell}
let ( >>= ) (parser1 : 'a parser) (parser2 : 'a -> 'b parser) : 'b parser =
 fun chrs ->
  match parser1 chrs with
  | None -> None
  | Some (v, chrs') -> parser2 v chrs'
```

Veriženje deluje tako, da najprej uporabimo `parser1`. Če že ta zavrne vhod, takoj končamo in vrnemo `None`. V primeru, pa da dobimo neko vrednost `v`, jo skupaj s preostankom znakov podamo funkciji `parser2`, ki potem uspešno ali neuspešno vrne končni rezultat.

Na primer, spodnja kombinacija najprej prebere katerikoli znak, nato pa ta znak poda funkciji, ki ne glede na preostanek, ki sledi, vedno vrne niz, sestavljen iz 10 kopij tega znaka.

```{code-cell}
let vedno_preberi_10_kopij_znaka c = return (String.make 10 c)
```

```{code-cell}
character >>= vedno_preberi_10_kopij_znaka $$$ "42abc"
```

Isto seveda lahko dosežemo tudi z anonimno funkcijo:

```{code-cell}
(character >>= fun c -> return (String.make 10 c)) $$$ "42abc"
```

#### Osnovni kombinatorji

Izkaže se, da je zgoraj naštetih pet razčlenjevalnikov, torej `fail`, `return`, `character`, `||` in `>>=` dovolj, da izrazimo vse razčlenjevalnike, ki jih potrebujemo. Na primer, če želimo vrniti par zaporedoma prebranih vrednosti, lahko to zapišemo kot:

```{code-cell}
let pair parser1 parser2 = parser1 >>= fun v1 -> parser2 >>= fun v2 -> return (v1, v2)
```

```{code-cell}
pair character character $$$ "42abc"
```

Če želimo, da uspešno prebrana vrednost zadošča še kakšnemu predikatu, uporabimo funkcijo `satisfy`, kjer v drugem delu odvisno od pogoja vrednost vrnemo ali zavrnemo:

```{code-cell}
let satisfy cond parser =
  parser >>= fun v -> if cond v then return v else fail
```

Na primer, spodnji razčlenjevalnik sprejema samo znake `'a'`, `'b'` in `'c'`.

```{code-cell}
satisfy (String.contains "abc") character $$$ "123"
```

```{code-cell}
satisfy (String.contains "abc") character $$$ "a23"
```

Pri zapisu pogojnih razčlenjevalnikov uporabljamo operacijo `x |> f`, ki funkcijo `f` uporabi na vrednosti `x`. Isti primer kot zgoraj bi napisali na sledeč način, kjer je bolj jasno, da najprej preberemo znak, nato pa preverimo, da je eden od znakov niza `"abc"`.

```{code-cell}
character |> satisfy (String.contains "abc") $$$ "a23"
```

Konkretna uporaba kombinatorja `satisfy` je razčlenjevalnik `exactly`, ki sprejme natanko znak `chr`:

```{code-cell}
let exactly chr = character |> satisfy (( = ) chr)
```

```{code-cell}
(exactly 'a' || exactly 'b') $$$ "abc"
```

Enako si lahko definiramo razčlenjevalnike, ki sprejemajo samo števke, črke ali presledke:

```{code-cell}

let digit =
  let is_digit = String.contains "0123456789" in
  character |> satisfy is_digit

let alpha =
  let is_alpha = String.contains "abcdefghijklmnopqrstvwuxyz" in
  character |> satisfy is_alpha

let space =
  let is_space = String.contains " \n\t\r" in
  character |> satisfy is_space
```

Podoben kombinator je `map`, ki prebere rezultat `v` in ga pretvori s pomočjo funkcije `f`.

```{code-cell}
let map f parser = parser >>= fun v -> return (f v)
```

```{code-cell}
(character |> map Char.uppercase_ascii) $$$ "abc"
```

Poseben primer operacije `>>=` je `>>`, kjer ne upoštevamo vrednosti, ki jo je prebral prvi razčlenjevalnik. Na primer, vemo, da se zanka vedno začne s ključno besedo `while`, ampak sama vrednost `"while"` za pomen programa ni pomembna.

```{code-cell}
let ( >> ) parser1 parser2 = parser1 >>= fun _ -> parser2
```

```{code-cell}
(exactly 'a' >> exactly 'b' >> character) $$$ "abcde"
```

```{code-cell}
(exactly 'a' >> exactly 'b' >> character) $$$ "bacde"
```

Postopek lahko posplošimo na poljuben niz znakov. Razčlenjevalnik napišemo tako, da besedo `str` razbijemo na seznam znakov `chrs`, nato iz tega naredimo seznam razčlenjevalnikov, ki zaporedoma sprejemajo natanko te znake, nato pa jih vse skupaj verižimo s pomočjo `>>`. Ta razčlenjevalnik bomo uporabljali za prebiranje ključnih besed kot so `while`, `if` in podobno, zato na koncu vrnemo vrednost `()`.

```{code-cell}
let word str =
  let chrs = explode str in
  let chr_parsers = List.map exactly chrs in
  List.fold_right ( >> ) chr_parsers (return ())
```

```{code-cell}
word "while" $$$ "while true do skip"
```

```{code-cell}
word "while" $$$ "if true then skip else skip"
```

Podobno lahko s pomočjo `fold_right` zaporedoma z `||` poskusimo vse razčlenjevalnike iz danega seznama:

```{code-cell}
let one_of parsers = List.fold_right ( || ) parsers fail
```

```{code-cell}
one_of [word "while"; word "if"] $$$ "while true do skip"
```

```{code-cell}
one_of [word "while"; word "if"] $$$ "if true then skip else skip"
```

```{code-cell}
one_of [word "while"; word "if"] $$$ "skip"
```

Rekurzivno si lahko definiramo tudi razčlenjevalnika `many` in `many1`, ki dani razčlenjevalnik uporabita poljubno mnogokrat oziroma vsaj enkrat, vrneta pa seznam uspešno prebranih vrednosti:

```{code-cell}
let rec many parser = many1 parser || return []

and many1 parser =
  parser >>= fun v ->
  many parser >>= fun vs -> return (v :: vs)
```

```{code-cell}
many digit $$$ "1234abc567"
```

S pomočjo vseh zgoraj naštetih kombinatorjev zdaj veliko lepše napišemo razčlenjevalnik za branje celih števil. Najprej moramo prebrati vsaj eno števko, nato seznam števk združimo v en sam niz, na koncu pa pogoljufamo in s pomočjo vgrajene funkcije to pretvorimo v število.

```{code-cell}
let integer = many1 digit |> map implode |> map int_of_string
```

```{code-cell}
integer $$$ "123abc"
```

#### Razčlenjevalniki za IMP

Razvili smo vsa orodja, ki jih potrebujemo, da preberemo celotno sintakso jezika IMP. Za ločevanje med posameznimi deli bomo uporabili presledke. Pri ključnih besedah bomo zahtevali vsaj enega, okoli operatorjev pa ne nujno:

```{code-cell}
let spaces = many space >> return ()
let spaces1 = many1 space >> return ()
```

Zaradi enostavnosti bomo za večje podizraze zahtevali, da se pojavijo v oklepajih:

```{code-cell}
let parens parser =
  exactly '(' >> spaces >> parser >>= fun v -> spaces >> exactly ')' >> return v
```

```{code-cell}
parens integer $$$ "(1234)"
```

Lokacije se bodo začele z znakom `#`, ki jim bo sledilo ime. To bo sestavljeno iz alfanumeričnih znakov, od katerih mora biti prvi črka.

```{code-cell}
let ident =
  alpha >>= fun chr ->
  many (alpha || digit) >>= fun chrs -> return (implode (chr :: chrs))

let location = word "#" >> ident >>= fun ident -> return (Location ident)
```

```{code-cell}
location $$$ "#fact"
```

Dvojiška operacija je podana s simbolom `op`, njegovim pomenom `f` ter z razčlenjevalnikom argumentov `parser`. Med operacijo in argumentoma so morebitni presledki

```{code-cell}
let binop parser op f =
  parser >>= fun v1 ->
  spaces >> word op >> spaces >>
  parser >>= fun v2 ->
  return (f v1 v2)
```

Pri razčlenjevalniku za aritmetične izraze sledimo sintaksi. Izrazi so lahko sestavljeni iz aritmetičnih operacij ali atomarni, pri čemer so atomarni izrazi lokacije, konstante ali običajni izrazi v oklepajih.

```{code-cell}
let rec exp chrs =
  one_of
    [
      binop atomic_exp "+" (fun e1 e2 -> Plus (e1, e2));
      binop atomic_exp "-" (fun e1 e2 -> Minus (e1, e2));
      binop atomic_exp "*" (fun e1 e2 -> Times (e1, e2));
      atomic_exp;
    ]
    chrs

and atomic_exp chrs =
  one_of
    [
      (location >>= fun l -> return (Lookup l));
      (integer >>= fun n -> return (Int n));
      parens exp;
    ]
    chrs
```

```{code-cell}
exp $$$ "1 + 3"
```

Podobno definiramo razčlenjevalnik za Booleove izraze:

```{code-cell}
let bexp =
  one_of
    [
      word "true" >> return (Bool true);
      word "false" >> return (Bool false);
      binop exp "=" (fun e1 e2 -> Equal (e1, e2));
      binop exp "<" (fun e1 e2 -> Less (e1, e2));
      binop exp ">" (fun e1 e2 -> Greater (e1, e2));
    ]
```

```{code-cell}
bexp $$$ "1 + 3 < 2 * 4"
```

Podobno definiramo tudi razčlenjevalnik za ukaze:

```{code-cell}
let rec cmd chrs =
  let if_then_else =
    word "if" >> spaces1 >> bexp >>= fun b ->
    spaces1 >> word "then" >> spaces1 >> cmd >>= fun c1 ->
    spaces1 >> word "else" >> spaces1 >> atomic_cmd >>= fun c2 ->
    return (IfThenElse (b, c1, c2))
  and while_do =
    word "while" >> spaces1 >> bexp >>= fun b ->
    spaces1 >> word "do" >> spaces1 >> atomic_cmd >>= fun c ->
    return (WhileDo (b, c))
  and seq =
    atomic_cmd >>= fun c1 ->
    spaces >> word ";" >> spaces >> cmd >>= fun c2 ->
    return (Seq (c1, c2))
  in
  one_of [ if_then_else; while_do; seq; atomic_cmd ] chrs

and atomic_cmd chrs =
  let assign =
    location >>= fun l ->
    spaces >> word ":=" >> spaces >> exp >>= fun e ->
    return (Assign (l, e))
  and skip = word "skip" >> return Skip
  in
  one_of [ assign; skip; parens cmd ] chrs
```

```{code-cell}
cmd $$$ "if 3 < 4 then skip else skip"
```

Vsaka IMP datoteka je sestavljena iz enega samega ukaza (ki je seveda lahko sestavljen iz več ukazov, ločenih s podpičjem). Da preberemo celotno datoteko, torej le pokličemo razčlenjevalnik `cmd`. Če nam ni ostalo nič neprebranih znakov, poženemo `eval_cmd` na praznem seznamu, sicer pa program zavrnemo:

```{code-cell}
let run str =
  match str |> String.trim |> explode |> cmd with
  | Some (c, []) -> eval_cmd [] c
  | Some (_, _ :: _) | None -> failwith "Parsing error"
```

```{code-cell}
run "#n := 10; #fact := 1; while #n > 0 do ( #fact := #fact * #n; #n := #n - 1 )"
```
