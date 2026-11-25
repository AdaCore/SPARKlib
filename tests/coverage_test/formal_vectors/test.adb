with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst;
with Test_Gen;
with Gen_Inst;

procedure Test with SPARK_Mode is

   --  The computation of indexes in the implementation of vectors depends on
   --  whether Count_Type fits in the index type.

   subtype Wide_Positive is Long_Long_Integer range 1 .. Long_Long_Integer'Last;
   package Wide_Inst is new Gen_Inst (Wide_Positive);

   procedure Test_Wide_Indexes is new Test_Gen (Wide_Positive, Wide_Inst);
   --  Count_Type fits in Wide_Positive

   procedure Test_Small_Indexes is new Test_Gen (Small_Positive, Small_Inst);
   --  But not in Short_Integer

begin
   Test_Wide_Indexes;
   Test_Small_Indexes;
end Test;
