--  Instantiation that drives the analysis of the implementation generic.
--  gnatprove analyses every operation of an instantiated generic, so the
--  instantiation below is enough to check the whole implementation; no calling
--  code is needed.

with SPARK.Containers.Formal.Doubly_Linked_Lists;
with SPARK.Containers.Formal.Doubly_Linked_Lists.Public_Impl;
with Element_Type_Defs; use Element_Type_Defs;

package Test_Instances with SPARK_Mode is

   package Lists is new
     SPARK.Containers.Formal.Doubly_Linked_Lists
       (Element_Type, "=", Eq_Reflexive, Eq_Symmetric, Eq_Transitive);

   package Lists_Impl is new Lists.Public_Impl;

end Test_Instances;
