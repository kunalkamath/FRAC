open Ast
open Sast

type symbol_table = {
  vars: var_decl list;
  funcs: func_decl list;
}

(*type environment = {
  scope: symbol_table;
}*)

(* idk if i will need this *)
(*let check_types t1 t2 =
  if (t1 != t2) then raise(Failure "type " ^ t2 ^ " but expected type " ^ t1)
  else print_endline "correct types!" (* should this be returning something instead of printing? *)

let check_expr (scope: symbol_table) (expr: Ast.expr) = match expr with
    Int_lit(i) -> Sast.Int_lit(i)
  | Double_lit(d) -> Sast.Double_lit(d)
  | String_lit(s) -> Sast.String_lit(s)
  | Bool_lit(b) -> Sast.Bool_lit(b)
  | _ -> raise(Failure "invalid expression")

let rec check_stmt (scope: symbol_table) (stmt: Ast.stmt) = match stmt with
    Block(sl) -> Sast.Block(List.fold_left (fun a s -> (check_stmt scope s) :: a) [] sl)
  | Expr(e) -> Sast.Expr(check_expr scope e)
  | _ -> raise(Failure "invalid statement")

and check_stmts (scope: symbol_table) stmts = match stmts with
    [] -> scope
  | [stmt] -> check_stmt scope stmt
  | stmt :: more_stmts -> (* CONTINUE WORKING ON THIS *)*)

let check_expr (e : Ast.expr) = match e with
    _ -> Sast.Int_lit(1)

let rec check_stmt (s : Ast.stmt) = match s with
    Block(sl) -> check_stmt_list sl
  | Expr(e) -> check_expr e
  | Return(e) -> check_expr e

and check_stmt_list (sl : Ast.stmt list) = match sl with
    [] -> []
  | hd :: tl -> (check_stmt hd) :: (check_stmt_list tl)

(* returns the function name and return type *)
let check_fdecl (env : symbol_table) (f : Ast.func_decl) = match f.fname with
    "main" -> match f.formals with
        [] -> f.fname, Sast.Void (* PLACEHOLDER *)
      | _ -> raise(Failure "main function cannot have formal parameters") 
  | _ -> f.fname, Sast.Int (* PLACEHOLDER *)

let rec find_fname (f : string) (funcs : Ast.func_decl list) = match funcs with
    [] -> false
  | hd :: tl -> match hd.fname with
      f -> true || find_fname f tl
    | _ -> false || find_fname f tl

let rec check_fdecl_list (env : symbol_table ) (prog : Ast.program) = match prog with
    hd :: [] -> if hd.fname <> "main" then raise(Failure "main function must be defined last") 
      else (*check_fdecl hd;*) env
  | hd :: tl -> if (find_fname hd.fname env.funcs) then raise(Failure("function " ^ hd.fname ^ "() defined twice"))
      else match hd.fname with
          "print" -> raise(Failure "reserved function name 'print'")
        | "draw" -> raise(Failure "reserved function name 'draw'")
        | "main" -> raise(Failure "main function can only be defined once")
        | _ -> (*check_fdecl hd;*)
               check_fdecl_list ({ vars = env.vars; funcs = (hd :: env.funcs); }) tl

(* list printer for testing purposes *)
let rec print_list = function
    [] -> ()
  | hd :: tl -> print_endline hd.fname; print_list tl

let check_program (prog : Ast.program) =
  let env = { vars = []; funcs = [] } in
  let checked_fdecls = check_fdecl_list env (List.rev prog) in
  print_list checked_fdecls.funcs; print_endline "checked func decls!";

(* todo:
  + check that main func does not have args
  + 
*)




