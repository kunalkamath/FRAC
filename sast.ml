open Ast

(* Variable types *)
type var_type =
    Void
  | Int
  | Double
  | String
  | Boolean
  | Gram

(* Variable Declarations*)
and var_decl =
    Var of var_type * string
  | Var_Init of var_type * string * expression

and term =
    Rturn of expr
  | Lturn of expr
  | Move of expr

(* Rule Definitions *)
and rule =
    Rec of string * string list
  | Term of string * term

(* Grammar Declarations *)
and gram_decl = {
  gname : string;
  alphabet : string list;
  init : string list;
  rec_rules : rule list;
  term_rules : rule list;
}

(* Function Declarations *)
and func_decl = {
  fname: string;
  rtype: var_type;
  formals: var_decl list;
  locals: var_decl list;
  body: stmt list;
}

(* Expressions *)
and expr =
    Noexpr
  | Int_lit of int
  | Double_lit of float
  | Id of string
  | String_lit of string
  | Bool_lit of bool
  | ParenExpr of expression
  | Unop of op * expression
  | Binop of expression * op * expression
  | Assign of string * expression
  | Call of string * expression list

and expression = expr * var_type

(* Statements *)
and stmt =
    Expr of expression
  | Block of stmt list
  | Return of expression
  | If of expression * stmt * stmt
  | For of expression * expression * expression * stmt
  | While of expression * stmt


type program = gram_decl list * func_decl list
