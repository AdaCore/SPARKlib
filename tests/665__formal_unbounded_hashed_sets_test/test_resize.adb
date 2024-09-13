with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst;
use Inst.Int_Sets;

--  Unbounded containers are resized automatically when they grow. Test
--  the capability by inserting enough elements in a container.

procedure Test_Resize with SPARK_Mode is
   X : Set;
begin
   for I in 1 .. 1000 loop
      Insert (X, I);
      pragma Loop_Invariant (Length (X) = Count_Type (I));
      pragma Loop_Invariant (for all K of X => K in 1 .. I);
   end loop;
end Test_Resize;
