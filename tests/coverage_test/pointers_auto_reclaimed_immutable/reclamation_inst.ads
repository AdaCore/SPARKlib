pragma Extensions_Allowed (On);

with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Auto_Reclaimed.Immutable;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;

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
     SPARK.Pointers.Auto_Reclaimed.Immutable (Owning_Object, Reclaim);

   function Make (V : Integer) return Owning_Object
   is (D => new Integer'(V));

   function Create_Owning is new Owning_Pointers.Create (Integer, Make);

   package Owning_Handles is new
     SPARK.Pointers.Handles.Auto_Reclaimed_Handles.Without_Weak_Handles;

   package Owning_Handle_Ops is new
     Owning_Pointers.Handle_Operations (Owning_Handles);

end Reclamation_Inst;
