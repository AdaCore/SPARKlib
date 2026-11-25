with Ada.Text_IO;

procedure Test_Gen with SPARK_Mode is
   use Inst.Holders;

   procedure Assert (B : Boolean; S : String) with Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Empty_Holder with Pre => True is
      H : Holder := Empty_Holder;
   begin
      Assert (Is_Empty (H), "Empty_Holder is empty");
   end Test_Empty_Holder;

   procedure Test_Is_Empty with Pre => True is
      H : Holder;
   begin
      Assert (Is_Empty (H), "Default holder is empty");
      H := To_Holder (Value (1));
      Assert (not Is_Empty (H), "To_Holder is not empty");
   end Test_Is_Empty;

   procedure Test_To_Holder with Pre => True is
      H : Holder := To_Holder (Value (1));
   begin
      Assert (Same_Value (Element (H), Value (1)),
              "To_Holder preserves the element");
   end Test_To_Holder;

   procedure Test_Eq with Pre => True is
      H, G : Holder;
   begin
      Assert (H = G, "Empty holders are equal");
      H := To_Holder (Value (1));
      Assert (H /= G and G /= H, "Only one holder is empty");
      G := H;
      Assert (H = H and H = G, "A holder equals itself and its copy");
      Replace_Element (G, Value (2));
      Assert ((H = G) = Inst.Equal (Element (H), Element (G)),
              "Holder equality uses element equality");
      Replace_Element (G, Value (3));
      Assert ((H = G) = Inst.Equal (Element (H), Element (G)),
              "Holder equality distinguishes unequal elements");
   end Test_Eq;

   procedure Test_Assign with Pre => True is
      H : Holder := To_Holder (Value (1));
      G : Holder;
   begin
      Assign (H, G);
      Assert (Is_Empty (H), "Assign from empty clears the target");
      Replace_Element (G, Value (1));
      Assign (H, G);
      Assert (Same_Value (Element (H), Value (1)),
              "Assign to empty preserves the element");
      Replace_Element (G, Value (2));
      Assert (Same_Value (Element (H), Value (1)),
              "Assign makes an independent copy");
      Assign (H, G);
      Assert (Same_Value (Element (H), Value (2)),
              "Assign replaces a non-empty target");
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      H : Holder;
   begin
      declare
         G : constant Holder := Copy (H);
      begin
         Assert (Is_Empty (G), "Copy of empty is empty");
      end;
      H := To_Holder (Value (1));
      declare
         G : constant Holder := Copy (H);
      begin
         Replace_Element (H, Value (2));
         Assert (Same_Value (Element (G), Value (1)),
                 "Copy preserves the element independently of its source");
      end;
   end Test_Copy;

   procedure Test_Assignment with Pre => True is
      H : Holder := To_Holder (Value (1));
      G : Holder := H;
   begin
      Replace_Element (G, Value (2));
      Assert (Same_Value (Element (H), Value (1)),
              "Assignment makes an independent copy");
      H := G;
      Assert (Same_Value (Element (H), Value (2)),
              "Assignment replaces a non-empty target");
      G := Empty_Holder;
      Assert (Same_Value (Element (H), Value (2)),
              "Assigned copy survives clearing its source");
   end Test_Assignment;

   procedure Test_Element with Pre => True is
      H : Holder := To_Holder (Value (1));
   begin
      Assert (Same_Value (Element (H), Value (1)),
              "Element returns the stored value");
   end Test_Element;

   procedure Test_Replace_Element with Pre => True is
      H : Holder;
   begin
      Replace_Element (H, Value (1));
      Assert (Same_Value (Element (H), Value (1)),
              "Replace_Element fills an empty holder");
      Replace_Element (H, Value (2));
      Assert (Same_Value (Element (H), Value (2)),
              "Replace_Element replaces an existing element");
   end Test_Replace_Element;

   procedure Test_Clear with Pre => True is
      H : Holder;
   begin
      Clear (H);
      Assert (Is_Empty (H), "Clear on empty remains empty");
      H := To_Holder (Value (1));
      Clear (H);
      Assert (Is_Empty (H), "Clear removes the element");
      Clear (H);
      Assert (Is_Empty (H), "Clear can be repeated");
   end Test_Clear;

   procedure Test_Move with Pre => True is
      H, G : Holder;
   begin
      Move (H, G);
      Assert (Is_Empty (H) and Is_Empty (G), "Move between empty holders");
      Replace_Element (G, Value (1));
      Move (H, G);
      Assert (Is_Empty (G) and then Same_Value (Element (H), Value (1)),
              "Move to empty transfers the element");
      Replace_Element (G, Value (2));
      Move (H, G);
      Assert (Is_Empty (G) and then Same_Value (Element (H), Value (2)),
              "Move replaces a non-empty target");
      Move (H, G);
      Assert (Is_Empty (H) and Is_Empty (G), "Move from empty clears target");
   end Test_Move;

   procedure Test_Swap with Pre => True is
      H, G : Holder;
   begin
      Swap (H, G);
      Assert (Is_Empty (H) and Is_Empty (G), "Swap two empty holders");
      Replace_Element (H, Value (1));
      Swap (H, G);
      Assert (Is_Empty (H) and then Same_Value (Element (G), Value (1)),
              "Swap non-empty with empty");
      Swap (H, G);
      Assert (Is_Empty (G) and then Same_Value (Element (H), Value (1)),
              "Swap empty with non-empty");
      Replace_Element (G, Value (2));
      Swap (H, G);
      Assert (Same_Value (Element (H), Value (2))
              and Same_Value (Element (G), Value (1)),
              "Swap exchanges both elements");
   end Test_Swap;

   procedure Test_Constant_Reference with Pre => True is
      H : Holder := To_Holder (Value (1));
   begin
      Assert (Same_Value (Constant_Reference (H).all, Value (1)),
              "Constant_Reference designates the element");
   end Test_Constant_Reference;

   procedure Test_Reference with Pre => True is
      H : Holder := To_Holder (Value (1));
   begin
      declare
         R : access Element_Type := Reference (H);
      begin
         Assert (Same_Value (R.all, Value (1)),
                 "Reference initially designates the element");
      end;
      Assert (Same_Value (Element (H), Value (1)),
              "An unmodified borrow preserves the element");
   end Test_Reference;

begin
   Test_Empty_Holder;
   Test_Is_Empty;
   Test_To_Holder;
   Test_Eq;
   Test_Assign;
   Test_Copy;
   Test_Assignment;
   Test_Element;
   Test_Replace_Element;
   Test_Clear;
   Test_Move;
   Test_Swap;
   Test_Constant_Reference;
   Test_Reference;
end Test_Gen;
