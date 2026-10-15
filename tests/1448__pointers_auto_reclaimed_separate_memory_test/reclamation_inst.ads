pragma Extensions_Allowed (On);

with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Auto_Reclaimed.Separate_Memory;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;

--  Fixtures for observing reclamation effects outside the logical model

package Reclamation_Inst
  with SPARK_Mode => Off
is

   type Int_Acc is access Integer;

   type Owning_Object is record
      D : Int_Acc;
   end record;

   procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Acc);

   procedure Reclaim (X : in out Owning_Object);

   package Owning_Pointers is new
     SPARK.Pointers.Auto_Reclaimed.Separate_Memory (Owning_Object, Reclaim);

   function Copy_Owning (O : Owning_Object) return Owning_Object
   is (D => (if O.D = null then null else new Integer'(O.D.all)));

   package Owning_Ops is new Owning_Pointers.Copy_Operations (Copy_Owning);

   function Make (V : Integer) return Owning_Object
   is (D => new Integer'(V));

   procedure Create_Owning is new Owning_Pointers.Create (Integer, Make);

   use Owning_Pointers;

   package Owning_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;

   package Owning_Handle_Ops is new
     Owning_Pointers.Handle_Operations (Owning_Handles);

end Reclamation_Inst;
