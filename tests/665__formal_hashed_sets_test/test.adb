with Test_Gen;
procedure Test with SPARK_Mode is

   --  A formal hashed set is implemented as several set structures inside a
   --  single array of values. They contain elements corresponding to the same
   --  hash modulo the number of buckets (aka modulus) in the structure. The
   --  head of these sets are stored in a separate array for easier access.
   --  We run the tests twice, once in a structure without collisions and one
   --  in a structure with a lot of collisions.

   procedure Test_No_Collisions is new Test_Gen (100);

   --  Disable proof on the second instance, as the implementation is not
   --  relevant for proof.

   package Nested with Annotate => (GNATprove, Skip_Proof) is
      procedure Test_With_Collisions is new Test_Gen (2);
   end Nested;

begin
   Test_No_Collisions;
   Nested.Test_With_Collisions;
end Test;
