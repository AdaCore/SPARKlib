--  Element types for the holders of class-wide values

package Shapes
  with SPARK_Mode
is

   type Shape is tagged record
      X, Y : Integer;
   end record;

   type Circle is new Shape with record
      Radius : Natural;
   end record;

   function Same_Position (Left, Right : Shape'Class) return Boolean
   is (Left.X = Right.X and then Left.Y = Right.Y);
   --  Equivalence used as the "=" parameter of the holders of Shape'Class.
   --  The predefined equality on Shape'Class dispatches to the equality of
   --  the specific type, so GNATprove can show neither that it terminates
   --  nor that it is an equivalence relation.

end Shapes;
