with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst;
with Test_Gen;

procedure Test with SPARK_Mode is

   --  The computation of indexes in the implementation of vectors depends on
   --  whether Count_Type fits in the index type.

   procedure Test_Big_Indexes is new Test_Gen (Positive, Big_Inst);
   --  Count_Type fits in Integer

   procedure Test_Small_Indexes is new Test_Gen (Small_Positive, Small_Inst);
   --  But not in Short_Integer

begin
   Test_Big_Indexes;
   Test_Small_Indexes;
end Test;
