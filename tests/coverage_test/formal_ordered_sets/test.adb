pragma Ada_2022;

with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Ordered_Sets;
with Big_Test;

procedure Test with SPARK_Mode is
   function Lt (X, Y : Integer) return Boolean is
     (X mod 1000 < Y mod 1000);
   function Eq (X, Y : Integer) return Boolean is
     (X mod 1000 = Y mod 1000);

   package Int_Sets is new
     SPARK.Containers.Formal.Ordered_Sets (Integer, Lt, Eq);
   use Int_Sets;

   package Value_Sets is new
     SPARK.Containers.Formal.Ordered_Sets (Integer, Lt);

   subtype Test_Set is Set (64);

   function Key_Of (Element : Integer) return Integer is
     (Element mod 1000);
   package Keys is new Int_Sets.Generic_Keys (Integer, Key_Of);

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Fill (X : in out Set; First_Item, Last_Item : Integer) is
   begin
      for I in First_Item .. Last_Item loop
         Insert (X, I);
      end loop;
   end Fill;

   procedure Test_Empty_Set with Pre => True is
      X : Test_Set := Empty_Set (64);
   begin
      Assert (Length (X) = 0, "Empty_Set");
   end Test_Empty_Set;

   procedure Test_To_Set with Pre => True is
   begin
      Assert (Length (To_Set (3)) = 1, "To_Set");
   end Test_To_Set;

   procedure Test_Length with Pre => True is
      X : Test_Set;
   begin
      Assert (Length (X) = 0, "Length on empty set");
      Fill (X, 1, 5);
      Assert (Length (X) = 5, "Length on non-empty set");
   end Test_Length;

   procedure Test_Is_Empty with Pre => True is
      X : Test_Set;
   begin
      Assert (Is_Empty (X), "Is_Empty on empty set");
      Fill (X, 1, 5);
      Assert (not Is_Empty (X), "Is_Empty on non-empty set");
   end Test_Is_Empty;

   procedure Test_Eq with Pre => True is
      X, Y : Test_Set;
   begin
      Assert (X = Y, "empty sets are equal");
      Fill (X, 1, 5);
      Assert (X /= Y, "sets of different lengths are unequal");
      Y := X;
      Assert (X = X and then X = Y, "equal non-empty sets");
      Insert (Y, 7);
      Assert (X /= Y, "sets of different lengths are unequal");
      Delete (Y, 1);
      Assert (X /= Y, "same-length sets with different elements");
   end Test_Eq;

   procedure Test_Equivalent_Sets with Pre => True is
      procedure Test_Equivalent_But_Unequal is
         X, Y : Value_Sets.Set (8);
      begin
         Value_Sets.Insert (X, 1);
         Value_Sets.Insert (Y, 1001);
         Assert (Value_Sets.Equivalent_Sets (X, Y),
                 "sets with equivalent keys");
         Assert (not Value_Sets."=" (X, Y),
                 "equivalent sets with different elements");
      end Test_Equivalent_But_Unequal;

      A, B : Test_Set;
   begin
      Assert (Equivalent_Sets (A, B), "empty sets are equivalent");
      Fill (A, 1, 5);
      Assert (not Equivalent_Sets (A, B),
              "sets of different lengths are not equivalent");
      B := A;
      Assert (Equivalent_Sets (A, B), "equal sets are equivalent");
      Delete (B, 1);
      Insert (B, 7);
      Assert (not Equivalent_Sets (A, B),
              "same-length sets with different elements");
      Test_Equivalent_But_Unequal;
   end Test_Equivalent_Sets;

   procedure Test_Contains with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Contains (X, 3) and then not Contains (X, 9),
              "Contains");
   end Test_Contains;

   procedure Test_Insert_1 with Pre => True is
      X : Test_Set;
   begin
      for I in 1 .. 5 loop
         Insert (X, I);
      end loop;
      Assert (Length (X) = 5, "Insert five elements");
   end Test_Insert_1;

   procedure Test_Insert_2 with Pre => True is
      X : Test_Set;
      P : Cursor;
      Inserted : Boolean;
   begin
      Fill (X, 1, 5);
      Insert (X, 3, P, Inserted);
      Assert (not Inserted and then Element (X, P) = 3,
              "Insert existing element");
      Insert (X, 6, P, Inserted);
      Assert (Inserted and then Element (X, P) = 6,
              "Insert new element");
   end Test_Insert_2;

   procedure Test_Assign with Pre => True is
      procedure Test_Same_Container is
         X : Test_Set;
      begin
         Fill (X, 1, 6);
         Assign (X, X);
         Assert (Length (X) = 6, "Assign on itself");
      end Test_Same_Container;

      X, Y : Test_Set;
   begin
      Test_Same_Container;
      Fill (X, 1, 6);
      Assign (Y, X);
      Assert (Y = X, "Assign non-empty set");
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      procedure Test_Empty is
         X : Test_Set;
      begin
         declare
            Z : constant Set := Copy (X, 64);
         begin
            Assert (Is_Empty (Z), "Copy empty set");
         end;
      end Test_Empty;

      procedure Test_Non_Empty is
         X : Test_Set;
      begin
         Fill (X, 1, 6);
         declare
            Z : constant Set := Copy (X, 64);
         begin
            Assert (Z = X, "Copy non-empty set");
         end;
         declare
            Z : constant Set := Copy (X, 96);
         begin
            Assert (Z.Capacity = 96 and then Z = X,
                    "Copy with larger capacity");
         end;
      end Test_Non_Empty;

      procedure Test_After_Delete is
         X : Test_Set;
      begin
         Fill (X, 1, 6);
         Delete (X, 1);
         declare
            Z : constant Set := Copy (X, 96);
         begin
            Assert (Z = X, "Copy after deleting an element");
         end;
      end Test_After_Delete;
   begin
      Test_Empty;
      Test_Non_Empty;
      Test_After_Delete;
   end Test_Copy;

   procedure Test_Clear with Pre => True is
      X : Test_Set;
   begin
      Clear (X);
      Assert (Is_Empty (X), "Clear empty set");
      Fill (X, 1, 5);
      Clear (X);
      Assert (Is_Empty (X), "Clear non-empty set");
   end Test_Clear;

   procedure Test_Move with Pre => True is
      X, Y : Test_Set;
   begin
      Fill (X, 1, 6);
      Move (Y, X);
      Assert (Is_Empty (X) and then Length (Y) = 6, "Move");
   end Test_Move;

   procedure Test_First_Element with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (First_Element (X) = 1, "First_Element");
   end Test_First_Element;

   procedure Test_Last_Element with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Last_Element (X) = 5, "Last_Element");
   end Test_Last_Element;

   procedure Test_First with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Element (X, First (X)) = 1, "First");
   end Test_First;

   procedure Test_Last with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Element (X, Last (X)) = 5, "Last");
   end Test_Last;

   procedure Test_Element with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Element (X, Find (X, 3)) = 3, "Element");
   end Test_Element;

   procedure Test_Find with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Find (X, 3) /= No_Element and then
              Find (X, 8) = No_Element, "Find");
   end Test_Find;

   procedure Test_Floor with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Floor (X, 0) = No_Element, "Floor below first element");
      Assert (Element (X, Floor (X, 3)) = 3, "Floor in range");
   end Test_Floor;

   procedure Test_Ceiling with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Ceiling (X, 6) = No_Element, "Ceiling above last element");
      Assert (Element (X, Ceiling (X, 3)) = 3, "Ceiling in range");
   end Test_Ceiling;

   procedure Test_Has_Element with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := First (X);
      Assert (Has_Element (X, P), "Has_Element");
   end Test_Has_Element;

   procedure Test_Constant_Reference with Pre => True is
      X : aliased Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := First (X);
      Assert (Constant_Reference (X, P).all = 1,
              "Constant_Reference");
   end Test_Constant_Reference;

   procedure Test_Next with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := First (X);
      Assert (Element (X, Next (X, P)) = 2, "Next function");
      Next (X, P);
      Assert (Element (X, P) = 2, "Next procedure");
      Assert (Next (X, No_Element) = No_Element, "Next No_Element");
   end Test_Next;

   procedure Test_Previous with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := Find (X, 2);
      Assert (Element (X, Previous (X, P)) = 1,
              "Previous function");
      Previous (X, P);
      Assert (Element (X, P) = 1, "Previous procedure");
      Assert (Previous (X, No_Element) = No_Element,
              "Previous No_Element");
   end Test_Previous;

   procedure Test_Replace_Element with Pre => True is
      procedure Test_Equivalent_Key is
         X : Test_Set;
         P : Cursor;
      begin
         Fill (X, 1, 5);
         P := Find (X, 3);
         Replace_Element (X, P, 1003);
         Assert (Element (X, P) = 1003,
                 "Replace_Element equivalent key");
      end Test_Equivalent_Key;

      procedure Test_Between_Elements is
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
      end Test_Between_Elements;

      procedure Test_After_Last is
         X : Test_Set;
         P : Cursor;
      begin
         Insert (X, 10);
         Insert (X, 20);
         Insert (X, 30);
         Insert (X, 40);
         P := Find (X, 40);
         Replace_Element (X, P, 50);
         Assert (Length (X) = 4 and then Element (X, P) = 50
                 and then not Contains (X, 40),
                 "Replace_Element reinserts after last element");
      end Test_After_Last;

      procedure Test_Same_Position is
         X : Test_Set;
         P : Cursor;
      begin
         Insert (X, 10);
         Insert (X, 20);
         Insert (X, 30);
         Insert (X, 40);
         P := Find (X, 30);
         Replace_Element (X, P, 28);
         Assert (Length (X) = 4 and then Element (X, P) = 28
                 and then not Contains (X, 30),
                 "Replace_Element keeps its position");
      end Test_Same_Position;

   begin
      Test_Equivalent_Key;
      Test_Between_Elements;
      Test_After_Last;
      Test_Same_Position;
   end Test_Replace_Element;

   procedure Test_Replace with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Replace (X, 1004);
      Assert (Element (X, Find (X, 4)) = 1004, "Replace");
   end Test_Replace;

   procedure Test_Include with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Include (X, 1005);
      Assert (Element (X, Find (X, 5)) = 1005,
              "Include existing element");
      Include (X, 6);
      Assert (Contains (X, 6), "Include new element");
   end Test_Include;

   procedure Test_Exclude with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 6);
      Exclude (X, 9);
      Exclude (X, 6);
      Assert (not Contains (X, 6), "Exclude");
   end Test_Exclude;

   procedure Test_Delete_1 with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Delete (X, 2);
      Assert (Length (X) = 4 and then not Contains (X, 2),
              "Delete by element");
   end Test_Delete_1;

   procedure Test_Delete_2 with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := Find (X, 3);
      Delete (X, P);
      Assert (P = No_Element and then Length (X) = 4,
              "Delete by cursor");
   end Test_Delete_2;

   procedure Test_Delete_First with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Delete_First (X);
      Assert (Length (X) = 4 and then First_Element (X) = 2,
              "Delete_First");
   end Test_Delete_First;

   procedure Test_Delete_Last with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Delete_Last (X);
      Assert (Length (X) = 4 and then Last_Element (X) = 4,
              "Delete_Last");
   end Test_Delete_Last;

   procedure Test_Overlap with Pre => True is
      X, Y : Test_Set;
   begin
      Fill (X, 1, 5);
      Fill (Y, 4, 8);
      Assert (Overlap (X, Y), "Overlap");
   end Test_Overlap;

   procedure Test_Is_Subset with Pre => True is
      X, Y : Test_Set;
   begin
      Fill (X, 1, 5);
      Fill (Y, 4, 8);
      Assert (not Is_Subset (X, Y), "Is_Subset false");
      Assert (Is_Subset (Intersection (X, Y), X),
              "Is_Subset true");
   end Test_Is_Subset;

   procedure Test_Union with Pre => True is
      procedure Test_Procedure is
         X, Y, Z : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Z := X;
         Union (Z, Y);
         Assert (Length (Z) = 8, "Union procedure");
      end Test_Procedure;

      procedure Test_Function is
         X, Y : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Assert (Length (Union (X, Y)) = 8,
                 "Union function");
      end Test_Function;

      procedure Test_Edges is
         X, Empty : Test_Set;
      begin
         Fill (X, 1, 5);
         Assert (Union (X, X) = X, "Union of same set");
         Assert (Union (Empty, X) = X, "Union with empty left");
         Assert (Union (X, Empty) = X, "Union with empty right");
      end Test_Edges;
   begin
      Test_Procedure;
      Test_Function;
      Test_Edges;
   end Test_Union;

   procedure Test_Intersection with Pre => True is
      procedure Test_Procedure is
         X, Y, Z : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Z := X;
         Intersection (Z, Y);
         Assert (Length (Z) = 2, "Intersection procedure");
      end Test_Procedure;

      procedure Test_Function is
         X, Y : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Assert (Length (Intersection (X, Y)) = 2,
                 "Intersection function");
      end Test_Function;

      procedure Test_Edges is
         X : Test_Set;
      begin
         Fill (X, 1, 5);
         Assert (Intersection (X, X) = X,
                 "Intersection of same set");
      end Test_Edges;
   begin
      Test_Procedure;
      Test_Function;
      Test_Edges;
   end Test_Intersection;

   procedure Test_Difference with Pre => True is
      procedure Test_Procedure is
         X, Y, Z : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Z := X;
         Difference (Z, Y);
         Assert (Length (Z) = 3, "Difference procedure");
      end Test_Procedure;

      procedure Test_Function is
         X, Y : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Assert (Length (Difference (X, Y)) = 3,
                 "Difference function");
      end Test_Function;

      procedure Test_Edges is
         X, Empty : Test_Set;
      begin
         Fill (X, 1, 5);
         Assert (Is_Empty (Difference (X, X)),
                 "Difference of same set");
         Assert (Is_Empty (Difference (Empty, X)),
                 "Difference with empty left");
         Assert (Difference (X, Empty) = X,
                 "Difference with empty right");
      end Test_Edges;
   begin
      Test_Procedure;
      Test_Function;
      Test_Edges;
   end Test_Difference;

   procedure Test_Symmetric_Difference with Pre => True is
      procedure Test_Procedure is
         X, Y, Z : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Z := X;
         Symmetric_Difference (Z, Y);
         Assert (Length (Z) = 6, "Symmetric_Difference procedure");
      end Test_Procedure;

      procedure Test_Function is
         X, Y : Test_Set;
      begin
         Fill (X, 1, 5);
         Fill (Y, 4, 8);
         Assert (Length (Symmetric_Difference (X, Y)) = 6,
                 "Symmetric_Difference function");
      end Test_Function;

      procedure Test_Edges is
         X, Empty : Test_Set;
      begin
         Fill (X, 1, 5);
         Assert (Is_Empty (Symmetric_Difference (X, X)),
                 "Symmetric_Difference of same set");
         Assert (Symmetric_Difference (Empty, X) = X,
                 "Symmetric_Difference with empty left");
         Assert (Symmetric_Difference (X, Empty) = X,
                 "Symmetric_Difference with empty right");
      end Test_Edges;
   begin
      Test_Procedure;
      Test_Function;
      Test_Edges;
   end Test_Symmetric_Difference;

   procedure Test_Contains_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Keys.Contains (X, 3) and then not Keys.Contains (X, 9),
              "Generic_Keys.Contains");
   end Test_Contains_Key;

   procedure Test_Find_Key with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := Keys.Find (X, 3);
      Assert (P /= No_Element, "Generic_Keys.Find");
   end Test_Find_Key;

   procedure Test_Key with Pre => True is
      X : Test_Set;
      P : Cursor;
   begin
      Fill (X, 1, 5);
      P := Keys.Find (X, 3);
      Assert (Keys.Key (X, P) = 3, "Generic_Keys.Key");
   end Test_Key;

   procedure Test_Element_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Keys.Element (X, 3) = 3, "Generic_Keys.Element");
   end Test_Element_Key;

   procedure Test_Floor_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Keys.Floor (X, 0) = No_Element,
              "Generic_Keys.Floor below first element");
      Assert (Keys.Key (X, Keys.Floor (X, 3)) = 3,
              "Generic_Keys.Floor in range");
   end Test_Floor_Key;

   procedure Test_Ceiling_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Assert (Keys.Ceiling (X, 6) = No_Element,
              "Generic_Keys.Ceiling above last element");
      Assert (Keys.Key (X, Keys.Ceiling (X, 3)) = 3,
              "Generic_Keys.Ceiling in range");
   end Test_Ceiling_Key;

   procedure Test_Replace_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Keys.Replace (X, 3, 1003);
      Assert (Keys.Element (X, 3) = 1003,
              "Generic_Keys.Replace");
   end Test_Replace_Key;

   procedure Test_Exclude_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Keys.Exclude (X, 9);
      Keys.Exclude (X, 4);
      Assert (not Keys.Contains (X, 4), "Generic_Keys.Exclude");
   end Test_Exclude_Key;

   procedure Test_Delete_Key with Pre => True is
      X : Test_Set;
   begin
      Fill (X, 1, 5);
      Keys.Delete (X, 2);
      Assert (not Keys.Contains (X, 2), "Generic_Keys.Delete");
   end Test_Delete_Key;

