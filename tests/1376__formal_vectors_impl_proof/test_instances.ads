--  Instantiations that drive the analysis of the implementation generic
--  SPARK.Containers.Formal.Vectors.Impl. Since Impl is a private child it
--  cannot be named here directly; each parent Formal.Vectors instance is paired
--  with a Public_Impl instance, which instantiates Impl (and its nested
--  Generic_Sorting) internally. gnatprove analyses every operation of an
--  instantiated generic, so the two instantiations below are enough to check
--  (and ultimately prove) the whole implementation; no calling code is needed.

with SPARK.Containers.Formal.Vectors;
with SPARK.Containers.Formal.Vectors.Public_Impl;
with Element_Type_Defs; use Element_Type_Defs;
with Index_Types;       use Index_Types;

package Test_Instances with SPARK_Mode is

   package Big_Vectors is new
     SPARK.Containers.Formal.Vectors (Big_Index, Element_Type, "=", Eq_Reflexive, Eq_Symmetric, Eq_Transitive);

   package Big_Vectors_Impl is new Big_Vectors.Public_Impl;

   package Small_Vectors is new
     SPARK.Containers.Formal.Vectors (Small_Index, Element_Type, "=", Eq_Reflexive, Eq_Symmetric, Eq_Transitive);

   package Small_Vectors_Impl is new Small_Vectors.Public_Impl;

end Test_Instances;
