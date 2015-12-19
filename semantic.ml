open Ast
open Sast

type symbol_table = {
  mutable vars: var_decl list;
  mutable funcs: func_decl list;
}

(* list printer for testing purposes *)
let rec print_list = function
    [] -> ()
  | hd :: tl -> print_endline hd.fname; print_list tl


(**************
 * Exceptions *
**************)

exception Except of string

let op_error t = match t with
    Ast.Not -> raise (Except("Invalid use of unop: '!'"))
  | Ast.Add -> raise (Except("Invalid types for binop: '+'"))
  | Ast.Sub -> raise (Except("Invalid types for binop: '-'"))
  | Ast.Mult -> raise (Except("Invalid types for binop: '*'"))
  | Ast.Div -> raise (Except("Invalid types for binop: '/'"))
  | Ast.Mod -> raise (Except("Invalid types for binop: '%'"))
  | Ast.Or -> raise (Except("Invalid types for binop: '||'"))
  | Ast.And -> raise (Except("Invalid types for binop: '&&'"))
  | Ast.Equal -> raise (Except("Invalid types for binop: '=='"))
  | Ast.Neq -> raise (Except("Invalid types for binop: '!='"))
  | Ast.Less -> raise (Except("Invalid types for binop: '<'"))
  | Ast.Greater -> raise (Except("Invalid types for binop: '>'"))
  | Ast.Leq -> raise (Except("Invalid types for binop: '<='"))
  | Ast.Geq -> raise (Except("Invalid types for binop: '>='"))


(**************
 * Checking *
**************)

(* returns true if the function name is found in the current scope *)
let rec find_func (env : symbol_table) (f : string) =
  (try
    List.find(fun func -> func.fname = f) env.funcs
  with Not_found -> raise(Failure ("function " ^ f ^ " not defined")))

let rec check_expr (env : symbol_table) (expr : Ast.expr) = match expr with
    Noexpr -> Sast.Noexpr, Void
  | Id(str) -> (match (find_vname str env.vars) with
                  Var(vt, s) -> Sast.Id(s), vt
                | Var_Init(vt, s, e) -> Sast.Id(s), vt)
  | Int_lit(i) -> Sast.Int_lit(i), Sast.Int
  | Double_lit(d) -> Sast.Double_lit(d), Sast.Double
  | String_lit(s) -> Sast.String_lit(s), Sast.String
  | Bool_lit(b) -> Sast.Bool_lit(b), Sast.Boolean
  | ParenExpr(e) -> check_paren_expr env e
  | Unop(_, _) as u -> check_unop env u
  | Binop(_, _, _) as b -> check_binop env b
  | Assign(_, _) as a -> check_assign env a
  | Call(_, _) as c -> check_call env c

and check_paren_expr (env : symbol_table) pe =
  let e = check_expr env pe in
  let (_, t) = e in
  Sast.ParenExpr(e), t

and find_vname (vname : string) (vars : Sast.var_decl list) = match vars with
    [] -> raise(Failure "variable not defined")
  | hd :: tl -> let name = (match hd with
                              Var(vt, s) -> s
                            | Var_Init(vt, s, e) -> s) in
                if(vname = name) then hd
                else find_vname vname tl
(*
and check_id (env : symbol_table) id =
  (try
  let vname = List.find(fun name -> name = id) (get_vdecl_name_list env env.vars) in Sast.Id(vname), Sast.String
  with Not_found -> raise (Failure ("Variable not found")))
*)
and check_unop (env : symbol_table) unop = match unop with
	Ast.Unop(op, e) ->
		(match op with
			Not ->
				let expr = check_expr env e in
				let (_, t) = expr in
				if (t <> Boolean)
          then op_error op
        else Sast.Unop(op, expr), t
			| _ -> raise (Failure "Invalid unary operator"))
	| _ -> raise (Failure "Invalid unary operator")

