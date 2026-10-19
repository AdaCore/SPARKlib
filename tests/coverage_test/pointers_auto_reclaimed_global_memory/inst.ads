pragma Extensions_Allowed (On);

with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Auto_Reclaimed.Global_Memory;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;

package Inst
  with SPARK_Mode
is

   type Plain_Object is record
      F : Integer;
      G : Integer;
   end record;

   package Plain_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Global_Memory (Plain_Object);

   package Plain_Ops is new Plain_Pointers.Copy_Operations;

   function Make_Plain (V : Integer) return Plain_Object
   is (F => V, G => 0);

   procedure Create_Plain is new Plain_Pointers.Create (Integer, Make_Plain);

   --  Each copy owns a separate integer; reclamation has no global effects

   type Int_Acc is access Integer;

   type Owning_Object is record
      D : Int_Acc;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Acc);

   procedure Reclaim (X : in out Owning_Object)
   with Global => null, Always_Terminates, Post => X.D = null;

   package Owning_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Global_Memory (Owning_Object, Reclaim);

   function Copy_Owning (O : Owning_Object) return Owning_Object
   with
     Global => null,
     Post   =>
       ((O.D = null) = (Copy_Owning'Result.D = null))
       and (if O.D /= null then Copy_Owning'Result.D.all = O.D.all);

   package Owning_Ops is new Owning_Pointers.Copy_Operations (Copy_Owning);

   function Make (V : Integer) return Owning_Object
   is (D => new Integer'(V));

   procedure Create_Owning is new Owning_Pointers.Create (Integer, Make);

   use Owning_Pointers;

   package Owning_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;

   package Owning_Handle_Ops is new
     Owning_Pointers.Handle_Operations (Owning_Handles);

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

   --  Strong forward edges and weak back edges permit automatic reclamation

   package Cyclic_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;

   type Cell is record
      Value : Integer;
      Next  : Cyclic_Handles.Strong_Handle;
      Prev  : Cyclic_Handles.Weak_Handle;
   end record;

   package Cyclic_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Global_Memory (Cell);

   use Cyclic_Pointers;

   package Cyclic_Handle_Ops is new
     Cyclic_Pointers.Handle_Operations (Cyclic_Handles);

   use Cyclic_Handle_Ops;

   function Make_Cell (V : Integer) return Cell
   is (Value => V,
       Next  => To_Strong_Handle (Cyclic_Pointers.Null_Pointer),
       Prev  => To_Weak_Handle (Cyclic_Pointers.Null_Pointer));

   procedure Create_Cell is new Cyclic_Pointers.Create (Integer, Make_Cell);

   package Cyclic_Ops is new Cyclic_Pointers.Copy_Operations;

end Inst;
