with Ada.Text_IO;
with Inst; use Inst;
with Shapes; use Shapes;
with Test_Gen;

procedure Test with SPARK_Mode is
   procedure Test_Strings is new
     Test_Gen (String, String_Inst, String_Value, Same_String);
   procedure Test_Shapes is new
     Test_Gen (Shape'Class, Shape_Inst, Shape_Value, Same_Shape);

   procedure Assert (B : Boolean; S : String) with Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_String_Bounds with Pre => True is
      use String_Inst.Holders;
      Item : constant String (4 .. 6) := "abc";
      H : Holder := To_Holder (Item);
   begin
      Assert (Element (H)'First = 4 and Element (H)'Last = 6,
              "To_Holder preserves string bounds");
      Assert (Constant_Reference (H).all'Length = 3,
              "Constant_Reference preserves string length");
      declare
         R : access String := Reference (H);
      begin
         R (4) := 'A';
      end;
      Assert (Same_String (Element (H), String'(4 => 'A', 5 => 'b', 6 => 'c')),
              "Reference changes a character and preserves bounds");
      Replace_Element (H, "longer string");
      Assert (Same_String (Element (H), "longer string"),
              "Replacement can change string bounds");
      Replace_Element (H, "");
      Assert (not Is_Empty (H) and then Element (H)'Length = 0,
              "A holder containing an empty string is not empty");
   end Test_String_Bounds;

   procedure Test_Shape_Tags with Pre => True is
      use Shape_Inst.Holders;
      H : Holder := To_Holder (Circle'(X => 1, Y => 2, Radius => 3));
      G : Holder := To_Holder (Shape'(X => 1, Y => 2));
   begin
      Assert (Element (H) in Circle and then Circle (Element (H)).Radius = 3,
              "To_Holder preserves the dynamic tag and extension");
      Assert (H = G, "Holder equality uses Same_Position across tags");
      G := Copy (H);
      Assert (Element (G) in Circle and then Circle (Element (G)).Radius = 3,
              "Copy preserves more than the supplied equality observes");
      Assert (Constant_Reference (H).all in Circle,
              "Constant_Reference preserves the dynamic tag");
      declare
         R : access Shape'Class := Reference (H);
      begin
         R.X := 7;
      end;
      Assert (Element (H).X = 7 and then Element (H).Y = 2
              and then Element (H) in Circle
              and then Circle (Element (H)).Radius = 3,
              "Reference preserves the tag and unmodified components");
      Assert (Element (G).X = 1, "Reference does not modify a copied holder");
      Replace_Element (H, Shape'(X => 0, Y => 0));
      Assert (Element (H) not in Circle,
              "Replace_Element can change the dynamic tag");
      Swap (H, G);
      Assert (Element (H) in Circle and Element (G) not in Circle,
              "Swap transfers the dynamic tags");
      Move (G, H);
      Assert (Is_Empty (H) and then Element (G) in Circle
              and then Circle (Element (G)).Radius = 3,
              "Move transfers the dynamic tag and extension");
   end Test_Shape_Tags;

begin
   Test_Strings;
   Test_Shapes;
   Test_String_Bounds;
   Test_Shape_Tags;
end Test;
