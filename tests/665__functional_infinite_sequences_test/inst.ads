with SPARK.Containers.Functional.Infinite_Sequences;
package Inst with SPARK_Mode is
   function Equal (X, Y : Integer) return Boolean is (X mod 100 = Y mod 100);
   function Equivalent (X, Y : Integer) return Boolean is (X mod 10 = Y mod 10);
   package Int_Sequences is new SPARK.Containers.Functional.Infinite_Sequences
     (Integer, "=" => Equal, Equivalent_Elements => Equivalent);
end Inst;
