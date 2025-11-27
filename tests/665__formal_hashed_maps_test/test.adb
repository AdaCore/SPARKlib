with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst;
use Inst.Int_Maps;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  A formal hashed map is implemented as several map structures inside a
   --  single array of values. They contain elements corresponding to the same
   --  hash modulo the number of buckets (aka modulus) in the structure. The
   --  head of these maps are stored in a separate array for easier access.

   --  Create map with 5 elements

   procedure Create_Non_Empty_Map (X : in out Map) with
     Pre  => X.Capacity >= 5,
     Post => Length (X) = 5
     and (for all K of X => K in 1 .. 5)
     and (for all K in 1 .. 5 => Contains (X, K))
     and (for all K of X => Element (X, K) = Integer'(K)) is
   begin
      Clear (X);
      for I in 1 .. 5 loop
         Insert (X, I, I);
      end loop;
   end Create_Non_Empty_Map;

   procedure Create_Non_Empty_Map_With_Collisions (X : in out Map) with
     Pre  => X.Capacity >= 5,
     Post => Length (X) = 5
     and (for all K of X => K in 100 | 200 | 300 | 400 | 500)
     and Contains (X, 100) and Contains (X, 200) and Contains (X, 300) and Contains (X, 400) and Contains (X, 500)
     and (for all K of X => Element (X, K) = Integer'(K)) is
   begin
      Clear (X);
      for I in 1 .. 5 loop
         Insert (X, I * 100, I * 100);
      end loop;
   end Create_Non_Empty_Map_With_Collisions;

   procedure Test_Empty_Map with Pre => True is
      X : Map := Empty_Map (1000);
   begin
      Assert (Length (X) = 0, "Empty_Map is empty");
   end Test_Empty_Map;

   procedure Test_Length with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Assert (Length (X) = 0, "Length on empty map");
      Create_Non_Empty_Map (X);
      Assert (Length (X) = 5, "Length on non-empty map");
   end Test_Length;

   procedure Test_Eq with Pre => True is
      X, Y, Z : Map (1000, Default_Modulus (1000));
   begin
      Assert (X = Y, """="" on empty maps");

      Create_Non_Empty_Map (X);
      Assert (X /= Y and Y /= X, """="" on empty and non-empty maps");

      Insert (Y, 1, 1);
      Assert (X /= Y, """="" on maps with different lengths");

      Y := X;
      Assert (X = X, """="" on same map");
      Assert (X = Y, """="" on copied map");

      Z := X;
      Insert (X, 6, 6);
      Insert (Y, 1006, 6);
      Assert (X = Y, """="" uses equivalence on keys");

      X := Z;
      Y := Z;
      Insert (X, 6, 6);
      Insert (Y, 6, 1006);
      Assert (X = Y, """="" uses equality on elements");

      X := Z;
      Y := Z;
      Insert (X, 6, 6);
      Insert (Y, 7, 6);
      Assert (X /= Y, """="" on maps with different keys");

      X := Z;
      Y := Z;
      Insert (X, 6, 6);
      Insert (Y, 6, 7);
      Assert (X /= Y, """="" on maps with different elements");
   end Test_Eq;

   procedure Test_Capacity with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Assert (Capacity (X) = 1000, "Capacity returns the Capacity discriminant");
   end Test_Capacity;

   procedure Test_Reserve_Capacity with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Reserve_Capacity (X, 200);
      Assert (Is_Empty (X), "Reserve_Capacity on empty map does not do anything");
      Create_Non_Empty_Map (X);
      Reserve_Capacity (X, 2);
      Reserve_Capacity (X, 200);
      Assert (Length (X) = 5, "Reserve_Capacity on non-empty map does not do anything");
   end Test_Reserve_Capacity;

   procedure Test_Is_Empty with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Assert (Is_Empty (X), "Is_Empty on empty map");
      Create_Non_Empty_Map (X);
      Assert (not Is_Empty (X), "Is_Empty on non-empty map");
   end Test_Is_Empty;

   procedure Test_Clear with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Clear (X);
      Assert (Is_Empty (X), "Clear on empty map");
      Create_Non_Empty_Map (X);
      Clear (X);
      Assert (Is_Empty (X), "Clear on non-empty map");
   end Test_Clear;

   procedure Test_Assign with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Map (X);
      Assign (X, Y);
      Assert (Length (X) = 0, "Assign on empty map");
      Create_Non_Empty_Map (X);
      for I in 7 .. 9 loop
         Insert (Y, I, I);
      end loop;
      Assign (X, Y);
      Assert (Length (X) = 3, "Assign non-empty maps");
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      procedure Test_No_Capacity is
         X : Map (1000, Default_Modulus (1000));
      begin
         declare
            Y : constant Map := Copy (X);
         begin
            Assert (Is_Empty (Y), "Copy no capacity of empty map");
         end;
         Create_Non_Empty_Map (X);
         declare
            Y : constant Map := Copy (X);
         begin
            Assert (Y = X, "Copy no capacity of non-empty map");
         end;
      end Test_No_Capacity;

      procedure Test_With_Capacity is
         X : Map (100, Default_Modulus (100));
      begin
         declare
            Y : constant Map := Copy (X, 200);
         begin
            Assert (Is_Empty (Y), "Copy with capacity of empty map");
         end;
         Create_Non_Empty_Map (X);
         declare
            Y : constant Map := Copy (X, 200);
         begin
            Assert (Y.Capacity = 200, "Copy with capacity, correct capacity");
            Assert (Y = X, "Copy with capacity of non-empty map");
         end;
      end Test_With_Capacity;
   begin
      Test_No_Capacity;
      Test_With_Capacity;
   end Test_Copy;

   procedure Test_Key with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Map (X);
      Assert (Key (X, First (X)) in 1 .. 5, "Key on non-empty map");
   end Test_Key;

   --  Element on a cursor
   procedure Test_Element_1 with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Map (X);
      Assert (Element (X, First (X)) = Natural'(Key (X, First (X))), "Element on a cursor");
   end Test_Element_1;

   --  Element on a key
   procedure Test_Element_2 with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Map (X);
      Assert (Element (X, 1) = 1, "Element on a key");
   end Test_Element_2;

   procedure Test_Replace_Element with Pre => True is
      X      : Map (1000, Default_Modulus (1000));
      P1, P2 : Cursor;
      E1 : Integer;
      K1, K2 : Natural;
   begin
      Create_Non_Empty_Map (X);
      P1 := First (X);
      P2 := Next (X, P1);
      K1 := Key (X, P1);
      K2 := Key (X, P2);
      E1 := Element (X, P1);

      Replace_Element (X, P2, 0);

      Assert (Element (X, P2) = 0, "Replace_Element, the element is replaced");
      Assert (Length (X) = 5, "Replace_Element, length is preserved");
      Assert (Key (X, P1) = K1 and Key (X, P2) = K2, "Replace_Element, keys are preserved");
      Assert (Element (X, P1) = E1, "Replace_Element, other elements are preserved");
   end Test_Replace_Element;

   --  Constant_Reference on a cursor
   procedure Test_Constant_Reference_1 with Pre => True is
      X  : aliased Map (1000, Default_Modulus (1000));
      P1 : Cursor;
      E1 : Integer;
   begin
      Create_Non_Empty_Map (X);
      P1 := First (X);
      E1 := Element (X, P1);

      Assert (Constant_Reference (X, P1).all = E1, "Constant_Reference on a cursor");
   end Test_Constant_Reference_1;

   --  Constant_Reference on a key
   procedure Test_Constant_Reference_2 with Pre => True is
      X  : aliased Map (1000, Default_Modulus (1000));
      P1 : Cursor;
   begin
      Create_Non_Empty_Map (X);

      Assert (Constant_Reference (X, 2).all = 2, "Constant_Reference on a key");
   end Test_Constant_Reference_2;

   --  Reference on a cursor
   procedure Test_Reference_1 with Pre => True is
      X      : aliased Map (1000, Default_Modulus (1000));
      P2     : Cursor;
      P4     : Cursor;
      K2, K4 : Integer;
      E2, E4 : Integer;
   begin
      Create_Non_Empty_Map (X);
      P2 := Next (X, First (X));
      K2 := Key (X, P2);
      E2 := Element (X, P2);
      P4 := Next (X, Next (X, P2));
      K4 := Key (X, P4);
      E4 := Element (X, P4);

      declare
         R : access Integer := Reference (X, P2);
      begin
         Assert (R.all = E2, "Reference on a cursor, designated value");
         R.all := 0;
      end;

      --  Check that the replacement has been made

      Assert (Has_Element (X, P2) and then Element (X, P2) = 0, "Reference, the element is replaced");
      Assert (Key (X, P2) = K2, "Reference, the key is preserved");
      Assert (Length (X) = 5, "Reference, length is preserved");
      Assert (Has_Element (X, P4) and then Key (X, P4) = K4 and then Element (X, P4) = E4, "Reference, other cursor/key/element mappings are preserved");
      Assert (P2 = Next (X, First (X)) and P4 = Next (X, Next (X, P2)), "Reference, order of cursors is preserved");
   end Test_Reference_1;

   --  Reference on a key
   procedure Test_Reference_2 with Pre => True is
      X : aliased Map (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Map (X);

      declare
         R : access Integer := Reference (X, 2);
      begin
         Assert (R.all = 2, "Reference on non-empty map");
         R.all := 0;
      end;

      --  Check that the replacement has been made

      Assert (Element (X, 2) = 0, "Reference, the element is replaced");
      Assert (Length (X) = 5, "Reference, length is preserved");
      Assert (Element (X, 4) = 4, "Reference, other key/element mappings are preserved");
   end Test_Reference_2;

   procedure Test_Move with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
   begin
      Create_Non_Empty_Map (X);
      Move (X, Y);
      Assert (Is_Empty (X) and Is_Empty (Y), "Move of empty map");
      Create_Non_Empty_Map (X);
      for I in 7 .. 9 loop
         Insert (Y, I, I);
      end loop;
      Move (X, Y);
      Assert (Length (X) = 3 and Is_Empty (Y), "Move of non-empty map");
   end Test_Move;

   --  Insert with Position and Inserted parameters
   procedure Test_Insert_1 with Pre => True is
      X, Y                  : Map (1000, Default_Modulus (1000));
      P1, P11, P21, P31, P2 : Cursor;
      B1, B2, B3            : Boolean;
   begin
      Insert (X, 1, 1, P1, B1);
      Assert (B1, "Conditional Insert in empty map, element can be inserted");
      Assert (Length (X) = 1, "Conditional Insert in empty map, length is incremented");
      Assert (Key (X, P1) = 1, "Conditional Insert in empty map, Key is designated by Position");
      Assert (Element (X, P1) = 1, "Conditional Insert in empty map, New_Item is designated by Position");
      Y := X;

      Insert (X, 101, 101, P11, B1);
      Insert (X, 201, 201, P21, B2);
      Insert (X, 301, 301, P31, B3);
      Assert (B1 and B2 and B3, "Conditional Insert in existing bucket, new element can be inserted");
      Assert (Length (X) = 4, "Conditional Insert in existing bucket, length is incremented");
      Assert (Key (X, P11) = 101 and Key (X, P21) = 201 and Key (X, P31) = 301, "Conditional Insert in existing bucket, Key is designated by Position");
      Assert (Element (X, 101) = 101 and Element (X, 201) = 201 and Element (X, 301) = 301, "Conditional Insert in existing bucket, New_Item is attached to Key");

      Insert (Y, 2, 2, P2, B1);
      Assert (B1, "Conditional Insert in new bucket, new element can be inserted");
      Assert (Length (Y) = 2, "Conditional Insert in new bucket, length is incremented");
      Assert (Key (Y, P2) = 2, "Conditional Insert in new bucket, Key is designated by Position");
      Assert (Element (Y, 2) = 2, "Conditional Insert in new bucket, New_Item is attached to Key");
      Assert (Element (Y, 1) = 1, "Conditional Insert in new bucket, existing Key/Element mappings are preserved");
      Assert (Element (Y, P1) = 1, "Conditional Insert in new bucket, existing Cursor/Key mappings are preserved");

      Insert (Y, 1002, 1002, P2, B1);
      Insert (X, 1201, 1201, P21, B2);
      Assert (not B1 and not B2, "Conditional Insert of existing value, element is not inserted");
      Assert (Length (X) = 4 and Length (Y) = 2, "Conditional Insert of existing value, length is preserved");
      Assert (Key (Y, P2) = 2 and Key (X, P21) = 201, "Conditional Insert of existing value, Position designates the right key in Container");
   end Test_Insert_1;

   --  Insert without Position nor Inserted parameters
   procedure Test_Insert_2 with Pre => True is
      X, Y    : Map (1000, Default_Modulus (1000));
      P21, P2 : Cursor;
   begin
      Insert (X, 1, 1);
      Assert (Length (X) = 1, "Insert in empty map, length is incremented");
      Assert (Contains (X, 1), "Insert in empty map, Key is in X");
      Assert (Element (X, 1) = 1, "Insert in empty map, Key maps to New_Item");

      Insert (X, 101, 101);
      Insert (X, 201, 201);
      Insert (X, 301, 301);
      Assert (Length (X) = 4, "Insert in existing bucket, length is incremented");
      Assert (Contains (X, 101) and Contains (X, 201) and Contains (X, 301), "Insert in existing bucket, Key is in Container");
      Assert (Element (X, 101) = 101 and Element (X, 201) = 201 and Element (X, 301) = 301, "Insert in existing bucket, Key maps to New_Item");

      Insert (Y, 1, 1);
      Insert (Y, 2, 2);
      Assert (Length (Y) = 2, "Insert in new bucket, length is incremented");
      Assert (Contains (Y, 2), "Insert in new bucket, Key is in Container");
      Assert (Element (Y, 2) = 2, "Insert in new bucket, Key maps to New_Item");
      Assert (Element (Y, 1) = 1, "Insert in new bucket, existing elements are preserved");

      P21 := Find (X, 201);
      P2 := Find (Y, 2);
      Assert (Key (Y, P2) = 2 and Key (X, P21) = 201, "Insert, precise key of inserted values");
   end Test_Insert_2;

   procedure Test_Include with Pre => True is
      X, Y    : Map (1000, Default_Modulus (1000));
      P21, P2 : Cursor;
   begin
      Include (X, 1, 1);
      Assert (Length (X) = 1, "Include in empty map, length is incremented");
      Assert (Contains (X, 1), "Include in empty map, Key is in Container");
      Assert (Element (X, 1) = 1, "Include in empty map, Key maps to New_Item");

      Include (X, 101, 101);
      Include (X, 201, 201);
      Include (X, 301, 301);
      Assert (Length (X) = 4, "Include in existing bucket, length is incremented");
      Assert (Contains (X, 101) and Contains (X, 201) and Contains (X, 301), "Include in existing bucket, Key is in Container");
      Assert (Element (X, 101) = 101 and Element (X, 201) = 201 and Element (X, 301) = 301, "Include in existing bucket, Key maps to New_Item");

      Include (Y, 1, 1);
      Include (Y, 2, 2);
      Assert (Length (Y) = 2, "Include in new bucket, length is incremented");
      Assert (Contains (Y, 2), "Include in new bucket, Key is in Container");
      Assert (Element (Y, 2) = 2, "Include in new bucket, Key maps to New_Item");
      Assert (Contains (Y, 1), "Include in new bucket, existing elements are preserved");

      P21 := Find (X, 201);
      P2 := Find (Y, 2);
      Assert (Key (Y, P2) = 2 and Key (X, P21) = 201, "Include, precise key of included values");

      Include (Y, 1002, 1002);
      Include (X, 1201, 1201);
      Assert (Length (X) = 4 and Length (Y) = 2, "Include of existing value, length is preserved");
      Assert (Element (Y, 1002) = 1002 and Element (X, 1201) = 1201, "Include, Key maps to New_Item");
      Assert (Key (Y, P2) = 1002 and Key (X, P21) = 1201, "Include, Key is replaced");
   end Test_Include;

   procedure Test_Replace with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
      P, Q : Cursor;
   begin
      Create_Non_Empty_Map (X);
      P := Find (X, 3);
      Q := Find (X, 1);
      Replace (X, 1003, 1003);

      Assert (Length (X) = 5, "Replace without collisions, length is preserved");
      Assert (Key (X, P) = 1003, "Replace without collisions, key is updated");
      Assert (Element (X, 1003) = 1003, "Replace without collisions, element is updated");
      Assert (Key (X, Q) = 1 and Element (X, 1) = 1, "Replace without collisions, other keys/elements are preserved");

      Create_Non_Empty_Map_With_Collisions (Y);
      P := Find (Y, 300);
      Q := Find (Y, 100);
      Replace (Y, 1300, 1300);

      Assert (Length (Y) = 5, "Replace with collisions, length is preserved");
      Assert (Key (Y, P) = 1300, "Replace with collisions, key is updated");
      Assert (Element (Y, 1300) = 1300, "Replace with collisions, element is updated");
      Assert (Key (Y, Q) = 100 and Element (Y, 100) = 100, "Replace with collisions, other keys/elements are preserved");
   end Test_Replace;

   procedure Test_Exclude with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
      Q    : Cursor;
   begin
      Exclude (X, 1);
      Assert (Length (X) = 0, "Exclude on empty map");

      Create_Non_Empty_Map (X);
      Exclude (X, 6);

      Assert (Length (X) = 5, "Exclude without collisions, key not is map");

      Q := Find (X, 1);
      pragma Assert (Equivalent (3, 1003));
      Exclude (X, 1003);

      Assert (Length (X) = 4, "Exclude without collisions, length is decremented");
      Assert (not Contains (X, 3), "Exclude without collisions, key is removed");
      Assert (Key (X, Q) = 1, "Exclude without collisions, other keys are preserved");
      Assert (Element (X, 1) = 1, "Exclude without collisions, other mappings are preserved");

      Create_Non_Empty_Map_With_Collisions (Y);
      Exclude (Y, 600);

      Assert (Length (Y) = 5, "Exclude with collisions, key not is map");

      Q := Find (Y, 100);
      pragma Assert (Equivalent (300, 1300));
      Exclude (Y, 1300);

      Assert (Length (Y) = 4, "Exclude with collisions, length is decremented");
      Assert (not Contains (Y, 300), "Exclude with collisions, key is removed");
      Assert (Key (Y, Q) = 100, "Exclude with collisions, other keys are preserved");
      Assert (Element (Y, 100) = 100, "Exclude with collisions, other mappings are preserved");
   end Test_Exclude;

   --  Delete a key from the map
   procedure Test_Delete_1 with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
      Q    : Cursor;
   begin
      Create_Non_Empty_Map (X);
      Q := Find (X, 1);
      Delete (X, 1003);

      Assert (Length (X) = 4, "Delete key without collisions, length is decremented");
      Assert (not Contains (X, 3), "Delete without collisions, key is removed");
      Assert (Key (X, Q) = 1, "Delete without collisions, other keys are preserved");
      Assert (Element (X, 1) = 1, "Delete without collisions, other mappings are preserved");

      Create_Non_Empty_Map_With_Collisions (Y);
      Q := Find (Y, 100);
      Delete (Y, 1300);

      Assert (Length (Y) = 4, "Delete key with collisions, length is decremented");
      Assert (not Contains (Y, 300), "Delete key with collisions, key is removed");
      Assert (Key (Y, Q) = 100, "Delete key with collisions, other keys are preserved");
      Assert (Element (Y, 100) = 100, "Delete key with collisions, other mappings are preserved");
   end Test_Delete_1;

   --  Delete a cursor
   procedure Test_Delete_2 with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
      P, Q : Cursor;
   begin
      Create_Non_Empty_Map (X);
      P := Find (X, 1003);
      Q := Find (X, 1);
      Delete (X, P);

      Assert (Length (X) = 4, "Delete cursor without collisions, length is decremented");
      Assert (not Contains (X, 3), "Delete cursor without collisions, key is removed");
      Assert (Key (X, Q) = 1, "Delete cursor without collisions, other keys are preserved");
      Assert (Element (X, 1) = 1, "Delete cursor without collisions, other mappings are preserved");

      Create_Non_Empty_Map_With_Collisions (Y);
      P := Find (Y, 1300);
      Q := Find (Y, 100);
      Delete (Y, P);

      Assert (Length (Y) = 4, "Delete cursor with collisions, length is decremented");
      Assert (not Contains (Y, 300), "Delete cursor with collisions, key is removed");
      Assert (Key (Y, Q) = 100, "Delete cursor with collisions, other keys are preserved");
      Assert (Element (Y, 100) = 100, "Delete cursor with collisions, other mappings are preserved");
   end Test_Delete_2;

   procedure Test_First with Pre => True is
      X : Map (1000, Default_Modulus (1000));
   begin
      Assert (First (X) = No_Element, "First on empty map");
      Create_Non_Empty_Map (X);
      Assert (Has_Element (X, First (X)) and Element (X, First (X)) in 1 .. 5, "First on non empty map");
   end Test_First;

   procedure Test_Next with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
      P : Cursor := No_Element;
   begin
      Create_Non_Empty_Map (X);

      Assert (Next (X, P) = No_Element, "Next function on No_Element");
      Next (X, P);
      Assert (P = No_Element, "Next procedure on No_Element");

      P := First (X);
      Assert (Has_Element (X, Next (X, P)), "Next function without collisions");
      Next (X, P);
      Assert (Has_Element (X, P), "Next procedure without collisions");

      Create_Non_Empty_Map_With_Collisions (Y);

      P := First (Y);
      Assert (Has_Element (Y, Next (Y, P)), "Next function with collisions");
      Next (Y, P);
      Assert (Has_Element (Y, P), "Next procedure with collisions");
   end Test_Next;

   procedure Test_Find with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
   begin
      Assert (Find (X, 1) = No_Element, "Find on empty map");

      Create_Non_Empty_Map (X);

      Assert (Find (X, 1) /= No_Element and Find (X, 5) /= No_Element, "Find without collisions, key is present");
      Assert (Find (X, 7) = No_Element, "Find without collisions, key is not present");
      Assert (Find (X, 1004) /= No_Element, "Find without collisions, use provided equivalence function");

      Create_Non_Empty_Map_With_Collisions (Y);

      Assert (Find (Y, 100) /= No_Element and Find (Y, 500) /= No_Element, "Find with collisions, key is present");
      Assert (Find (Y, 7) = No_Element, "Find with collisions, key is not present");
      Assert (Find (Y, 1400) /= No_Element, "Find with collisions, use provided equivalence function");
   end Test_Find;

   procedure Test_Contains with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
   begin
      Assert (not Contains (X, 1), "Contains on empty map");

      Create_Non_Empty_Map (X);

      Assert (Contains (X, 1) and Contains (X, 5), "Contains without collisions, key is present");
      Assert (not Contains (X, 7), "Contains without collisions, key is not present");
      Assert (Contains (X, 1004), "Contains without collisions, use provided equivalence function");

      Create_Non_Empty_Map_With_Collisions (Y);

      Assert (Contains (Y, 100) and Contains (Y, 500), "Contains with collisions, key is present");
      Assert (not Contains (Y, 7), "Contains with collisions, key is not present");
      Assert (Contains (Y, 1400), "Contains with collisions, use provided equivalence function");
   end Test_Contains;

   procedure Test_Has_Element with Pre => True is
      X : Map (1000, Default_Modulus (1000));
      P : Cursor;
   begin
      Create_Non_Empty_Map (X);
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

   procedure Test_Iteration with Pre => True is
      X, Y : Map (1000, Default_Modulus (1000));
   begin
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, empty map");
      Assert ((for all K of X => K /= 0), "for of iteration, empty map");

      Create_Non_Empty_Map (X);
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, non-empty map without collisions");
      Assert ((for some K of X => Element (X, K) = 3), "for of iteration, non-empty map without collisions");

      Create_Non_Empty_Map_With_Collisions (Y);
      Assert ((for all P in Y => Element (Y,  P) /= 0), "for in iteration, non-empty map with collisions");
      Assert ((for some K of Y => Element (Y, K) = 300), "for of iteration, non-empty map with collisions");
   end Test_Iteration;

   procedure Test_Aggregate with Pre => True is
      X : Map := [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5];
   begin
      Assert (Length (X) = 5, "aggregate, length");
      Assert (Contains (X, 1) and Contains (X, 5), "aggregate, keys");
      Assert (Element (X, 1) = 1 and Element (X, 5) = 5, "aggregate, elements");
   end Test_Aggregate;

begin
   Test_Empty_Map;
   Test_Length;
   Test_Eq;
   Test_Capacity;
   Test_Reserve_Capacity;
   Test_Is_Empty;
   Test_Clear;
   Test_Assign;
   Test_Copy;
   Test_Key;
   Test_Element_1;
   Test_Element_1;
   Test_Replace_Element;
   Test_Constant_Reference_1;
   Test_Reference_1;
   Test_Constant_Reference_2;
   Test_Reference_2;
   Test_Move;
   Test_Insert_1;
   Test_Insert_2;
   Test_Include;
   Test_Replace;
   Test_Exclude;
   Test_Delete_1;
   Test_Delete_2;
   Test_First;
   Test_Next;
   Test_Find;
   Test_Contains;
   Test_Has_Element;
   Test_Default_Modulus;
   Test_Iteration;
   Test_Aggregate;
end Test;
