with SPARK.Containers.Functional.Maps;
package Inst with SPARK_Mode is
   function Eq (X, Y : Integer) return Boolean is (X mod 1000 = Y mod 1000);
   function Equivalent (X, Y : Integer) return Boolean is (X mod 100 = Y mod 100);
   package Int_Maps is new SPARK.Containers.Functional.Maps
     (Integer, Integer, Equivalent_Keys => Equivalent, "=" => Eq, Equivalent_Elements => Equivalent);
end Inst;