begin
   Test_Empty_Set;
   Test_To_Set;
   Test_Length;
   Test_Is_Empty;
   Test_Eq;
   Test_Equivalent_Sets;
   Test_Contains;
   Test_Insert_1;
   Test_Insert_2;
   Test_Assign;
   Test_Copy;
   Test_Clear;
   Test_Move;
   Test_First_Element;
   Test_Last_Element;
   Test_First;
   Test_Last;
   Test_Element;
   Test_Find;
   Test_Floor;
   Test_Ceiling;
   Test_Has_Element;
   Test_Constant_Reference;
   Test_Next;
   Test_Previous;
   Test_Replace_Element;
   Test_Replace;
   Test_Include;
   Test_Exclude;
   Test_Delete_1;
   Test_Delete_2;
   Test_Delete_First;
   Test_Delete_Last;
   Test_Overlap;
   Test_Is_Subset;
   Test_Union;
   Test_Intersection;
   Test_Difference;
   Test_Symmetric_Difference;
   Test_Contains_Key;
   Test_Find_Key;
   Test_Key;
   Test_Element_Key;
   Test_Floor_Key;
   Test_Ceiling_Key;
   Test_Replace_Key;
   Test_Exclude_Key;
   Test_Delete_Key;
   Big_Test;
end Test;
