with SPARK.Containers.Formal.Unbounded_Holders;
with Reclamation_Test;
with Same_Object_Test;
with Shapes; use Shapes;

--  Call every operation of the holders, in every case of their contracts,
--  on an indefinite array type and on a class-wide type.

procedure Test with SPARK_Mode is

   package String_Holders is new
     SPARK.Containers.Formal.Unbounded_Holders (String);

   package Shape_Holders is new
     SPARK.Containers.Formal.Unbounded_Holders (Shape'Class, Same_Position);

   procedure Test_String;
   procedure Test_Shape;

   -----------------
   -- Test_String --
   -----------------

   procedure Test_String is
      use String_Holders;

      H : Holder;
      G : Holder := Empty_Holder;
   begin
      --  The default value is empty

      pragma Assert (Is_Empty (H));
      pragma Assert (Is_Empty (G));
      pragma Assert (H = G);

      --  To_Holder, Element and Constant_Reference

      H := To_Holder ("abc");
      pragma Assert (not Is_Empty (H));
      pragma Assert (Element (H) = "abc");
      pragma Assert (Constant_Reference (H).all = "abc");
      pragma Assert (Constant_Reference (H).all'Length = 3);

      --  "=" when only one holder is empty

      pragma Assert (H /= G);
      pragma Assert (G /= H);

      --  Assignment copies the element

      G := H;
      pragma Assert (G = H);
      Replace_Element (G, "longer string");
      pragma Assert (Element (G) = "longer string");
      pragma Assert (Element (H) = "abc");
      pragma Assert (G /= H);

      --  Copy of a holder which is empty or not

      declare
         C : constant Holder := Copy (H);
         E : constant Holder := Copy (Empty_Holder);
      begin
         pragma Assert (Element (C) = "abc");
         pragma Assert (Is_Empty (E));
      end;

      --  Assign from a holder which is empty or not

      Assign (Target => G, Source => H);
      pragma Assert (Element (G) = "abc");
      Assign (Target => G, Source => Empty_Holder);
      pragma Assert (Is_Empty (G));

      --  Replace_Element in a holder which is empty

      Replace_Element (G, "xyz");
      pragma Assert (Element (G) = "xyz");

      --  Move from a holder which is empty or not

      Move (Target => G, Source => H);
      pragma Assert (Is_Empty (H));
      pragma Assert (Element (G) = "abc");
      Move (Target => G, Source => H);
      pragma Assert (Is_Empty (G));
      pragma Assert (Is_Empty (H));

      --  Swap in the four possible cases

      Swap (G, H);
      pragma Assert (Is_Empty (G));
      pragma Assert (Is_Empty (H));

      Replace_Element (H, "one");
      Swap (G, H);
      pragma Assert (Element (G) = "one");
      pragma Assert (Is_Empty (H));

      Swap (G, H);
      pragma Assert (Is_Empty (G));
      pragma Assert (Element (H) = "one");

      Replace_Element (G, "two");
      Swap (G, H);
      pragma Assert (Element (G) = "one");
      pragma Assert (Element (H) = "two");

      --  Reference gives a read-write access to the element

      declare
         R : access String := Reference (H);
      begin
         pragma Assert (R.all = "two");
         R (1) := 'T';
      end;
      pragma Assert (Element (H) = "Two");
      pragma Assert (Element (G) = "one");

      --  Clear a holder which is empty or not

      Clear (G);
      pragma Assert (Is_Empty (G));
      Clear (G);
      pragma Assert (Is_Empty (G));
      pragma Assert (Element (H) = "Two");
   end Test_String;

   ----------------
   -- Test_Shape --
   ----------------

   procedure Test_Shape is
      use Shape_Holders;

      H : Holder := To_Holder (Circle'(X => 1, Y => 2, Radius => 3));
      G : Holder;
   begin
      --  The holder keeps the specific type of its element

      pragma Assert (Element (H) in Circle);
      pragma Assert (Circle (Element (H)).Radius = 3);
      pragma Assert (Constant_Reference (H).all in Circle);
      pragma Assert (Constant_Reference (H).X = 1);

      --  "=" compares elements with Same_Position

      G := To_Holder (Shape'(X => 1, Y => 2));
      pragma Assert (Element (G) not in Circle);
      pragma Assert (G = H);

      --  Replace the element by one of a different type

      Replace_Element (H, Shape'(X => 0, Y => 0));
      pragma Assert (Element (H) not in Circle);
      pragma Assert (Element (H).X = 0);
      pragma Assert (G /= H);

      --  Move and swap elements of different types

      Replace_Element (G, Circle'(X => 4, Y => 5, Radius => 6));
      Swap (G, H);
      pragma Assert (Element (H) in Circle);
      pragma Assert (Element (G) not in Circle);
      Move (Target => G, Source => H);
      pragma Assert (Is_Empty (H));
      pragma Assert (Circle (Element (G)).Radius = 6);

      --  Update a component of the element through Reference. The element
      --  keeps its specific type and its other components.

      declare
         R : access Shape'Class := Reference (G);
      begin
         pragma Assert (R.X = 4);
         R.X := 7;
      end;
      pragma Assert (Element (G).X = 7);
      pragma Assert (Element (G).Y = 5);
      pragma Assert (Circle (Element (G)).Radius = 6);
   end Test_Shape;

begin
   Test_String;
   Test_Shape;
   Same_Object_Test;
   Reclamation_Test;
end Test;
