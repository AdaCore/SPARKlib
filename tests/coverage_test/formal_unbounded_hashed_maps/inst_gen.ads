with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Hashed_Maps;

generic
   Modulus : Positive;
package Inst_Gen with SPARK_Mode is
   pragma Compile_Time_Error (1000 mod Modulus /= 0, "Modulus is incompatible with equality");
   function Witness (X : Natural) return Natural is (X mod 1000);
   function Hash (X : Natural) return Hash_Type is (Hash_Type (X mod Modulus));
   function Eq (X, Y : Integer) return Boolean is ((X mod 1000) = (Y mod 1000));
   function Equivalent (X, Y : Natural) return Boolean is (Witness (X) = Witness (Y));
   package Int_Maps is new SPARK.Containers.Formal.Unbounded_Hashed_Maps (Natural, Integer, Hash, Equivalent, Eq);
end Inst_Gen;
