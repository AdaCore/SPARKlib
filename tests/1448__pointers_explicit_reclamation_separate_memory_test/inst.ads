with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Explicit_Reclamation.Separate_Memory;

package Inst
  with SPARK_Mode
is

   type Object is record
      F : Integer;
      G : Integer;
   end record;

   package Pointers is new
     SPARK.Pointers.Explicit_Reclamation.Separate_Memory (Object);

   package Ops is new Pointers.Copy_Operations;

   --  The standalone allocator, which builds the object from an Input rather
   --  than copying an existing one.

   package Owning is
      type Int_Access is access Integer;
      type Object is record
         D : Int_Access;
      end record;

      function Is_Reclaimed (O : Object) return Boolean
      is (O.D = null)
      with Ghost => Static;

      procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Access);

      package Pointers is new
        SPARK.Pointers.Explicit_Reclamation.Separate_Memory
          (Object,
           Is_Reclaimed);

      function Copy (O : Object) return Object
      with
        Global => null,
        Post   =>
          ((O.D = null) = (Copy'Result.D = null))
          and then (if O.D /= null then Copy'Result.D.all = O.D.all);

      package Ops is new Pointers.Copy_Operations (Copy);
   end Owning;

   subtype Input_Value is Integer range Integer'First .. Integer'Last - 1;
   function Make (V : Input_Value) return Object
   is (F => V, G => V + 1);
   procedure Create_From_Int is new Pointers.Create (Input_Value, Make);

end Inst;