and check_binop (env : symbol_table) binop = match binop with
  Ast.Binop(ex1, op, ex2) ->
    let e1 = check_expr env ex1 and e2 = check_expr env ex2 in
    let (_, t1) = e1 and (_, t2) = e2 in
    let t = match op with
        Mod ->
          if (t1 <> Int || t2 <> Int)
                then op_error op
          else Sast.Int
      | Add | Sub | Mult | Div ->
          if (t1 <> Int || t2 <> Int) then
            if (t1 <> Double || t2 <> Double)
              then op_error op
            else Sast.Double
          else Sast.Int
      | Greater | Less | Leq | Geq ->
          if (t1 <> Int || t2 <> Int) then
            if (t1 <> Double || t2 <> Double)
              then op_error op
            else Sast.Boolean
          else Sast.Boolean
      | And | Or ->
          if (t1 <> Boolean || t2 <> Boolean)
            then op_error op
          else Sast.Boolean
      | Equal | Neq ->
          if (t1 <> t2)
            then op_error op
          else Sast.Boolean
      | _ -> raise (Failure "Invalid binary operator")
    in Sast.Binop(e1, op, e2), t
  | _ -> raise (Failure "Not a binary operator")

and check_assign (env : symbol_table) a = match a with
  Ast.Assign(id, expr) ->
    let vdecl = find_vname id env.vars in
    let (t,n) = (match vdecl with
              Var(vt, s) -> (vt,s)
            | Var_Init(vt, s, e) -> (vt,s)) in
    let e = check_expr env expr in
    let (_, t2) = e in
    if t <> t2 then raise (Failure "Incorrect type for assignment") else Sast.Assign(n, e), t
  | _ -> raise (Failure "Not a valid assignment")

and check_call (env : symbol_table) c = match c with
    Ast.Call(f, actuals) -> (match f with
        "print" -> (match actuals with
            []        -> raise(Failure "print() requires an argument")
          | hd :: []     -> Sast.Call(f, [check_expr env hd]), Sast.Void
          | hd :: tl -> raise(Failure "print() only takes one argument"))
      (*| "draw" -> Sast.Call(f, actuals), Sast.Void (* PLACEHOLDER: actuals should be gram g and int n *)*)
      | _ -> let called_func = find_func env f in
             Sast.Call(f, (check_args env (called_func.formals, actuals))), called_func.rtype)
  | _ -> raise (Failure "Not a valid function call")

and check_args (env : symbol_table) ((formals : var_decl list), (actuals : Ast.expr list)) = match (formals, actuals) with
    ([], []) -> []
  | (f_hd :: f_tl, a_hd :: a_tl) ->
      let f_type = (match f_hd with
                Var(t, _) -> t
              | Var_Init(t, _, _) -> t) in
      let (a_expr, a_type) = check_expr env a_hd in
      if (f_type <> a_type) then raise (Failure "wrong argument type")
      else (a_expr, a_type) :: check_args env (f_tl, a_tl)
  | (_, _) -> raise (Failure "wrong number of arguments")

let check_vtype (t : Ast.var_type) = match t with
    Int    -> Sast.Int
  | Double -> Sast.Double
  | String -> Sast.String
  | Bool   -> Sast.Boolean
  | _      -> raise (Failure "Variables cannot be of this type.")


let check_vdecl (env : symbol_table) (v : Ast.var_decl) =
  (match v with
    Var(t, name) ->
      let t = check_vtype t in Sast.Var(t, name)
  | Var_Init(t, name, expr) ->
      let t = check_vtype t in
      let expr = check_expr env expr in
      let (_, t2 ) = expr in
      if t <> t2 then raise (Failure "Incorrect type for variable initialization") else Sast.Var_Init(t, name, expr))

let rec check_vdecl_list (env : symbol_table) (vl : Ast.var_decl list) = match vl with
    [] -> []
  | hd :: tl -> (check_vdecl env hd) :: (check_vdecl_list env tl)

