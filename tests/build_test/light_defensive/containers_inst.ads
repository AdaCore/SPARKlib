with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Functional.Multisets;
with SPARK.Containers.Functional.Sets;
with SPARK.Containers.Functional.Total_Maps;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Doubly_Linked_Lists;
with SPARK.Containers.Formal.Vectors;
with SPARK.Containers.Formal.Hashed_Sets;
with SPARK.Containers.Formal.Hashed_Maps;

--  Check that it is possible to instantiate the containers

package Containers_Inst with SPARK_Mode is

   --  Check that it is possible to instantiate functional containers

   package Seqs is new
     SPARK.Containers.Functional.Infinite_Sequences (Integer);
   package Maps is new SPARK.Containers.Functional.Maps (Integer, Integer);
   package Multisets is new SPARK.Containers.Functional.Multisets (Integer);
   package Sets is new SPARK.Containers.Functional.Sets (Integer);
   package Tmaps is new
     SPARK.Containers.Functional.Total_Maps (Integer, Integer, 0);
   package Vecs is new SPARK.Containers.Functional.Vectors (Positive, Integer);

   --  Check that it is possible to instantiate formal containers

   package Lists is new SPARK.Containers.Formal.Doubly_Linked_Lists (Integer);
   package Vectors is new SPARK.Containers.Formal.Vectors (Positive, Integer);

   function Hash (X : Positive) return Hash_Type is (Hash_Type (X));
   package H_Sets is new SPARK.Containers.Formal.Hashed_Sets (Positive, Hash);
   package H_Maps is new SPARK.Containers.Formal.Hashed_Maps
     (Positive, Integer, Hash);

end Containers_Inst;
