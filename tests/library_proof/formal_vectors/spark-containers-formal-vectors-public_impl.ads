--  Test-only child that exposes the private implementation child
--  SPARK.Containers.Formal.Vectors.Impl for instantiation. Impl is a private
--  child of Formal.Vectors, so a client (here, Test_Instances) cannot name it;
--  this Public_Impl child "private with"s Impl and instantiates it (and its
--  nested Generic_Sorting) in its own private part, giving the proof test a
--  handle on the implementation without widening the public API.

pragma Ada_2022;

private with SPARK.Containers.Formal.Vectors.Impl;

generic
   with function "<" (Left, Right : Element_Type) return Boolean is <>;
package SPARK.Containers.Formal.Vectors.Public_Impl with SPARK_Mode
is
private
   package Impl is new SPARK.Containers.Formal.Vectors.Impl;
   package Sorting is new Impl.Generic_Sorting ("<");
end SPARK.Containers.Formal.Vectors.Public_Impl;
