with SPARK.Containers.Types; use SPARK.Containers.Types;
with Gen_Inst;

--  Unbounded containers are resized automatically when they grow. Test
--  the capability by inserting enough elements in a container.
--  Disable execution of full contracts because they are too slow here

procedure Test_Resize with SPARK_Mode is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);

   subtype Small_Positive is Short_Integer range 1 .. Short_Integer'Last;
   package Inst is new Gen_Inst (Small_Positive);
   use Inst.Int_Vectors;

   X : Vector;
begin
   for I in 1 .. 1000 loop
      Append (X, I);
      pragma Loop_Invariant (Length (X) = Count_Type (I));
   end loop;
end Test_Resize;
