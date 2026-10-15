pragma Extensions_Allowed (On);
--  Clients of the reference-counted units have to enable extensions
--  themselves: the instantiation re-elaborates a private part which uses the
--  GNAT-specific Finalizable aspect.

with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Auto_Reclaimed.Global_Memory;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;

package Reclamation_Inst
  with SPARK_Mode => Off
is

   --  A designated object subject to ownership. Reclaim frees the cell and
   --  bumps a counter, so the test can observe that the library reclaims,
   --  both when a cell is overwritten by Assign and when the last pointer to
   --  it disappears.

   type Int_Acc is access Integer;

   type Owning_Object is record
      D : Int_Acc;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Acc);

   procedure Reclaim (X : in out Owning_Object);

   package Owning_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Global_Memory (Owning_Object, Reclaim);

   function Copy_Owning (O : Owning_Object) return Owning_Object
   with
     Post =>
       ((O.D = null) = (Copy_Owning'Result.D = null))
       and (if O.D /= null then Copy_Owning'Result.D.all = O.D.all);
   --  The designated object owns a cell, so copying it has to duplicate that
   --  cell. Deref therefore hands out a value the caller owns and must free.

   package Owning_Ops is new Owning_Pointers.Copy_Operations (Copy_Owning);

   function Make (V : Integer) return Owning_Object
   is (D => new Integer'(V));

   procedure Create_Owning is new Owning_Pointers.Create (Integer, Make);

   --  Handles over the owning pointers, in the flavour that has weak handles.
   --  Owning_Pointers has to be use-visible at the instantiation, or the
   --  Proof_In of Of_Live_Weak_Handle does not resolve. Only Owning_Pointers
   --  is used here, so nothing below becomes ambiguous.

   use Owning_Pointers;

   package Owning_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;

   package Owning_Handle_Ops is new
     Owning_Pointers.Handle_Operations (Owning_Handles);

   --  Pointers that can be used to create a cycle made of a weak and a strong
   --  handle.

   package Cyclic_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;

   type Cell is record
      Value : Int_Acc;
      Next  : Cyclic_Handles.Strong_Handle;
      Prev  : Cyclic_Handles.Weak_Handle;
   end record;

   procedure Reclaim (X : in out Cell);

   package Cyclic_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Global_Memory (Cell, Reclaim);

   use Cyclic_Pointers;

   package Cyclic_Handle_Ops is new
     Cyclic_Pointers.Handle_Operations (Cyclic_Handles);
   use Cyclic_Handle_Ops;

   function Make (V : Integer) return Cell
   is (Value => new Integer'(V),
       Next  => To_Strong_Handle (Cyclic_Pointers.Null_Pointer),
       Prev  => To_Weak_Handle (Cyclic_Pointers.Null_Pointer));

   procedure Create_Cell is new Cyclic_Pointers.Create (Integer, Make);

   function Copy_Cell (O : Cell) return Cell
   with
     Post =>
       (Static =>
          (Valid_Handle (O.Prev) = Valid_Handle (Copy_Cell'Result.Prev))
          and (if Valid_Handle (O.Prev) then Copy_Cell'Result.Prev = O.Prev)
          and (Valid_Handle (O.Next) = Valid_Handle (Copy_Cell'Result.Next))
          and (if Valid_Handle (O.Next) then Copy_Cell'Result.Next = O.Next)
          and ((O.Value = null) = (Copy_Cell'Result.Value = null))
          and
            (if O.Value /= null
             then Copy_Cell'Result.Value.all = O.Value.all));

   package Cyclic_Ops is new Cyclic_Pointers.Copy_Operations (Copy_Cell);

end Reclamation_Inst;
