with SPARK.Containers.Formal.Unbounded_Holders;

--  Clients of holders of strings and of class-wide values. Their proof relies
--  only on the contracts of the holders.

package Clients
  with SPARK_Mode
is
   pragma Unevaluated_Use_Of_Old (Allow);

   ------------------------
   -- Holders of strings --
   ------------------------

   package String_Holders is new
     SPARK.Containers.Formal.Unbounded_Holders (String);
   use String_Holders;

   function Name_Or (H : Holder; Default : String) return String
   with
     Post =>
       (if Is_Empty (H)
        then Name_Or'Result = Default
        else Name_Or'Result = Element (H));

   function Name_Length (H : Holder) return Natural
   with
     Pre  => not Is_Empty (H),
     Post => Name_Length'Result = Element (H)'Length;
   --  Compute the length of the element without copying it

   procedure Set_Name (H : in out Holder; Name : String)
   with Post => not Is_Empty (H) and then Element (H) = Name;

   procedure Set_First (H : in out Holder; C : Character)
   with
     Pre  => not Is_Empty (H) and then Element (H)'Length > 0,
     Post =>
       not Is_Empty (H)
       and then Element (H)'First = Element (H)'Old'First
       and then Element (H)'Last = Element (H)'Old'Last
       and then Element (H) (Element (H)'First) = C
       and then
         (for all I in Element (H)'Range =>
            (if I /= Element (H)'First
             then Element (H) (I) = Element (H)'Old (I)));
   --  Update the first character of the element in place

   procedure Duplicate (Source : Holder; Target : out Holder)
   with Post => Target = Source;

   procedure Rotate (A, B, C : in out Holder)
   with
     Post =>
       Is_Empty (A) = Is_Empty (C)'Old
       and Is_Empty (B) = Is_Empty (A)'Old
       and Is_Empty (C) = Is_Empty (B)'Old;
   --  Move the contents of A to B, of B to C, and of C to A

   ----------------------------------
   -- Holders of class-wide values --
   ----------------------------------

   type Shape is tagged record
      X, Y : Integer;
   end record;

   type Circle is new Shape with record
      Radius : Natural;
   end record;

   function Same_Position (Left, Right : Shape'Class) return Boolean
   is (Left.X = Right.X and then Left.Y = Right.Y);

   package Shape_Holders is new
     SPARK.Containers.Formal.Unbounded_Holders (Shape'Class, Same_Position);

   function Is_Circle (H : Shape_Holders.Holder) return Boolean
   is (not Shape_Holders.Is_Empty (H)
       and then Shape_Holders.Element (H) in Circle);

   function Radius (H : Shape_Holders.Holder) return Natural
   with
     Pre  => Is_Circle (H),
     Post => Radius'Result = Circle (Shape_Holders.Element (H)).Radius;

   procedure Translate (H : in out Shape_Holders.Holder; DX : Integer)
   with
     Pre  =>
       not Shape_Holders.Is_Empty (H)
       and then
         (if DX > 0
          then Shape_Holders.Element (H).X <= Integer'Last - DX
          else Shape_Holders.Element (H).X >= Integer'First - DX),
     Post =>
       not Shape_Holders.Is_Empty (H)
       and then
         Shape_Holders.Element (H).X = Shape_Holders.Element (H)'Old.X + DX
       and then Shape_Holders.Element (H).Y = Shape_Holders.Element (H)'Old.Y
       and then
         (Shape_Holders.Element (H) in Circle)
         = (Shape_Holders.Element (H)'Old in Circle);
   --  Move the shape held by H, keeping its specific type

   procedure Translate_In_Place (H : in out Shape_Holders.Holder; DX : Integer)
   with
     Pre            =>
       not Shape_Holders.Is_Empty (H)
       and then
         (if DX > 0
          then Shape_Holders.Element (H).X <= Integer'Last - DX
          else Shape_Holders.Element (H).X >= Integer'First - DX),
     Post           =>
       not Shape_Holders.Is_Empty (H)
       and then
         Shape_Holders.Element (H).X = Shape_Holders.Element (H)'Old.X + DX
       and then Shape_Holders.Element (H).Y = Shape_Holders.Element (H)'Old.Y,
     Contract_Cases =>
       (Is_Circle (H) => Is_Circle (H) and then Radius (H) = Radius (H)'Old,
        others        => not Is_Circle (H));
   --  Move the shape held by H without copying it. The shape keeps its
   --  specific type and its other components.

   procedure Make_Circle (H : in out Shape_Holders.Holder; R : Natural)
   with
     Pre  => not Shape_Holders.Is_Empty (H),
     Post =>
       Is_Circle (H)
       and then Radius (H) = R
       and then Shape_Holders."=" (H, H'Old);
   --  Replace the shape held by H by a circle at the same position

end Clients;
