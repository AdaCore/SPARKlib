with Ada.Text_IO;
with SPARK.Lemmas.Float_Arithmetic;
with SPARK.Lemmas.Integer_Arithmetic;
with SPARK.Lemmas.Mod32_Arithmetic;
with Containers_Inst; use Containers_Inst;
with Pointers_Inst;

procedure Main with SPARK_Mode is

   --  Test whether SPARKlib_Defensive is enabled

   procedure Test_Defensive with Global => null;

   procedure Test_Defensive with SPARK_Mode => Off is
     L : Lists.List (10);
     E : Integer;
   begin
     Ada.Text_IO.Put_Line ("Assert_Failure should be raised if SPARKlib_Defensive is enabled and Constraint_Error should be raised otherwise");
     E := Lists.First_Element (L);
   end;
begin
   Test_Defensive;
end Main;
