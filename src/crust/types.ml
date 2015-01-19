type lifetime = string
type type_param = string
type variant_name = string
					  
type simple_type = [
  | `Int of int
  | `UInt of int
  | `Bool
  | `Unit
  ]
					 
type 'a mono_r_type = [
  | `Adt_type of 'a adt_type
  | `Ref of lifetime * 'a
  | `Ref_Mut of lifetime * 'a
  | `Ptr of 'a
  | `Ptr_Mut of 'a
  | simple_type
  | `Tuple of 'a list
  | `Bottom
  ]
 and 'a adt_type = {
	 type_name : string;
	 lifetime_param : lifetime list;
	 type_param : 'a list;
   }

type mono_type = mono_type mono_r_type;;
  
type r_type = [
  | `T_Var of type_param
  | r_type mono_r_type
  ]
				
type mono_adt_type = mono_type adt_type
type poly_adt_type = r_type adt_type
let rec (to_monomorph : (string * mono_type) list -> r_type -> mono_type) = fun t_binding t ->
  match t with
  | `Adt_type a ->
	 let mono_params = List.map (to_monomorph t_binding) a.type_param in
	 `Adt_type { a with type_param = mono_params }
  | `T_Var t_var -> List.assoc t_var t_binding
  | #simple_type as st -> st 
  | `Ref (l,t') -> `Ref (l,(to_monomorph t_binding t'))
  | `Ref_Mut (l, t') -> `Ref_Mut (l,(to_monomorph t_binding t'))
  | `Ptr_Mut t' -> `Ptr_Mut (to_monomorph t_binding t')
  | `Bottom -> `Bottom
  | `Ptr t' -> `Ptr (to_monomorph t_binding t')
  | `Tuple tl -> `Tuple (List.map (to_monomorph t_binding) tl)


let type_binding tv ty = 
  List.map2 (fun t_name t -> (t_name, t)) tv ty

let rec pp_t (to_pp : r_type) = match to_pp with
  | `Bottom -> "!"
  | `T_Var t -> "var " ^ t
  | `Int _ -> "int"
  | `UInt _ -> "uint"
  | `Unit -> "()"
  | `Bool -> "bool"
  | `Ptr t
  | `Ref (_,t) -> "const " ^ (pp_t t) ^ "*"
  | `Ref_Mut (_,t)
  | `Ptr_Mut t -> (pp_t t) ^ "*"
  | `Tuple tl -> "(" ^ (String.concat ", " @@ List.map pp_t tl) ^ ")"
  | `Adt_type p -> 
	 if p.type_param = [] then p.type_name 
	 else p.type_name ^ "<" ^ (String.concat "," @@ List.map pp_t p.type_param) ^ ">"


let rust_tuple_name = "__rust_tuple"