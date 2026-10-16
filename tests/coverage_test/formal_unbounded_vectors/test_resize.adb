with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst;
with Test_Gen;

procedure Test_Resize with SPARK_Mode is

   --  Unbounded containers are resized automatically when they grow. Test
   --  the capability by inserting enough elements in a container.

   procedure Test_Resize_Big with Pre => True is
      use Big_Inst.Int_Vectors;
      X : Vector;
   begin
      for I in 1 .. 1000 loop
         Append (X, I);
         pragma Loop_Invariant (Length (X) = Count_Type (I));
      end loop;
   end Test_Resize_Big;

   procedure Test_Resize_Small with Pre => True is
      use Small_Inst.Int_Vectors;
      X : Vector;
   begin
      for I in 1 .. 1000 loop
         Append (X, I);
         pragma Loop_Invariant (Length (X) = Count_Type (I));
      end loop;
   end Test_Resize_Small;

begin
   Test_Resize_Big;
   Test_Resize_Small;
end Test_Resize;
