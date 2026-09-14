with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst_Gen;

--  Unbounded containers are resized automatically when they grow. Test
--  the capability by inserting enough elements in a container.
--  Disable execution of contracts on this test as their prohibitively slow.

procedure Test_Resize with SPARK_Mode is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);
   package Inst is new Inst_Gen (100);
   use Inst;
   use Inst.Int_Sets;
   X : Set;
begin
   for I in 1 .. 1000 loop
      Insert (X, I);
      pragma Loop_Invariant (Length (X) = Count_Type (I));
      pragma Loop_Invariant (for all K of X => K in 1 .. I);
   end loop;
end Test_Resize;
