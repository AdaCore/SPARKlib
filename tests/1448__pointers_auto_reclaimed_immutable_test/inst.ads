pragma Extensions_Allowed (On);
--  Clients of the reference-counted units have to enable extensions
--  themselves: the instantiation re-elaborates a private part which uses the
--  GNAT-specific Finalizable aspect.

with Ada.Unchecked_Deallocation;
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Pointers.Auto_Reclaimed.Immutable;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;

package Inst with SPARK_Mode is

   --  A plain designated object

   type Plain_Object is record
      F : Integer;
      G : Integer;
   end record;

   package Plain_Pointers is new SPARK.Pointers.Auto_Reclaimed.Immutable (Plain_Object);

   function Id (O : Plain_Object) return Plain_Object is (O);
   function Create_Plain is new Plain_Pointers.Create (Plain_Object, Id);

   --  Deref, which copies the designated value, as opposed to
   --  Constant_Reference, which observes it in place.

   package Plain_Ops is new Plain_Pointers.Copy_Operations (Id);

   --  A designated object subject to ownership. Reclaim frees the cell and
   --  bumps a counter, so the test can observe that the library reclaims.

   type Int_Acc is access Integer;

   type Owning_Object is record
      D : Int_Acc;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Acc);

   procedure Reclaim (X : in out Owning_Object)
   with Global => null, Always_Terminates, Post => X.D = null;

   package Owning_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Immutable (Owning_Object, Reclaim);

   function Make (V : Integer) return Owning_Object
   is (D => new Integer'(V));

   function Create_Owning is new Owning_Pointers.Create (Integer, Make);

   --  Handles over the owning pointers. Immutable data cannot form a cycle,
   --  so the flavour without weak handles is the right one.

   use Owning_Pointers;

   package Owning_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.Without_Weak_Handles;

   package Owning_Handle_Ops is new
     Owning_Pointers.Handle_Operations (Owning_Handles);

   --  A recursive structure, to exercise Structural_Variant. The cell holds
   --  a handle to its successor, and the variant supplies the measure that
   --  makes the recursive definitions below terminate. Nothing in the cell
   --  records a length, so the variant is the only thing available.

   package List_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.Without_Weak_Handles;

   type List_Cell is record
      Value : Integer;
      Next  : aliased List_Handles.Handle;
   end record;

   package List_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Immutable (List_Cell);

   package List_Handle_Ops is new
     List_Pointers.Handle_Operations (List_Handles);

   function Id_Cell (C : List_Cell) return List_Cell is (C);
   function Create_Cell is new List_Pointers.Create (List_Cell, Id_Cell);

   function Cell_Next (O : not null access constant List_Cell)
     return access constant List_Handles.Handle
   is (O.Next'Access)
   with Global => null;

   package List_Variant is new
     List_Handle_Ops.Structural_Variant (Cell_Next);

   use type List_Pointers.Pointer;

   --  Two recursive definitions, both terminating on List_Variant.Weight

   function Valid_Chain (P : List_Pointers.Pointer) return Boolean
   is (P = List_Pointers.Null_Pointer
       or else
         (List_Handle_Ops.Valid_Handle
            (Cell_Next (List_Pointers.Constant_Reference (P)).all)
          and then Valid_Chain
                     (List_Handle_Ops.Of_Handle
                        (Cell_Next
                           (List_Pointers.Constant_Reference (P)).all))))
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => List_Variant.Weight (P));

   function Sum (P : List_Pointers.Pointer) return Big_Integer
   is (if P = List_Pointers.Null_Pointer
       then Big_Integer'(0)
       else To_Big_Integer (List_Pointers.Constant_Reference (P).Value)
            + Sum (List_Handle_Ops.Of_Handle
                     (Cell_Next
                        (List_Pointers.Constant_Reference (P)).all)))
   with
     Ghost              => Static,
     Global             => null,
     Pre                => Valid_Chain (P),
     Subprogram_Variant => (Decreases => List_Variant.Weight (P));

   --  The measure is a Static ghost function, but a client at any level can
   --  use it, including non-ghost code, by giving the variant at that level.

   function Count (P : List_Pointers.Pointer) return Big_Natural
   with
     Global             => null,
     Pre                => (Static => Valid_Chain (P)),
     Subprogram_Variant => (Static => (Decreases => List_Variant.Weight (P)));

   --  A node with a variable number of children, to exercise
   --  Multiway_Structural_Variant. Next returns null along a way the node
   --  does not have, which is what lets nodes differ in arity.

   package Tree_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.Without_Weak_Handles;

   subtype Way is Positive range 1 .. 3;

   type Child_Array is array (Way) of aliased Tree_Handles.Handle;

   type Tree_Node is record
      Value    : Integer;
      Arity    : Natural range 0 .. 3;
      Children : Child_Array;
   end record;

   package Tree_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Immutable (Tree_Node);

   package Tree_Handle_Ops is new
     Tree_Pointers.Handle_Operations (Tree_Handles);

   function Tree_Next (O : not null access constant Tree_Node; W : Way)
     return access constant Tree_Handles.Handle
   with Global => null;
   --  Null along a way the node does not have. SPARK requires 'Access to sit
   --  directly in a return statement, so this cannot be an expression
   --  function.

   package Tree_Variant is new
     Tree_Handle_Ops.Multiway_Structural_Variant (Way, Tree_Next);

   use type Tree_Pointers.Pointer;

   function Valid_Tree (P : Tree_Pointers.Pointer) return Boolean
   is (P = Tree_Pointers.Null_Pointer
       or else
         (for all W in Way =>
            (if Tree_Next (Tree_Pointers.Constant_Reference (P), W) /= null
             then
               Tree_Handle_Ops.Valid_Handle
                 (Tree_Next (Tree_Pointers.Constant_Reference (P), W).all)
               and then Valid_Tree
                          (Tree_Handle_Ops.Of_Handle
                             (Tree_Next
                                (Tree_Pointers.Constant_Reference (P),
                                 W).all)))))
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Tree_Variant.Weight (P));

end Inst;
