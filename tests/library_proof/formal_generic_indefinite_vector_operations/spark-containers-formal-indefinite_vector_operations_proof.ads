pragma Ada_2022;

with Index_Types;       use Index_Types;
with Element_Type_Defs; use Element_Type_Defs;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Functional.Vectors;
with SPARK.Containers.Formal.Generic_Indefinite_Vector_Operations;
with SPARK.Containers.Formal.Generic_Vector_Storage;
with SPARK.Pointers.Poisoned.Pointers;

--  Mirror the storage and operations instances for Unbounded_Vectors so their
--  bodies can be proved separately from its controlled implementation.

private package SPARK.Containers.Formal.Indefinite_Vector_Operations_Proof
  with SPARK_Mode
is
   pragma Unevaluated_Use_Of_Old (Allow);

   generic
      type Index_Type is range <>;
   package Instance is
      No_Index   : constant Index_Type'Base := Index_Type'First - 1;
      Last_Count : constant Count_Type :=
        (if Index_Type'Last < Index_Type'First
         then 0
         elsif (if Index_Type'First > 0
                then
                  Index_Type'Pos (Index_Type'Last)
                  - Index_Type'Pos (Index_Type'First)
                  < Count_Type'Pos (Count_Type'Last)
                else
                  Index_Type'Pos (Index_Type'Last)
                  < Count_Type'Pos (Count_Type'Last)
                    + Index_Type'Pos (Index_Type'First))
         then
           Count_Type'Val
             (Index_Type'Pos (Index_Type'Last)
              - Index_Type'Pos (Index_Type'First) + 1)
         else Count_Type'Last);

      package Formal_Model
        with Ghost => SPARKlib_Logic
      is
         package M is new
           SPARK.Containers.Functional.Vectors (Index_Type, Element_Type,
              Eq_Reflexive                  => Eq_Reflexive,
              Eq_Symmetric                  => Eq_Symmetric,
              Eq_Transitive                 => Eq_Transitive,
              Equivalent_Elements_Reflexive  => Equivalent_Reflexive,
              Equivalent_Elements_Symmetric  => Eq_Symmetric,
              Equivalent_Elements_Transitive => Eq_Transitive);
      end Formal_Model;

      package Cells is new SPARK.Pointers.Poisoned.Pointers (Element_Type);
      package Storage is new
        SPARK.Containers.Formal.Generic_Vector_Storage
          (Last_Count  => Last_Count,
           Index_Type  => Index_Type,
           No_Index    => No_Index,
           Holder_Type => Cells.Pointer);
      package Indefinite_Ops is new
        SPARK.Containers.Formal.Generic_Indefinite_Vector_Operations
          (Last_Count   => Last_Count,
           Index_Type   => Index_Type,
           No_Index     => No_Index,
           Element_Type => Element_Type,
           "="          => "=",
           Cells        => Cells,
           Storage      => Storage);
      package Sorting is new Indefinite_Ops.Ops.Generic_Sorting;
      package Vector_Model is new
        Indefinite_Ops.Ops.Generic_Model (Formal_Model.M);
      package Model_Sorting is new Vector_Model.Generic_Sorting;
   end Instance;

   package Big_Vectors is new Instance (Big_Index);
   package Small_Vectors is new Instance (Small_Index);
end SPARK.Containers.Formal.Indefinite_Vector_Operations_Proof;
