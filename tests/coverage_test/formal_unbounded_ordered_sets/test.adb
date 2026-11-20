pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Ordered_Sets;
with Big_Test;
with Growth_Test;

procedure Test with SPARK_Mode is
   function Lt (X, Y : Integer) return Boolean is
     (X mod 1000 < Y mod 1000);
   function Eq (X, Y : Integer) return Boolean is
     (X mod 1000 = Y mod 1000);

   package Int_Sets is new
     SPARK.Containers.Formal.Unbounded_Ordered_Sets (Integer, Lt, Eq);
   use Int_Sets;

   package Value_Sets is new
     SPARK.Containers.Formal.Unbounded_Ordered_Sets (Integer, Lt);

   subtype Test_Set is Set;

   function Key_Of (Element : Integer) return Integer is
     (Element mod 1000);
   package Keys is new Int_Sets.Generic_Keys (Integer, Key_Of);

   procedure Assert (B : Boolean; Message : String) is
   begin
      if not B then
         raise Program_Error with Message;
      end if;
   end Assert;

   procedure Fill (X : in out Set; First_Item, Last_Item : Integer) is
   begin
      for I in First_Item .. Last_Item loop
         Insert (X, I);
      end loop;
   end Fill;

   procedure Test_Basics with Pre => True is
      X, Y : Test_Set;
      P : Cursor;
      Inserted : Boolean;
   begin
      Assert (Is_Empty (X), "new set is empty");
      Assert (Length (Empty_Set) = 0, "Empty_Set");
      Assert (Length (To_Set (3)) = 1, "To_Set");
      Assert (X = Y, "empty sets are equal");
      declare
         Z : constant Set := Copy (X);
      begin
         Assert (Is_Empty (Z), "Copy of empty set");
      end;
      Y := X;
      Assert (Is_Empty (Y), "Adjust empty set");

      Fill (X, 1, 5);
      Assert (Length (X) = 5 and then not Is_Empty (X), "Insert and Length");
      Assert (Contains (X, 3) and then not Contains (X, 9), "Contains");
      Insert (X, 3, P, Inserted);
      Assert (not Inserted and then Element (X, P) = 3, "duplicate Insert");
      Insert (X, 6, P, Inserted);
      Assert (Inserted and then Element (X, P) = 6, "new Insert");

      Assign (X, X);
      Assert (Length (X) = 6, "Assign on itself");
      Assign (Y, X);
      Assert (Y = X and then Equivalent_Sets (X, Y), "Assign");
      declare
         Z : constant Set := Copy (X);
      begin
         Assert (Z = X, "Copy");
      end;
      Assert (X = X, "same set equality");
      Insert (Y, 7);
      Assert (X /= Y and then not Equivalent_Sets (X, Y), "different sets");
      Delete (Y, 1);
      Assert (not Equivalent_Sets (X, Y)
              and then not Equivalent_Sets (Y, X),
              "same-length sets with different elements");
      Clear (Y);
      Assert (Is_Empty (Y), "Clear");
      Move (Y, X);
      Assert (Is_Empty (X) and then Length (Y) = 6, "Move");
   end Test_Basics;

   procedure Test_Equivalent_But_Unequal with Pre => True is
      X, Y : Value_Sets.Set;
   begin
      Value_Sets.Insert (X, 1);
      Value_Sets.Insert (Y, 1001);
      Assert (Value_Sets.Equivalent_Sets (X, Y),
              "sets with equivalent keys");
      Assert (not Value_Sets."=" (X, Y),
              "equivalent sets with different elements");
   end Test_Equivalent_But_Unequal;

   procedure Test_Cursors with Pre => True is
      X : aliased Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      Assert (First_Element (X) = 1 and Last_Element (X) = 5,
              "first and last elements");
      Assert (Element (X, First (X)) = 1 and Element (X, Last (X)) = 5,
              "first and last cursors");
      Assert (Find (X, 3) /= No_Element and Find (X, 8) = No_Element,
              "Find");
      Assert (Floor (X, 0) = No_Element and Ceiling (X, 6) = No_Element,
              "Floor and Ceiling outside range");
      Assert (Element (X, Floor (X, 3)) = 3
              and Element (X, Ceiling (X, 3)) = 3,
              "Floor and Ceiling in range");
      P := First (X);
      Assert (Has_Element (X, P) and Constant_Reference (X, P).all = 1,
              "Has_Element and Constant_Reference");
      Assert (Element (X, Next (X, P)) = 2, "Next function");
      Next (X, P);
      Assert (Element (X, P) = 2, "Next procedure");
      Assert (Element (X, Previous (X, P)) = 1, "Previous function");
      Previous (X, P);
      Assert (Element (X, P) = 1, "Previous procedure");
      Assert (Next (X, No_Element) = No_Element
              and then Previous (X, No_Element) = No_Element,
              "Next and Previous on No_Element");

      P := Find (X, 3);
      Replace_Element (X, P, 1003);
      Assert (Element (X, P) = 1003, "Replace_Element");
      Replace (X, 1004);
      Assert (Element (X, Find (X, 4)) = 1004, "Replace");
      Include (X, 1005);
      Assert (Element (X, Find (X, 5)) = 1005, "Include existing");
      Include (X, 6);
      Assert (Contains (X, 6), "Include new");

      Exclude (X, 9);
      Exclude (X, 6);
      Assert (not Contains (X, 6), "Exclude");
      Delete (X, 2);
      P := Find (X, 3);
      Delete (X, P);
      Assert (P = No_Element and Length (X) = 3, "Delete by key and cursor");
      Delete_First (X);
      Delete_Last (X);
      Assert (Length (X) = 1, "Delete_First and Delete_Last");
   end Test_Cursors;

   procedure Test_Replacing_Keys with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Insert (X, 10);
      Insert (X, 20);
      Insert (X, 30);
      Insert (X, 40);

      P := Find (X, 20);
      Replace_Element (X, P, 25);
      Assert (Length (X) = 4 and then Element (X, P) = 25
              and then not Contains (X, 20),
              "Replace_Element reinserts between elements");

      P := Find (X, 40);
      Replace_Element (X, P, 50);
      Assert (Length (X) = 4 and then Element (X, P) = 50
              and then not Contains (X, 40),
              "Replace_Element reinserts after last element");

      P := Find (X, 30);
      Replace_Element (X, P, 28);
      Assert (Length (X) = 4 and then Element (X, P) = 28
              and then not Contains (X, 30),
              "Replace_Element keeps its position");
   end Test_Replacing_Keys;

   procedure Test_Set_Operations with Pre => True is
      X, Y : Test_Set;
   begin
      Fill (X, 1, 5);
      Fill (Y, 4, 8);
      Assert (Overlap (X, Y) and not Is_Subset (X, Y), "Overlap and Is_Subset");
      Assert (Is_Subset (Intersection (X, Y), X), "Intersection subset");
      Assert (Length (Union (X, Y)) = 8, "Union function");
      Assert (Length (Intersection (X, Y)) = 2, "Intersection function");
      Assert (Length (Difference (X, Y)) = 3, "Difference function");
      Assert (Length (Symmetric_Difference (X, Y)) = 6,
              "Symmetric_Difference function");

      declare
         Z : Test_Set := X;
      begin
         Union (Z, Y);
         Assert (Length (Z) = 8, "Union procedure");
      end;
      declare
         Z : Test_Set := X;
      begin
         Intersection (Z, Y);
         Assert (Length (Z) = 2, "Intersection procedure");
      end;
      declare
         Z : Test_Set := X;
      begin
         Difference (Z, Y);
         Assert (Length (Z) = 3, "Difference procedure");
      end;
      declare
         Z : Test_Set := X;
      begin
         Symmetric_Difference (Z, Y);
         Assert (Length (Z) = 6, "Symmetric_Difference procedure");
      end;
   end Test_Set_Operations;

   procedure Test_Set_Edges with Pre => True is
      X, Empty : Test_Set;
   begin
      Fill (X, 1, 5);

      Assert (Is_Empty (Difference (X, X)), "Difference of same set");
      Assert (Is_Empty (Difference (Empty, X)), "Difference with empty left");
      Assert (Difference (X, Empty) = X, "Difference with empty right");
      Assert (Intersection (X, X) = X, "Intersection of same set");

      Assert (Is_Empty (Symmetric_Difference (X, X)),
              "Symmetric_Difference of same set");
      Assert (Symmetric_Difference (Empty, X) = X,
              "Symmetric_Difference with empty left");
      Assert (Symmetric_Difference (X, Empty) = X,
              "Symmetric_Difference with empty right");

      Assert (Union (X, X) = X, "Union of same set");
      Assert (Union (Empty, X) = X, "Union with empty left");
      Assert (Union (X, Empty) = X, "Union with empty right");

      declare
         Target : Test_Set;
      begin
         Union (Target, Empty);
         Assert (Is_Empty (Target), "Union of empty sets");
         Union (Target, X);
         Assert (Target = X, "Union into empty target");
         Union (Target, Empty);
         Assert (Target = X, "Union with empty source");
      end;
   end Test_Set_Edges;

   procedure Test_Keys with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      Assert (Keys.Contains (X, 3) and not Keys.Contains (X, 9),
              "Generic_Keys.Contains");
      P := Keys.Find (X, 3);
      Assert (P /= No_Element and then Keys.Key (X, P) = 3,
              "Generic_Keys.Find and Key");
      Assert (Keys.Element (X, 3) = 3, "Generic_Keys.Element");
      Assert (Keys.Floor (X, 0) = No_Element
              and Keys.Ceiling (X, 6) = No_Element,
              "Generic_Keys.Floor and Ceiling outside range");
      Assert (Keys.Key (X, Keys.Floor (X, 3)) = 3
              and Keys.Key (X, Keys.Ceiling (X, 3)) = 3,
              "Generic_Keys.Floor and Ceiling in range");
      Keys.Replace (X, 3, 1003);
      Assert (Keys.Element (X, 3) = 1003, "Generic_Keys.Replace");
      Keys.Exclude (X, 9);
      Keys.Exclude (X, 4);
      Keys.Delete (X, 2);
      Assert (not Keys.Contains (X, 2) and not Keys.Contains (X, 4),
              "Generic_Keys.Exclude and Delete");
   end Test_Keys;

begin
   Test_Basics;
   Test_Equivalent_But_Unequal;
   Test_Cursors;
   Test_Replacing_Keys;
   Test_Set_Operations;
   Test_Set_Edges;
   Test_Keys;
   Growth_Test;
   Big_Test;
end Test;
