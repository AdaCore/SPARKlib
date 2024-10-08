pragma Ignore_Pragma (Assertion_Policy);
with SPARK.Containers.Formal.Vectors;

generic
  type Index_Type is range <>;
package Gen_Inst with SPARK_Mode is
   function Eq (X, Y : Integer) return Boolean is (X mod 1000 = Y mod 1000);
   function Lt (X, Y : Integer) return Boolean is (X mod 1000 < Y mod 1000);
   package Int_Vectors is new SPARK.Containers.Formal.Vectors
     (Index_Type, Integer, "=" => Eq);
   package Sorting is new Int_Vectors.Generic_Sorting (Lt);
end Gen_Inst;
