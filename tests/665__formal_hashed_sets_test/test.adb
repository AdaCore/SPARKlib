with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst;
use Inst.Int_Sets;

procedure Test with SPARK_Mode is
   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  A formal hashed set is implemented as several set structures inside a
   --  single array of values. They contain elements corresponding to the same
   --  hash modulo the number of buckets (aka modulus) in the structure. The
   --  head of these sets are stored in a separate array for easier access.

   --  Create set with 5 elements

   procedure Create_Non_Empty_Set (X : in out Set) is
   begin
      for I in 1 .. 5 loop
         Insert (X, I);
      end loop;
   end Create_Non_Empty_Set;

   procedure Create_Non_Empty_Set_With_Collisions (X : in out Set) is
   begin
      for I in 1 .. 5 loop
         Insert (X, I * 100);
      end loop;
   end Create_Non_Empty_Set_With_Collisions;

   procedure Test_Empty_Set with Pre => True is
      X : Set := Empty_Set (1000);
   begin
      Assert (Length (X) = 0, "Empty_Set is empty");
   end Test_Empty_Set;

   procedure Test_Length with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Assert (Length (X) = 0, "Length on empty set");
      Create_Non_Empty_Set (X);
      Assert (Length (X) = 5, "Length on non-empty set");
   end Test_Length;

   procedure Test_Eq with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert (X = Y, """="" on empty sets");
      Create_Non_Empty_Set (X);
      Insert (Y, 1);
      Assert (X /= Y, """="" on sets with different lengths");
      Y := X;
      Assert (X = X, """="" on same set");
      Assert (X = Y, """="" on copied set");
      Insert (X, 6);
      Insert (Y, 10006);
      Assert (X = Y, """="" uses equality on elements");
      Insert (X, 7);
      Insert (Y, 1007);
      Assert (X /= Y, """="" on sets with different elements");
   end Test_Eq;

   procedure Test_Equivalent_Sets with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert (Equivalent_Sets (X, Y), "Equivalent_Sets on empty sets");
      Create_Non_Empty_Set (X);
      Insert (Y, 1);
      Assert (not Equivalent_Sets (X, Y) and not Equivalent_Sets (Y, X), "Equivalent_Sets on sets with different lengths");
      Y := X;
      Assert (Equivalent_Sets (X, X), "Equivalent_Sets on same set");
      Assert (Equivalent_Sets (X, Y), "Equivalent_Sets on copied set");
      Insert (X, 6);
      Insert (Y, 1006);
      Assert (Equivalent_Sets (X, Y), "Equivalent_Sets with equivalent elements");
      Insert (X, 7);
      Insert (Y, 17);
      pragma Assert (not Contains (X, 17));
      Assert (not Equivalent_Sets (X, Y), "Equivalent_Sets on sets with different elements");
   end Test_Equivalent_Sets;

   procedure Test_To_Set with Pre => True is
   begin
      Assert (Length (To_Set (1)) = 1, "To_Set, Length is 1");
      Assert (Contains (To_Set (1), 1) and not Contains (To_Set (1), 2), "To_Set, contains only New_Item");
   end Test_To_Set;

   procedure Test_Capacity with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Assert (Capacity (X) = 1000, "Capacity returns the Capacity discriminant");
   end Test_Capacity;

   procedure Test_Reserve_Capacity with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Reserve_Capacity (X, 200);
      Assert (Is_Empty (X), "Reserve_Capacity on empty set does not do anything");
      Create_Non_Empty_Set (X);
      Reserve_Capacity (X, 2);
      Reserve_Capacity (X, 200);
      Assert (Length (X) = 5, "Reserve_Capacity on non-empty set does not do anything");
   end Test_Reserve_Capacity;

   procedure Test_Is_Empty with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Assert (Is_Empty (X), "Is_Empty on empty set");
      Create_Non_Empty_Set (X);
      Assert (not Is_Empty (X), "Is_Empty on non-empty set");
   end Test_Is_Empty;

   procedure Test_Clear with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Clear (X);
      Assert (Is_Empty (X), "Clear on empty set");
      Create_Non_Empty_Set (X);
      Clear (X);
      Assert (Is_Empty (X), "Clear on non-empty set");
   end Test_Clear;

   procedure Test_Assign with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Assign (X, Y);
      Assert (Length (X) = 0, "Assign on empty set");
      Create_Non_Empty_Set (X);
      for I in 7 .. 9 loop
         Insert (Y, I);
      end loop;
      Assign (X, Y);
      Assert (Length (X) = 3, "Assign non empty sets");
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      procedure Test_No_Capacity is
         X : Set (1000, Default_Modulus (1000));
      begin
         declare
            Y : constant Set := Copy (X);
         begin
            Assert (Is_Empty (Y), "Copy no capacity of empty set");
         end;
         Create_Non_Empty_Set (X);
         declare
            Y : constant Set := Copy (X);
         begin
            Assert (Y = X, "Copy no capacity of non-empty set");
         end;
      end Test_No_Capacity;

      procedure Test_With_Capacity is
         X : Set (100, Default_Modulus (100));
      begin
         declare
            Y : constant Set := Copy (X, 200);
         begin
            Assert (Is_Empty (Y), "Copy with capacity of empty set");
         end;
         Create_Non_Empty_Set (X);
         declare
            Y : constant Set := Copy (X, 200);
         begin
            Assert (Y.Capacity = 200, "Copy with capacity, correct capacity");
            Assert (Y = X, "Copy with capacity of non-empty set");
         end;
      end Test_With_Capacity;
   begin
      Test_No_Capacity;
      Test_With_Capacity;
   end Test_Copy;

   procedure Test_Element with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Assert (Element (X, First (X)) in 1 .. 5, "Element on non-empty set");
   end Test_Element;

   procedure Test_Replace_Element with Pre => True is
      X      : Set (1000, Default_Modulus (1000));
      P1, P2 : Cursor;
      E1, E2 : Integer;
   begin
      Create_Non_Empty_Set (X);
      P1 := First (X);
      P2 := Next (X, P1);
      E1 := Element (X, P1);
      E2 := Element (X, P2);

      Replace_Element (X, P2, E2 + 100);

      Assert (Element (X, P2) = E2 + 100, "Replace_Element in same bucket, the element is replaced");
      Assert (Length (X) = 5, "Replace_Element in same bucket, length is preserved");
      Assert (Element (X, P1) = E1, "Replace_Element in same bucket, other elements are preserved");

      Replace_Element (X, P2, 0);

      Assert (Element (X, P2) = 0, "Replace_Element in other bucket, the element is replaced");
      Assert (Length (X) = 5, "Replace_Element in other bucket, length is preserved");
      Assert (Element (X, P1) = E1, "Replace_Element in other bucket, other elements are preserved");
   end Test_Replace_Element;

   procedure Test_Constant_Reference with Pre => True is
      X  : aliased Set (1000, Default_Modulus (1000));
      P1 : Cursor;
      E1 : Integer;
   begin
      Create_Non_Empty_Set (X);
      P1 := First (X);
      E1 := Element (X, P1);

      Assert (Constant_Reference (X, P1).all = E1, "Constant_Reference on non-empty set");
   end Test_Constant_Reference;

   procedure Test_Move with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Move (X, Y);
      Assert (Is_Empty (X) and Is_Empty (Y), "Move of empty set");
      Create_Non_Empty_Set (X);
      for I in 7 .. 9 loop
         Insert (Y, I);
      end loop;
      Move (X, Y);
      Assert (Length (X) = 3 and Is_Empty (Y), "Move of non-empty set");
   end Test_Move;

   --  Insert with Position and Inserted parameters
   procedure Test_Insert_1 with Pre => True is
      X                     : Set (1000, Default_Modulus (1000));
      P1, P11, P21, P31, P2 : Cursor;
      B1, B2, B3            : Boolean;
   begin
      Insert (X, 1, P1, B1);
      Assert (B1, "Conditional Insert in empty set, element can be inserted");
      Assert (Length (X) = 1, "Conditional Insert in empty set, length is incremented");
      Assert (Element (X, P1) = 1, "Conditional Insert in empty set, New_Item is designated by Position");

      Insert (X, 101, P11, B1);
      Insert (X, 201, P21, B2);
      Insert (X, 301, P31, B3);
      Assert (B1 and B2 and B3, "Conditional Insert in existing bucket, new element can be inserted");
      Assert (Length (X) = 4, "Conditional Insert in existing bucket, length is incremented");
      Assert (Element (X, P11) = 101 and Element (X, P21) = 201 and Element (X, P31) = 301, "Conditional Insert in existing bucket, New_Item is designated by Position");

      Insert (X, 2, P2, B1);
      Assert (B1, "Conditional Insert in new bucket, new element can be inserted");
       Assert (Length (X) = 5, "Conditional Insert in new bucket, length is incremented");
      Assert (Element (X, P2) = 2, "Conditional Insert in new bucket, New_Item is designated by Position");
      Assert (Element (X, P1) = 1, "Conditional Insert in new bucket, existing Cursor/Element mappings are preserved");

      Insert (X, 1002, P2, B1);
      Insert (X, 1201, P21, B2);
      Assert (not B1 and not B2, "Conditional Insert of existing value, element is not inserted");
      Assert (Length (X) = 5, "Conditional Insert of existing value, length is preserved");
      Assert (Element (X, P2) = 2 and Element (X, P21) = 201, "Conditional Insert of existing value, Position designates the right value in Container");
   end Test_Insert_1;

   --  Insert without Position nor Inserted parameters
   procedure Test_Insert_2 with Pre => True is
      X       : Set (1000, Default_Modulus (1000));
      P21, P2 : Cursor;
   begin
      Insert (X, 1);
      Assert (Length (X) = 1, "Insert in empty set, length is incremented");
      Assert (Contains (X, 1), "Insert in empty set, New_Item is in X");

      Insert (X, 101);
      Insert (X, 201);
      Insert (X, 301);
      Assert (Length (X) = 4, "Insert in existing bucket, length is incremented");
      Assert (Contains (X, 101) and Contains (X, 201) and Contains (X, 301), "Insert in existing bucket, New_Item is in X");

      Insert (X, 2);
      Assert (Length (X) = 5, "Insert in new bucket, length is incremented");
      Assert (Contains (X, 2), "Insert in new bucket, New_Item is in X");
      Assert (Contains (X, 1), "Insert in new bucket, existing elements are preserved");

      P21 := Find (X, 201);
      P2 := Find (X, 2);
      Assert (Element (X, P2) = 2 and Element (X, P21) = 201, "Insert, precise value of inserted values");
   end Test_Insert_2;

   procedure Test_Include with Pre => True is
      X       : Set (1000, Default_Modulus (1000));
      P21, P2 : Cursor;
   begin
      Include (X, 1);
      Assert (Length (X) = 1, "Include in empty set, length is incremented");
      Assert (Contains (X, 1), "Include in empty set, New_Item is in X");

      Include (X, 101);
      Include (X, 201);
      Include (X, 301);
      Assert (Length (X) = 4, "Include in existing bucket, length is incremented");
      Assert (Contains (X, 101) and Contains (X, 201) and Contains (X, 301), "Include in existing bucket, New_Item is in X");

      Include (X, 2);
      Assert (Length (X) = 5, "Include in new bucket, length is incremented");
      Assert (Contains (X, 2), "Include in new bucket, New_Item is in X");
      Assert (Contains (X, 1), "Include in new bucket, existing elements are preserved");

      P21 := Find (X, 201);
      P2 := Find (X, 2);
      Assert (Element (X, P2) = 2 and Element (X, P21) = 201, "Include, precise value of included values");

      Include (X, 1002);
      Include (X, 1201);
      Assert (Length (X) = 5, "Include of existing value, length is preserved");
      Assert (Element (X, P2) = 1002 and Element (X, P21) = 1201, "Include of existing value, values are replaced");
   end Test_Include;

   procedure Test_Replace with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      P, Q : Cursor;
   begin
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Q := Find (X, 1);
      Replace (X, 1003);

      Assert (Length (X) = 5, "Replace without collisions, length is preserved");
      Assert (Element (X, P) = 1003, "Replace without collisions, element is updated");
      Assert (Element (X, Q) = 1, "Replace without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      P := Find (Y, 300);
      Q := Find (Y, 100);
      Replace (Y, 1300);

      Assert (Length (Y) = 5, "Replace with collisions, length is preserved");
      Assert (Element (Y, P) = 1300, "Replace with collisions, element is updated");
      Assert (Element (Y, Q) = 100, "Replace with collisions, other elements are preserved");
   end Test_Replace;

   procedure Test_Exclude with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      Q    : Cursor;
   begin
      Exclude (X, 1);
      Assert (Length (X) = 0, "Exclude on empty set");

      Create_Non_Empty_Set (X);
      Exclude (X, 6);

      Assert (Length (X) = 5, "Exclude without collisions, element not is set");

      Q := Find (X, 1);
      Exclude (X, 1003);

      Assert (Length (X) = 4, "Exclude without collisions, length is decremented");
      Assert (not Contains (X, 3), "Exclude without collisions, element is removed");
      Assert (Element (X, Q) = 1, "Exclude without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      Exclude (Y, 600);

      Assert (Length (Y) = 5, "Exclude with collisions, element not is set");

      Q := Find (Y, 100);
      Exclude (Y, 1300);

      Assert (Length (Y) = 4, "Exclude with collisions, length is decremented");
      Assert (not Contains (Y, 300), "Exclude with collisions, element is removed");
      Assert (Element (Y, Q) = 100, "Exclude with collisions, other elements are preserved");
   end Test_Exclude;

   --  Delete an element from the set
   procedure Test_Delete_1 with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      Q    : Cursor;
   begin
      Create_Non_Empty_Set (X);
      Q := Find (X, 1);
      Delete (X, 1003);

      Assert (Length (X) = 4, "Delete element without collisions, length is decremented");
      Assert (not Contains (X, 3), "Delete without collisions, element is removed");
      Assert (Element (X, Q) = 1, "Delete without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      Q := Find (Y, 100);
      Delete (Y, 1300);

      Assert (Length (Y) = 4, "Delete element with collisions, length is decremented");
      Assert (not Contains (Y, 300), "Delete element with collisions, element is removed");
      Assert (Element (Y, Q) = 100, "Delete element with collisions, other elements are preserved");
   end Test_Delete_1;

   --  Delete a cursor
   procedure Test_Delete_2 with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      P, Q : Cursor;
   begin
      Create_Non_Empty_Set (X);
      P := Find (X, 1003);
      Q := Find (X, 1);
      Delete (X, P);

      Assert (Length (X) = 4, "Delete cursor without collisions, length is decremented");
      Assert (not Contains (X, 3), "Delete cursor without collisions, element is removed");
      Assert (Element (X, Q) = 1, "Delete cursor without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      P := Find (Y, 1300);
      Q := Find (Y, 100);
      Delete (Y, P);

      Assert (Length (Y) = 4, "Delete cursor with collisions, length is decremented");
      Assert (not Contains (Y, 300), "Delete cursor with collisions, element is removed");
      Assert (Element (Y, Q) = 100, "Delete cursor with collisions, other elements are preserved");
   end Test_Delete_2;

   --  Union procedure
   procedure Test_Union_1 with Pre => True is
      X, Y, Z : Set (1000, Default_Modulus (1000));
   begin
      Union (X, Y);
      Assert (Is_Empty (X), "Union of empty sets");

      Create_Non_Empty_Set (X);
      Union (Y, X);
      Assert (Y = X, "Union with empty left");
      Union (Y, Z);
      Assert (Y = X, "Union with empty right");

      for I in 4 .. 8 loop
         Insert (Z, I);
      end loop;
      Union (Y, Z);
      Assert ((for all E of Y => Contains (X, E) or Contains (Z, E)), "Union of non-empty sets, no additional element");
      Assert (Is_Subset (X, Y), "Union of non-empty sets, Is_Subset left");
      Assert (Is_Subset (Z, Y), "Union of non-empty sets, Is_Subset right");
   end Test_Union_1;

   --  Union function
   procedure Test_Union_2 with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      declare
         Z : Set := Union (X, Y);
      begin
         Assert (Is_Empty (Z), "Union function of empty sets");
      end;

      Create_Non_Empty_Set (X);
      declare
         Z : Set := Union (Y, X);
      begin
         Assert (Z = X, "Union function with empty left");
      end;
      declare
         Z : Set := Union (X, Y);
      begin
         Assert (Z = X, "Union function with empty right");
      end;

      for I in 4 .. 8 loop
         Insert (Y, I);
      end loop;
      declare
         Z : Set := Union (X, Y);
      begin
         Assert ((for all E of Z => Contains (X, E) or Contains (Y, E)), "Union function of non-empty sets, no additional element");
         Assert (Is_Subset (X, Z), "Union function of non-empty sets, Is_Subset left");
         Assert (Is_Subset (Y, Z), "Union function of non-empty sets, Is_Subset right");
      end;
   end Test_Union_2;

   --  Intersection procedure
   procedure Test_Intersection_1 with Pre => True is
      X, Y, Z : Set (1000, Default_Modulus (1000));
   begin
      Union (X, Y);
      Assert (Is_Empty (X), "Intersection of empty sets");

      Create_Non_Empty_Set (X);
      Intersection (Y, X);
      Assert (Is_Empty (Y), "Intersection with empty left");
      Z := X;
      Intersection (Z, Y);
      Assert (Is_Empty (Z), "Intersection with empty right");

      for I in 4 .. 8 loop
         Insert (Z, I);
      end loop;
      Y := X;
      Intersection (Y, Z);
      Assert (Contains (Y, 4) and Contains (Y, 5), "Intersection of non-empty sets, contains elements in both");
      Assert (Is_Subset (Y, X), "Intersection of non-empty sets, Is_Subset left");
      Assert (Is_Subset (Y, Z), "Intersection of non-empty sets, Is_Subset right");
   end Test_Intersection_1;

   --  Intersection function
   procedure Test_Intersection_2 with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      declare
         Z : Set := Intersection (X, Y);
      begin
         Assert (Is_Empty (Z), "Intersection function of empty sets");
      end;

      Create_Non_Empty_Set (X);
      declare
         Z : Set := Intersection (Y, X);
      begin
         Assert (Is_Empty (Z), "Intersection function with empty left");
      end;
      declare
         Z : Set := Intersection (X, Y);
      begin
         Assert (Is_Empty (Z), "Intersection function with empty right");
      end;

      for I in 4 .. 8 loop
         Insert (Y, I);
      end loop;
      declare
         Z : Set := Intersection (X, Y);
      begin
         Assert (Contains (Z, 4) and Contains (Z, 5), "Intersection function of non-empty sets, contains elements in both");
         Assert (Is_Subset (Z, X), "Intersection function of non-empty sets, Is_Subset left");
         Assert (Is_Subset (Z, Y), "Intersection function of non-empty sets, Is_Subset right");
      end;
   end Test_Intersection_2;

   --  Difference procedure
   procedure Test_Difference_1 with Pre => True is
      X, Y, Z : Set (1000, Default_Modulus (1000));
   begin
      Union (X, Y);
      Assert (Is_Empty (X), "Difference of empty sets");

      Create_Non_Empty_Set (X);
      Difference (Y, X);
      Assert (Is_Empty (Y), "Difference with empty left");
      Y := X;
      Difference (Y, Z);
      Assert (Y = X, "Difference with empty right");

      for I in 4 .. 7 loop
         Insert (Z, I);
      end loop;
      Difference (Y, Z);
      Assert ((for all E of X => (if not Contains (Z, E) then Contains (Y, E))), "Difference of non-empty sets, contains elements not in right");
      Assert (Is_Subset (Y, X), "Difference of non-empty sets, Is_Subset left");
      Assert (not Overlap (Y, Z), "Difference of non-empty sets, no overlap right");

      --  Same as above but with parameters reversed
      Y := X;
      X := Z;
      Difference (Z, Y);
      Assert ((for all E of X => (if not Contains (Y, E) then Contains (Z, E))), "Difference of non-empty sets reverse, contains elements not in right");
      Assert (Is_Subset (Z, X), "Difference of non-empty set reverses, Is_Subset left");
      Assert (not Overlap (Y, Z), "Difference of non-empty sets reverse, no overlap right");
   end Test_Difference_1;

   --  Difference function
   procedure Test_Difference_2 with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      declare
         Z : Set := Difference (X, Y);
      begin
         Assert (Is_Empty (Z), "Difference function of empty sets");
      end;

      Create_Non_Empty_Set (X);
      declare
         Z : Set := Difference (Y, X);
      begin
         Assert (Is_Empty (Z), "Difference function with empty left");
      end;
      declare
         Z : Set := Difference (X, Y);
      begin
         Assert (Z = X, "Difference function with empty right");
      end;

      for I in 4 .. 8 loop
         Insert (Y, I);
      end loop;
      declare
         Z : Set := Difference (X, Y);
      begin
         Assert ((for all E of X => (if not Contains (Y, E) then Contains (Z, E))), "Difference function of non-empty sets, contains elements not in right");
         Assert (Is_Subset (Z, X), "Difference function of non-empty sets, Is_Subset left");
         Assert (not Overlap (Y, Z), "Difference function of non-empty sets, no overlap right");
      end;
   end Test_Difference_2;

   --  Symmetric_Difference procedure
   procedure Test_Symmetric_Difference_1 with Pre => True is
      X, Y, Z : Set (1000, Default_Modulus (1000));
   begin
      Union (X, Y);
      Assert (Is_Empty (X), "Symmetric_Difference of empty sets");

      Create_Non_Empty_Set (X);
      Symmetric_Difference (Y, X);
      Assert (Y = X, "Symmetric_Difference with empty left");
      Symmetric_Difference (Y, Z);
      Assert (Y = X, "Symmetric_Difference with empty right");

      for I in 4 .. 8 loop
         Insert (Z, I);
      end loop;
      Symmetric_Difference (Y, Z);
      Assert ((for all E of X => (if not Contains (Z, E) then Contains (Y, E))), "Symmetric_Difference of non-empty sets, contains all elements of left not in right");
      Assert ((for all E of Z => (if not Contains (X, E) then Contains (Y, E))), "Symmetric_Difference of non-empty sets, contains all elements of right not in left");
      Assert (Is_Subset (Y, Union (X, Z)), "Symmetric_Difference of non-empty sets, contains only elements of left or right");
   end Test_Symmetric_Difference_1;

   --  Symmetric_Difference function
   procedure Test_Symmetric_Difference_2 with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      declare
         Z : Set := Symmetric_Difference (X, Y);
      begin
         Assert (Is_Empty (Z), "Symmetric_Difference function of empty sets");
      end;

      Create_Non_Empty_Set (X);
      declare
         Z : Set := Symmetric_Difference (Y, X);
      begin
         Assert (Z = X, "Symmetric_Difference function with empty left");
      end;
      declare
         Z : Set := Symmetric_Difference (X, Y);
      begin
         Assert (Z = X, "Symmetric_Difference function with empty right");
      end;

      for I in 4 .. 8 loop
         Insert (Y, I);
      end loop;
      declare
         Z : Set := Symmetric_Difference (X, Y);
      begin
         Assert ((for all E of X => (if not Contains (Y, E) then Contains (Z, E))), "Symmetric_Difference of non-empty sets, contains all elements of left not in right");
         Assert ((for all E of Y => (if not Contains (X, E) then Contains (Z, E))), "Symmetric_Difference of non-empty sets, contains all elements of right not in left");
         Assert (Is_Subset (Z, Union (X, Y)), "Symmetric_Difference of non-empty sets, contains only elements of left or right");
      end;
   end Test_Symmetric_Difference_2;

   procedure Test_Overlap with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Assert (not Overlap (X, Y) and not Overlap (Y, X) and not Overlap (Y, Y), "Overlap on empty set");
      Assert (Overlap (X, X), "Overlap on same set");

      for I in 6 .. 8 loop
         Insert (Y, I);
      end loop;
      Assert (not Overlap (X, Y), "Overlap on distinct sets");

      Insert (Y, 1003);
      Assert (Overlap (X, Y), "Overlap uses equivalence on elements");
   end Test_Overlap;

   procedure Test_Is_Subset with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Assert (not Is_Subset (X, Y) and Is_Subset (Y, X) and Is_Subset (Y, Y), "Is_Subset on empty set");
      Assert (Is_Subset (X, X), "Is_Subset on same set");

      for I in 1003 .. 1005 loop
         Insert (Y, I);
      end loop;
      Assert (Is_Subset (Y, X), "Is_Subset uses equivalence on elements");

      Insert (Y, 130);
      Assert (not Is_Subset (Y, X), "Is_Subset returns False with distinct element");
   end Test_Is_Subset;

   procedure Test_First with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Assert (First (X) = No_Element, "First on empty set");
      Create_Non_Empty_Set (X);
      Assert (Has_Element (X, First (X)) and Element (X, First (X)) in 1 .. 5, "First on non empty set");
   end Test_First;

   procedure Test_Next with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      P : Cursor := No_Element;
   begin
      Create_Non_Empty_Set (X);

      Assert (Next (X, P) = No_Element, "Next function on No_Element");
      Next (X, P);
      Assert (P = No_Element, "Next procedure on No_Element");

      P := First (X);
      Assert (Has_Element (X, Next (X, P)), "Next function without collisions");
      Next (X, P);
      Assert (Has_Element (X, P), "Next procedure without collisions");

      Create_Non_Empty_Set_With_Collisions (Y);

      P := First (Y);
      Assert (Has_Element (Y, Next (Y, P)), "Next function with collisions");
      Next (Y, P);
      Assert (Has_Element (Y, P), "Next procedure with collisions");
   end Test_Next;

   procedure Test_Find with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert (Find (X, 1) = No_Element, "Find on empty set");

      Create_Non_Empty_Set (X);

      Assert (Find (X, 1) /= No_Element and Find (X, 5) /= No_Element, "Find without collisions, element is present");
      Assert (Find (X, 7) = No_Element, "Find without collisions, element is not present");
      Assert (Find (X, 1004) /= No_Element, "Find without collisions, use provided equivalence function");

      Create_Non_Empty_Set_With_Collisions (Y);

      Assert (Find (Y, 100) /= No_Element and Find (Y, 500) /= No_Element, "Find with collisions, element is present");
      Assert (Find (Y, 7) = No_Element, "Find with collisions, element is not present");
      Assert (Find (Y, 1400) /= No_Element, "Find with collisions, use provided equivalence function");
   end Test_Find;

   procedure Test_Contains with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert (not Contains (X, 1), "Contains on empty set");

      Create_Non_Empty_Set (X);

      Assert (Contains (X, 1) and Contains (X, 5), "Contains without collisions, element is present");
      Assert (not Contains (X, 7), "Contains without collisions, element is not present");
      Assert (Contains (X, 1004), "Contains without collisions, use provided equivalence function");

      Create_Non_Empty_Set_With_Collisions (Y);

      Assert (Contains (Y, 100) and Contains (Y, 500), "Contains with collisions, element is present");
      Assert (not Contains (Y, 7), "Contains with collisions, element is not present");
      Assert (Contains (Y, 1400), "Contains with collisions, use provided equivalence function");
   end Test_Contains;

   procedure Test_Has_Element with Pre => True is
      X : Set (1000, Default_Modulus (1000));
      P : Cursor;
   begin
      Create_Non_Empty_Set (X);
      Assert (not Has_Element (X, No_Element), "Has_Element on No_Element");
      P := Find (X, 3);
      Assert (Has_Element (X, P), "Has_Element returns True");
      Delete (X, 3);
      Assert (not Has_Element (X, P), "Has_Element returns False");
   end Test_Has_Element;

   procedure Test_Default_Modulus with Pre => True is
      I : Hash_Type;
   begin
      I := Default_Modulus (0);
      I := Default_Modulus (Count_Type'Last);
      I := Default_Modulus (Count_Type'Last / 2);
   end Test_Default_Modulus;

   procedure Test_Key with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Assert (Int_Sets_Keys.Key (X, First (X)) in 1 .. 5, "Generic_Keys.Key on non-empty set");
   end Test_Key;

   procedure Test_Element_Key with Pre => True is
      X : Set (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Set (X);
      Assert (Int_Sets_Keys.Element (X, 1) in 1, "Generic_Keys.Element on non-empty set");
   end Test_Element_Key;

   procedure Test_Replace_Key with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      P, Q : Cursor;
   begin
      Create_Non_Empty_Set (X);
      P := Int_Sets_Keys.Find (X, 3);
      Q := Int_Sets_Keys.Find (X, 1);
      Int_Sets_Keys.Replace (X, 3, 1003);

      Assert (Length (X) = 5, "Replace without collisions, length is preserved");
      Assert (Element (X, P) = 1003, "Replace without collisions, element is updated");
      Assert (Element (X, Q) = 1, "Replace without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      P := Int_Sets_Keys.Find (Y, 300);
      Q := Int_Sets_Keys.Find (Y, 100);
      Int_Sets_Keys.Replace (Y, 300, 1300);

      Assert (Length (Y) = 5, "Replace with collisions, length is preserved");
      Assert (Element (Y, P) = 1300, "Replace with collisions, element is updated");
      Assert (Element (Y, Q) = 100, "Replace with collisions, other elements are preserved");
   end Test_Replace_Key;

   procedure Test_Exclude_Key with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      Q    : Cursor;
   begin
      Int_Sets_Keys.Exclude (X, 1);
      Assert (Length (X) = 0, "Exclude on empty set");

      Create_Non_Empty_Set (X);
      Int_Sets_Keys.Exclude (X, 6);

      Assert (Length (X) = 5, "Exclude without collisions, element not is set");

      Q := Int_Sets_Keys.Find (X, 1);
      Int_Sets_Keys.Exclude (X, 3);

      Assert (Length (X) = 4, "Exclude without collisions, length is decremented");
      Assert (not Int_Sets_Keys.Contains (X, 3), "Exclude without collisions, element is removed");
      Assert (Element (X, Q) = 1, "Exclude without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      Int_Sets_Keys.Exclude (Y, 600);

      Assert (Length (Y) = 5, "Exclude with collisions, element not is set");

      Q := Int_Sets_Keys.Find (Y, 100);
      Int_Sets_Keys.Exclude (Y, 300);

      Assert (Length (Y) = 4, "Exclude with collisions, length is decremented");
      Assert (not Int_Sets_Keys.Contains (Y, 300), "Exclude with collisions, element is removed");
      Assert (Element (Y, Q) = 100, "Exclude with collisions, other elements are preserved");
   end Test_Exclude_Key;

   procedure Test_Delete_Key with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
      Q    : Cursor;
   begin
      Create_Non_Empty_Set (X);
      Q := Int_Sets_Keys.Find (X, 1);
      Int_Sets_Keys.Delete (X, 3);

      Assert (Length (X) = 4, "Delete element without collisions, length is decremented");
      Assert (not Int_Sets_Keys.Contains (X, 3), "Delete without collisions, element is removed");
      Assert (Element (X, Q) = 1, "Delete without collisions, other elements are preserved");

      Create_Non_Empty_Set_With_Collisions (Y);
      Q := Int_Sets_Keys.Find (Y, 100);
      Int_Sets_Keys.Delete (Y, 300);

      Assert (Length (Y) = 4, "Delete element with collisions, length is decremented");
      Assert (not Int_Sets_Keys.Contains (Y, 300), "Delete element with collisions, element is removed");
      Assert (Element (Y, Q) = 100, "Delete element with collisions, other elements are preserved");
   end Test_Delete_Key;

   procedure Test_Find_Key with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert (Int_Sets_Keys.Find (X, 1) = No_Element, "Find on empty set");

      Create_Non_Empty_Set (X);

      Assert (Int_Sets_Keys.Find (X, 1) /= No_Element and Int_Sets_Keys.Find (X, 5) /= No_Element, "Find without collisions, element is present");
      Assert (Int_Sets_Keys.Find (X, 7) = No_Element, "Find without collisions, element is not present");

      Create_Non_Empty_Set_With_Collisions (Y);

      Assert (Int_Sets_Keys.Find (Y, 100) /= No_Element and Int_Sets_Keys.Find (Y, 500) /= No_Element, "Find with collisions, element is present");
      Assert (Int_Sets_Keys.Find (Y, 7) = No_Element, "Find with collisions, element is not present");
   end Test_Find_Key;

   procedure Test_Contains_Key with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert (not Int_Sets_Keys.Contains (X, 1), "Contains on empty set");

      Create_Non_Empty_Set (X);

      Assert (Int_Sets_Keys.Contains (X, 1) and Int_Sets_Keys.Contains (X, 5), "Contains without collisions, element is present");
      Assert (not Int_Sets_Keys.Contains (X, 7), "Contains without collisions, element is not present");

      Create_Non_Empty_Set_With_Collisions (Y);

      Assert (Int_Sets_Keys.Contains (Y, 100) and Int_Sets_Keys.Contains (Y, 500), "Contains with collisions, element is present");
      Assert (not Int_Sets_Keys.Contains (Y, 7), "Contains with collisions, element is not present");
   end Test_Contains_Key;

   procedure Test_Iteration with Pre => True is
      X, Y : Set (1000, Default_Modulus (1000));
   begin
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, empty set");
      Assert ((for all E of X => E /= 0), "for of iteration, empty set");

      Create_Non_Empty_Set (X);
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, non-empty set without collisions");
      Assert ((for some E of X => E = 3), "for of iteration, non-empty set without collisions");

      Create_Non_Empty_Set_With_Collisions (Y);
      Assert ((for all P in Y => Element (Y,  P) /= 0), "for in iteration, non-empty set with collisions");
      Assert ((for some E of Y => E = 300), "for of iteration, non-empty set with collisions");
   end Test_Iteration;

   procedure Test_Aggregate with Pre => True is
      X : Set := [1, 2, 3, 4, 5];
   begin
      Assert (Length (X) = 5, "aggregate, length");
      Assert (Contains (X, 1) and Contains (X, 5), "aggregate, elements");
   end Test_Aggregate;

begin
   Test_Empty_Set;
   Test_Length;
   Test_Eq;
   Test_Equivalent_Sets;
   Test_To_Set;
   Test_Capacity;
   Test_Reserve_Capacity;
   Test_Is_Empty;
   Test_Clear;
   Test_Assign;
   Test_Copy;
   Test_Element;
   Test_Replace_Element;
   Test_Constant_Reference;
   Test_Move;
   Test_Insert_1;
   Test_Insert_2;
   Test_Include;
   Test_Replace;
   Test_Exclude;
   Test_Delete_1;
   Test_Delete_2;
   Test_Union_1;
   Test_Union_2;
   Test_Intersection_1;
   Test_Intersection_2;
   Test_Difference_1;
   Test_Difference_2;
   Test_Symmetric_Difference_1;
   Test_Symmetric_Difference_2;
   Test_Overlap;
   Test_Is_Subset;
   Test_First;
   Test_Next;
   Test_Find;
   Test_Contains;
   Test_Has_Element;
   Test_Default_Modulus;
   Test_Key;
   Test_Element_Key;
   Test_Replace_Key;
   Test_Exclude_Key;
   Test_Delete_Key;
   Test_Find_Key;
   Test_Contains_Key;
   Test_Iteration;
   Test_Aggregate;
end Test;
