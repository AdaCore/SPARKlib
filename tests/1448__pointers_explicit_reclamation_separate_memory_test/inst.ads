with SPARK.Pointers.Explicit_Reclamation.Separate_Memory;

package Inst with SPARK_Mode is

   type Object is record
      F : Integer;
      G : Integer;
   end record;

   package Pointers is new
     SPARK.Pointers.Explicit_Reclamation.Separate_Memory (Object);

   package Ops is new Pointers.Copy_Operations;

   --  The standalone allocator, which builds the object from an Input rather
   --  than copying an existing one.

   function Make (V : Integer) return Object is (F => V, G => V + 1);
   procedure Create_From_Int is new Pointers.Create (Integer, Make);

end Inst;
