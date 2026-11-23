pragma Ada_2022;

with Element_Type_Defs; use Element_Type_Defs;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Formal.Generic_Indefinite_List_Operations;
with SPARK.Containers.Formal.Generic_List_Storage;
with SPARK.Pointers.Poisoned.Pointers;

--  Instantiate the storage and operations used by the production unbounded
--  list independently of its Controlled shell.

private package SPARK.Containers.Formal.Indefinite_List_Operations_Proof
  with SPARK_Mode
is
   pragma Unevaluated_Use_Of_Old (Allow);

   package Cells is new SPARK.Pointers.Poisoned.Pointers (Element_Type);
   package Storage is new Generic_List_Storage (Cells.Pointer);
   package Indefinite_Ops is new
     Generic_Indefinite_List_Operations (Element_Type, "=", Cells, Storage);
   package Sorting is new Indefinite_Ops.Ops.Generic_Sorting;

   type Cursor is record
      Node : Count_Type := 0;
   end record;

   function To_Cursor (Index : Count_Type) return Cursor
   is ((Node => Index))
   with Ghost => SPARKlib_Logic;

   function Node (Position : Cursor) return Count_Type
   is (Position.Node)
   with Ghost => SPARKlib_Logic;

   package Formal_Model
     with Ghost => SPARKlib_Logic
   is
      package M is new
        SPARK.Containers.Functional.Vectors
          (Storage.Positive_Count_Type,
           Element_Type,
           Eq_Reflexive                   => Eq_Reflexive,
           Eq_Symmetric                   => Eq_Symmetric,
           Eq_Transitive                  => Eq_Transitive,
           Equivalent_Elements_Reflexive  => Equivalent_Reflexive,
           Equivalent_Elements_Symmetric  => Eq_Symmetric,
           Equivalent_Elements_Transitive => Eq_Transitive);
      package P is new
        SPARK.Containers.Functional.Maps
          (Cursor,
           Storage.Positive_Count_Type,
           Enable_Handling_Of_Equivalence => False);
   end Formal_Model;

   package List_Model is new
     Indefinite_Ops.Ops.Generic_Model
       (Cursor,
        To_Cursor,
        Node,
        Formal_Model.M,
        Formal_Model.P);
   package Sorting_Model is new List_Model.Generic_Sorting;
end SPARK.Containers.Formal.Indefinite_List_Operations_Proof;
