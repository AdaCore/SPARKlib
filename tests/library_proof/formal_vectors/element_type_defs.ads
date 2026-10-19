--  Element type for instantiating SPARK.Containers.Formal.Vectors.Impl in the
--  proof test. It is a private type whose full view is hidden from SPARK
--  analysis (the private part is SPARK_Mode => Off), and "=" and "<" are
--  imported functions with no contracts. This gives the implementation an
--  opaque element type and uninterpreted comparison operators, so the proof
--  cannot rely on any property of the element type beyond what the contracts
--  state.

package Element_Type_Defs with SPARK_Mode is

   type Element_Type is private;

   function "=" (Left, Right : Element_Type) return Boolean
   with Import, Global => null;

   procedure Eq_Reflexive (X : Element_Type)
     with Ghost => Static, Global => null, Post => X = X;

   procedure Eq_Symmetric (X, Y : Element_Type)
     with Ghost => Static, Global => null, Pre => X = Y, Post => Y = X;

   procedure Eq_Transitive (X, Y, Z : Element_Type)
     with Ghost => Static, Global => null, Pre => X = Y and Y = Z, Post => X = Z;

   function "<" (Left, Right : Element_Type) return Boolean
   with Import, Global => null;

private
   pragma SPARK_Mode (Off);

   type Element_Type is new Integer;

end Element_Type_Defs;
