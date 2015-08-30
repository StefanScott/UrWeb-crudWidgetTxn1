table t1 : {
  Id : int, 
  A : int, 
  B : string, 
  C : float, 
  D : bool}
PRIMARY KEY Id

open CrudWidgetTxn.Make( struct
  val tab = t1
  val title = "Crud1"
  val cols = { 
    A = CrudWidgetTxn.int "A",
    B = CrudWidgetTxn.string "B",
    C = CrudWidgetTxn.float "C",
    D = CrudWidgetTxn.bool "D"}
end )