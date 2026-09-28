with Ada.Text_IO;
with System.Assertions; use System.Assertions;
with SPARK.Big_Integers;
with SPARK.Lemmas.Float_Arithmetic;
with SPARK.Lemmas.Integer_Arithmetic;
with SPARK.Lemmas.Mod32_Arithmetic;
with Containers_Inst; use Containers_Inst;
with Pointers_Inst;

procedure Main with SPARK_Mode is

   --  Test whether SPARKlib_Logic is enabled

   procedure Test_Logic with Global => null;

   procedure Test_Logic with SPARK_Mode => Off is
     use Lists.Formal_Model;
     use SPARK.Big_Integers;
     L : Lists.List (10);
   begin
     pragma Assert (SPARKlib_Logic => M.Length (Model (L)) /= 0);
     Ada.Text_IO.Put_Line ("SPARKlib_Logic:OFF");
   exception
     when Assert_Failure =>
       Ada.Text_IO.Put_Line ("SPARKlib_Logic:ON");
   end;

   --  Test whether SPARKlib_Defensive is enabled

   procedure Test_Defensive with Global => null;

   procedure Test_Defensive with SPARK_Mode => Off is
     L : Lists.List (10);
     E : Integer;
   begin
     E := Lists.First_Element (L);
   exception
     when Assert_Failure =>
       Ada.Text_IO.Put_Line ("SPARKlib_Defensive:ON");
     when Constraint_Error =>
       Ada.Text_IO.Put_Line ("SPARKlib_Defensive:OFF");
   end;
begin
   Test_Logic;
   Test_Defensive;
end Main;
