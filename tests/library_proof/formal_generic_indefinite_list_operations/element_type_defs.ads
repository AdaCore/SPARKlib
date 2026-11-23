--  Opaque elements and uninterpreted comparisons for implementation proof.

package Element_Type_Defs with SPARK_Mode is
   type Element_Type is private;

   function "=" (Left, Right : Element_Type) return Boolean
   with Import, Global => null;

   procedure Eq_Reflexive (X : Element_Type)
   with Ghost => Static, Global => null, Post => X = X;

   procedure Eq_Symmetric (X, Y : Element_Type)
   with Ghost => Static, Global => null, Pre => X = Y, Post => Y = X;

   procedure Eq_Transitive (X, Y, Z : Element_Type)
   with Ghost => Static, Global => null,
     Pre => X = Y and Y = Z, Post => X = Z;

   procedure Equivalent_Reflexive (X, Y : Element_Type)
   with Ghost => Static, Global => null, Pre => X = Y, Post => X = Y;

   function "<" (Left, Right : Element_Type) return Boolean
   with Import, Global => null;

private
   pragma SPARK_Mode (Off);
   type Element_Type is new Integer;
end Element_Type_Defs;
