pragma Ignore_Pragma (Assertion_Policy);
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Hashed_Maps;

package Inst with SPARK_Mode is
   function Witness (X : Natural) return Natural is (X mod 1000);
   function Hash (X : Natural) return Hash_Type is (Hash_Type (X mod 100));
   function Eq (X, Y : Integer) return Boolean is ((X mod 1000) = (Y mod 1000));
   function Equivalent (X, Y : Natural) return Boolean is (Witness (X) = Witness (Y));
   package Int_Maps is new SPARK.Containers.Formal.Hashed_Maps (Natural, Integer, Hash, Equivalent, Eq);
end Inst;
