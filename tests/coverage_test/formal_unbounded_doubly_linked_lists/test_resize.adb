with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists;

--  Unbounded containers are resized automatically when they grow. Test
--  the capability by inserting enough elements in a container.
--  Disable execution of full contracts because they are too slow here

procedure Test_Resize with SPARK_Mode is
   pragma Assertion_Policy (SPARKlib_Full => Ignore);

   function Eq (X, Y : Integer) return Boolean is (X mod 1000 = Y mod 1000);
   package Int_Lists is new
     SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists
       (Integer, "=" => Eq);
   use Int_Lists;

   X : List;
begin
   for I in 1 .. 1000 loop
      Append (X, I);
      pragma Loop_Invariant (Length (X) = Count_Type (I));
   end loop;
end Test_Resize;
