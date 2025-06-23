with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Hashed_Sets;

package Inst with SPARK_Mode is
   function Witness (X : Natural) return Natural is (X mod 1000);
   function Hash (X : Natural) return Hash_Type is (Hash_Type (X mod 100));
   function Eq (X, Y : Natural) return Boolean is ((X mod 10000) = (Y mod 10000));
   function Equivalent (X, Y : Natural) return Boolean is (Witness (X) = Witness (Y));
   package Int_Sets is new SPARK.Containers.Formal.Unbounded_Hashed_Sets (Natural, Hash, Equivalent, Eq);

   subtype Key_Type is Natural range 0 .. 999;
   function Hash_Key (X : Key_Type) return Hash_Type is (Hash_Type (X mod 100));
   package Int_Sets_Keys is new Int_Sets.Generic_Keys (Key_Type, Witness, Hash_Key, "=");
end Inst;