let rec check_stmt (env : symbol_table) (s : Ast.stmt) = match s with
    Block(sl) -> Sast.Block(check_stmt_list env sl)
  | Expr(e) -> Sast.Expr(check_expr env e)
  | Return(e) -> Sast.Return(check_expr env e)
  | If(e, s1, s2) ->
		let expr = check_expr env e in
		let (_, t) = expr in
		if t <> Sast.Boolean then
			raise (Failure "If statement uses a boolean expression")
		else
			let stmt1 = check_stmt env s1 in
			let stmt2 = check_stmt env s2 in
			Sast.If(expr, stmt1, stmt2)
  | For(e1, e2, e3, s) ->
  	let ex1 = check_expr env e1 in
  	let ex2 = check_expr env e2 in
  	let (_, t) = ex2 in
  	if t <> Sast.Boolean then
  		raise (Failure "For statment uses a boolean expression")
  	else
  		let ex3 = check_expr env e3 in
  		let stmt = check_stmt env s in
  		Sast.For(ex1, ex2, ex3, stmt)
  | While(e, s) ->
		let expr = check_expr env e in
		let (_, t) = expr in
		if t <> Sast.Boolean then
			raise (Failure "While statement uses a boolean expression")
		else
			let stmt = check_stmt env s in
			Sast.While(expr, stmt)

and check_stmt_list (env : symbol_table) (sl : Ast.stmt list) = match sl with
    [] -> []
  | hd :: tl -> (check_stmt env hd) :: (check_stmt_list env tl)

let rec find_rtype (env : symbol_table) (body : Ast.stmt list) (rtype : Sast.var_type) = match body with
    [] -> rtype
  | hd :: tl -> (match hd with
      Return(e) -> if (rtype <> Sast.Void) then raise(Failure "function cannot have multiple return statements")
                   else let (_, t) = (check_expr env e) in find_rtype env tl t
    | _ -> find_rtype env tl rtype)

let sast_fdecl (env : symbol_table) (f : Ast.func_decl) =
  let checked_formals = check_vdecl_list env f.formals in
  let checked_locals = check_vdecl_list env f.locals in
  let new_env = { vars = checked_formals @ checked_locals; funcs = env.funcs } in
  { fname = f.fname; rtype = (find_rtype new_env f.body Sast.Void); formals = checked_formals; locals = checked_locals; body = (check_stmt_list new_env f.body) }

(* returns an updated func_decl with return type *)
let check_fdecl (env : symbol_table) (f : Ast.func_decl) = match f.fname with
    "main" -> (match f.formals with
        [] -> let sast_main = sast_fdecl env f in if (sast_main.rtype <> Sast.Void) then raise(Failure "main function should not return anything")
              else sast_main
      | _  -> raise(Failure "main function cannot have formal parameters"))
  | _ -> sast_fdecl env f

(* checks the list of function declarations in the program *)
let rec check_fdecl_list (env : symbol_table ) (prog : Ast.program) = match prog with
    []       -> raise(Failure "Valid FRAC program must have at least a main function")
  | hd :: [] -> if hd.fname <> "main" then raise(Failure "main function must be defined last")
                else { vars = env.vars; funcs = (check_fdecl env hd) :: env.funcs }
  | hd :: tl -> if (List.exists (fun func -> func.fname = hd.fname) env.funcs) then raise(Failure("function " ^ hd.fname ^ "() defined twice"))
                else match hd.fname with
                    "print" -> raise(Failure "reserved function name 'print'")
                  | "draw" -> raise(Failure "reserved function name 'draw'")
                  | "main" -> raise(Failure "main function can only be defined once")
                  | _ -> check_fdecl_list { vars = env.vars; funcs = (check_fdecl env hd) :: env.funcs } tl



(* entry point *)
let check_program (prog : Ast.program) =
  let env = { vars = []; funcs = [] } in
  let checked_fdecls = check_fdecl_list env (List.rev prog) in
  (*print_list checked_fdecls.funcs; print_endline "checked func decls!"; *)
  checked_fdecls.funcs
