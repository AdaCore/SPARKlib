with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Hashed_Sets;

generic
   Modulus : Positive;
package Inst_Gen with SPARK_Mode is
   pragma Compile_Time_Error (1000 mod Modulus /= 0, "Modulus is incompatible with equality");
   function Hash (X : Natural) return Hash_Type is (Hash_Type (X mod Modulus));
   function Witness (X : Natural) return Natural is (X mod 1000);
   function Eq (X, Y : Natural) return Boolean is ((X mod 10000) = (Y mod 10000));
   function Equivalent (X, Y : Natural) return Boolean is (Witness (X) = Witness (Y));
   package Int_Sets is new SPARK.Containers.Formal.Hashed_Sets (Natural, Hash, Equivalent, Eq);

   subtype Key_Type is Natural range 0 .. 999;
   function Hash_Key (X : Key_Type) return Hash_Type is (Hash_Type (X mod Modulus));
   package Int_Sets_Keys is new Int_Sets.Generic_Keys (Key_Type, Witness, Hash_Key, "=");
end Inst_Gen;
