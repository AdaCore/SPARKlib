with SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists;

package Inst with SPARK_Mode is
   function Eq (X, Y : Integer) return Boolean is (X mod 1000 = Y mod 1000);
   function Lt (X, Y : Integer) return Boolean is (X mod 1000 < Y mod 1000);
   package Int_Lists is new SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists
     (Integer, "=" => Eq);
   package Sorting is new Int_Lists.Generic_Sorting (Lt);
end Inst;
