(* Operators *)
type op = Add | Sub | Mult | Div | Mod | Equal | Neq | Less | Leq | Greater | Geq | Or | And | Not

(* Variable types *)
type var_type =
    Int
  | Double
  | String
  | Bool

(* Expressions *)
type expr =
    Int_lit of int
  | Double_lit of float
  | Id of string
  | String_lit of string
  | Bool_lit of bool
  | Unop of op * expr
  | Binop of expr * op * expr
  | Assign of string * expr
  | Call of string * expr list
  | Noexpr

(* Statements *)
type stmt =
    Expr of expr
  | Block of stmt list
  | Return of expr
  | If of expr * stmt * stmt
  | For of expr * expr * expr * stmt
  | While of expr * stmt

(* Variable Declarations *)
type var_decl =
    Var of var_type * string
  | Var_Init of var_type * string * expr

(* Function Declarations *)
type func_decl = {
  fname : string;
  formals : var_decl list;
  locals : var_decl list;
  body : stmt list;
}

(* Program entry point *)
type program = func_decl list
