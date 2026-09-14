with SPARK.Containers.Functional.Sets;
package Inst with SPARK_Mode is
   function Equivalent (X, Y : Integer) return Boolean is (X mod 100 = Y mod 100);
   package Int_Sets is new SPARK.Containers.Functional.Sets
     (Integer, Equivalent_Elements => Equivalent);
end Inst;
