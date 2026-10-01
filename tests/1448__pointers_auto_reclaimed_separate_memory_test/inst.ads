pragma Extensions_Allowed (On);
--  Clients of the reference-counted units have to enable extensions
--  themselves: the instantiation re-elaborates a private part which uses the
--  GNAT-specific Finalizable aspect.

with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Auto_Reclaimed.Separate_Memory;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;

--  Execution test for SPARK.Pointers.Auto_Reclaimed.Separate_Memory, the
--  counterpart of 1448__pointers_auto_reclaimed_global_memory_test. Same unit but
--  with the memory as an object, so every operation takes one.

package Inst with SPARK_Mode is

   --  A plain designated object

   type Plain_Object is record
      F : Integer;
      G : Integer;
   end record;

   package Plain_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Separate_Memory (Plain_Object);

   package Plain_Ops is new Plain_Pointers.Copy_Operations;

   --  A designated object subject to ownership. Reclaim frees the cell and
   --  bumps a counter, so the test can observe that the library reclaims,
   --  both when a cell is overwritten by Assign and when the last pointer to
   --  it disappears.

   type Int_Acc is access Integer;

   type Owning_Object is record
      D : Int_Acc;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Acc);

   procedure Reclaim (X : in out Owning_Object)
   with Global => null, Always_Terminates, Post => X.D = null;

   package Owning_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Separate_Memory (Owning_Object, Reclaim);

   function Copy_Owning (O : Owning_Object) return Owning_Object
   is (D => new Integer'(O.D.all))
   with Pre => O.D /= null;
   --  The designated object owns a cell, so copying it has to duplicate that
   --  cell. Deref therefore hands out a value the caller owns and must free.

   package Owning_Ops is new Owning_Pointers.Copy_Operations (Copy_Owning);

   function Make (V : Integer) return Owning_Object
   is (D => new Integer'(V));

   procedure Create_Owning is new Owning_Pointers.Create (Integer, Make);

   --  The standalone allocator over the plain object too, so Create is
   --  covered as well as Create_Copy.

   function Make_Plain (V : Integer) return Plain_Object is (F => V, G => V + 1);
   procedure Create_From_Int is new
     Plain_Pointers.Create (Integer, Make_Plain);

   --  Handles over the owning pointers, in the flavour that has weak handles.
   --  Owning_Pointers has to be use-visible at the instantiation, or the
   --  Proof_In of Of_Live_Weak_Handle does not resolve. Only Owning_Pointers
   --  is used here, so nothing below becomes ambiguous.

   use Owning_Pointers;

   package Owning_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;

   package Owning_Handle_Ops is new
     Owning_Pointers.Handle_Operations (Owning_Handles);

   --  A witnessed instantiation, in its canonical form: the client hands over
   --  the pointer it is already holding, and Witness is the identity. Holding
   --  that pointer is what keeps the cell alive, so the upgrade cannot fail.

   use Owning_Handles;
   use Owning_Handle_Ops;

   function Has_Witness (P : Pointer; X : Pointer) return Boolean
   is (X = P)
   with Ghost => Static;

   function Witness (H : Weak_Handle; X : Pointer) return Pointer
   is (X)
   with
     Pre  =>
       (SPARKlib_Full => Valid_Handle (H),
        Static        => Has_Witness (Peek (H), X)),
     Post => (Static => Peek (H) = Witness'Result);

   package Owning_Live_Ops is new
     Owning_Handle_Ops.Witnessed_Conversions (Pointer, Has_Witness, Witness);

end Inst;
