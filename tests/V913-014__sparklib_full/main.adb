with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Maps;
with SPARK.Containers.Functional.Multisets;
with SPARK.Containers.Functional.Sets;
with SPARK.Containers.Functional.Vectors;
with SPARK.Lemmas.Float_Arithmetic;

with SPARK.Containers.Formal.Doubly_Linked_Lists;
with SPARK.Containers.Formal.Vectors;
with SPARK.Containers.Formal.Hashed_Maps;
with SPARK.Containers.Formal.Hashed_Sets;
with SPARK.Containers.Formal.Ordered_Maps;
with SPARK.Containers.Formal.Ordered_Sets;
with SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists;
with SPARK.Containers.Formal.Unbounded_Vectors;
with SPARK.Containers.Formal.Unbounded_Hashed_Maps;
with SPARK.Containers.Formal.Unbounded_Hashed_Sets;
with SPARK.Containers.Formal.Unbounded_Ordered_Maps;
with SPARK.Containers.Formal.Unbounded_Ordered_Sets;

with SPARK.Containers.Types; use SPARK.Containers.Types;

procedure Main with SPARK_Mode is

   function Hash (I : Integer) return Hash_Type is
      (SPARK.Containers.Types.Hash_Type'Mod (I));

   --  Check that it is possible to instantiate functional containers

   package Seqs is new
     SPARK.Containers.Functional.Infinite_Sequences (Integer);
   package Maps is new SPARK.Containers.Functional.Maps (Integer, Integer);
   package Multisets is new SPARK.Containers.Functional.Multisets (Integer);
   package Sets is new SPARK.Containers.Functional.Sets (Integer);
   package Vecs is new SPARK.Containers.Functional.Vectors (Positive, Integer);

   --  Check that it is possible to instantiate formal containers

   package Lists is new SPARK.Containers.Formal.Doubly_Linked_Lists (Integer);
   package Vectors is new SPARK.Containers.Formal.Vectors (Positive, Integer);
   package Hashed_Maps is new
     SPARK.Containers.Formal.Hashed_Maps (Integer, Integer, Hash);
   package Hashed_Sets is new
     SPARK.Containers.Formal.Hashed_Sets (Integer, Hash);
   package Ordered_Maps is new
     SPARK.Containers.Formal.Ordered_Maps (Integer, Integer);
   package Ordered_Sets is new
     SPARK.Containers.Formal.Ordered_Sets (Integer);
   package Unb_Lists is new
     SPARK.Containers.Formal.Unbounded_Doubly_Linked_Lists (Integer);
   package Unb_Vectors is new
     SPARK.Containers.Formal.Unbounded_Vectors (Positive, Integer);
   package Unb_Hashed_Maps is new
     SPARK.Containers.Formal.Unbounded_Hashed_Maps (Integer, Integer, Hash);
   package Unb_Hashed_Sets is new
     SPARK.Containers.Formal.Unbounded_Hashed_Sets (Integer, Hash);
   package Unb_Ordered_Maps is new
     SPARK.Containers.Formal.Unbounded_Ordered_Maps (Integer, Integer);
   package Unb_Ordered_Sets is new
     SPARK.Containers.Formal.Unbounded_Ordered_Sets (Integer);
begin
   null;
end Main;
