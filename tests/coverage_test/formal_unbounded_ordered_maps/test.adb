pragma Ada_2022;
with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Ordered_Maps;
with Big_Test;

procedure Test with SPARK_Mode is

   function Lt (X, Y : Integer) return Boolean is
      (X mod 1000 < Y mod 1000);

   function Eq (X, Y : Integer) return Boolean is
      (X mod 1000 = Y mod 1000);

   package Inst is new
     SPARK.Containers.Formal.Unbounded_Ordered_Maps (Integer, Integer, Lt, Eq);
   use Inst;

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  Create map with 5 elements

   procedure Create_Non_Empty_Map (X : in out Map) with
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

   procedure Test_Empty_Map with Pre => True is
      X : Map := Empty_Map;
   begin
      Assert (Length (X) = 0, "Empty_Map is empty");
   end Test_Empty_Map;

   procedure Test_Length with Pre => True is
      X : Map;
   begin
      Assert (Length (X) = 0, "Length on empty map");
      Create_Non_Empty_Map (X);
      Assert (Length (X) = 5, "Length on non-empty map");
   end Test_Length;

   procedure Test_Eq with Pre => True is
      X, Y, Z : Map;
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

   procedure Test_Is_Empty with Pre => True is
      X : Map;
   begin
      Assert (Is_Empty (X), "Is_Empty on empty map");
      Create_Non_Empty_Map (X);
      Assert (not Is_Empty (X), "Is_Empty on non-empty map");
   end Test_Is_Empty;

   procedure Test_Clear with Pre => True is
      X : Map;
   begin
      Clear (X);
      Assert (Is_Empty (X), "Clear on empty map");
      Create_Non_Empty_Map (X);
      Clear (X);
      Assert (Is_Empty (X), "Clear on non-empty map");
   end Test_Clear;

   procedure Test_Assign with Pre => True is
      X, Y : Map;
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
      X : Map;
   begin
      declare
         Y : constant Map := Copy (X);
      begin
         Assert (Is_Empty (Y), "Copy of empty map");
      end;
      Create_Non_Empty_Map (X);
      declare
         Y : constant Map := Copy (X);
      begin
         Assert (Y = X, "Copy of non-empty map");
      end;
   end Test_Copy;

   procedure Test_Key with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (Key (X, First (X)) in 1 .. 5, "Key on non-empty map");
   end Test_Key;

   --  Element on a cursor
   procedure Test_Element_1 with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (Element (X, First (X)) = Natural'(Key (X, First (X))), "Element on a cursor");
   end Test_Element_1;

   --  Element on a key
   procedure Test_Element_2 with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (Element (X, 1) = 1, "Element on a key");
   end Test_Element_2;

   procedure Test_Replace_Element with Pre => True is
      X          : Map;
      P1, P2, P3 : Cursor;
      E1, E3     : Integer;
      K1, K2, K3 : Natural;
   begin
      Create_Non_Empty_Map (X);
      P1 := First (X);
      P2 := Next (X, P1);
      P3 := Next (X, P2);
      K1 := Key (X, P1);
      K2 := Key (X, P2);
      K3 := Key (X, P3);
      E1 := Element (X, P1);
      E3 := Element (X, P3);

      Replace_Element (X, P2, 0);

      Assert (Element (X, P2) = 0, "Replace_Element, the element is replaced");
      Assert (Length (X) = 5, "Replace_Element, length is preserved");
      Assert (Key (X, P1) = K1 and Key (X, P2) = K2 and Key (X, P3) = K3, "Replace_Element, keys are preserved");
      Assert (Element (X, P1) = E1 and Element (X, P3) = E3, "Replace_Element, other elements are preserved");
   end Test_Replace_Element;

   --  Constant_Reference on a cursor
   procedure Test_Constant_Reference_1 with Pre => True is
      X  : aliased Map;
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
      X  : aliased Map;
      P1 : Cursor;
   begin
      Create_Non_Empty_Map (X);

      Assert (Constant_Reference (X, 2).all = 2, "Constant_Reference on a key");
   end Test_Constant_Reference_2;

   --  Reference on a cursor
   procedure Test_Reference_1 with Pre => True is
      X      : aliased Map;
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
      X : aliased Map;
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
      X, Y : Map;
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
      X      : Map;
      P1, P2 : Cursor;
      B1     : Boolean;
   begin
      Insert (X, 1, 1, P1, B1);
      Assert (B1, "Conditional Insert in empty map, element can be inserted");
      Assert (Length (X) = 1, "Conditional Insert in empty map, length is incremented");
      Assert (Key (X, P1) = 1, "Conditional Insert in empty map, Key is designated by Position");
      Assert (Element (X, P1) = 1, "Conditional Insert in empty map, New_Item is designated by Position");

      Insert (X, 2, 2, P2, B1);
      Assert (B1, "Conditional Insert, new element can be inserted");
      Assert (Length (X) = 2, "Conditional Insert, length is incremented");
      Assert (Key (X, P2) = 2, "Conditional Insert, Key is designated by Position");
      Assert (Element (X, 2) = 2, "Conditional Insert, New_Item is attached to Key");
      Assert (Element (X, 1) = 1, "Conditional Insert, existing Key/Element mappings are preserved");
      Assert (Key (X, P1) = 1, "Conditional Insert, existing Cursor/Key mappings are preserved");

      Insert (X, 1002, 1002, P2, B1);
      Assert (not B1, "Conditional Insert of existing value, element is not inserted");
      Assert (Length (X) = 2, "Conditional Insert of existing value, length is preserved");
      Assert (Key (X, P2) = 2, "Conditional Insert of existing value, Position designates the right key in Container");
   end Test_Insert_1;

   --  Insert without Position nor Inserted parameters
   procedure Test_Insert_2 with Pre => True is
      X  : Map;
      P2 : Cursor;
   begin
      Insert (X, 1, 1);
      Assert (Length (X) = 1, "Insert in empty map, length is incremented");
      Assert (Contains (X, 1), "Insert in empty map, Key is in X");
      Assert (Element (X, 1) = 1, "Insert in empty map, Key maps to New_Item");

      Insert (X, 2, 2);
      Assert (Length (X) = 2, "Insert, length is incremented");
      Assert (Contains (X, 2), "Insert, Key is in Container");
      Assert (Element (X, 2) = 2, "Insert, Key maps to New_Item");
      Assert (Element (X, 1) = 1, "Insert, existing elements are preserved");

      P2 := Find (X, 2);
      Assert (Key (X, P2) = 2, "Insert, precise key of inserted values");
   end Test_Insert_2;

   procedure Test_Include with Pre => True is
      X  : Map;
      P2 : Cursor;
   begin
      Include (X, 1, 1);
      Assert (Length (X) = 1, "Include in empty map, length is incremented");
      Assert (Contains (X, 1), "Include in empty map, Key is in Container");
      Assert (Element (X, 1) = 1, "Include in empty map, Key maps to New_Item");

      Include (X, 2, 2);
      Assert (Length (X) = 2, "Include, length is incremented");
      Assert (Contains (X, 2), "Include, Key is in Container");
      Assert (Element (X, 2) = 2, "Include, Key maps to New_Item");
      Assert (Contains (X, 1), "Include, existing elements are preserved");

      P2 := Find (X, 2);
      Assert (Key (X, P2) = 2, "Include, precise key of included values");

      Include (X, 1002, 1002);
      Assert (Length (X) = 2, "Include of existing value, length is preserved");
      Assert (Element (X, 1002) = 1002, "Include, Key maps to New_Item");
      Assert (Key (X, P2) = 1002, "Include, Key is replaced");
   end Test_Include;

   procedure Test_Replace with Pre => True is
      X, Y : Map;
      P, Q : Cursor;
   begin
      Create_Non_Empty_Map (X);
      P := Find (X, 3);
      Q := Find (X, 1);
      Replace (X, 1003, 1003);

      Assert (Length (X) = 5, "Replace, length is preserved");
      Assert (Key (X, P) = 1003, "Replace, key is updated");
      Assert (Element (X, 1003) = 1003, "Replace, element is updated");
      Assert (Key (X, Q) = 1 and Element (X, 1) = 1, "Replace, other keys/elements are preserved");
   end Test_Replace;

   procedure Test_Exclude with Pre => True is
      X, Y : Map;
      Q    : Cursor;
   begin
      Exclude (X, 1);
      Assert (Length (X) = 0, "Exclude on empty map");

      Create_Non_Empty_Map (X);
      Exclude (X, 6);

      Assert (Length (X) = 5, "Exclude without collisions, key not is map");

      Q := Find (X, 1);
      Exclude (X, 1003);

      Assert (Length (X) = 4, "Exclude, length is decremented");
      Assert (not Contains (X, 3), "Exclude, key is removed");
      Assert (Key (X, Q) = 1, "Exclude, other keys are preserved");
      Assert (Element (X, 1) = 1, "Exclude, other mappings are preserved");
   end Test_Exclude;

   --  Delete a key from the map
   procedure Test_Delete_1 with Pre => True is
      X, Y : Map;
      Q    : Cursor;
   begin
      Create_Non_Empty_Map (X);
      Q := Find (X, 1);
      Delete (X, 1003);

      Assert (Length (X) = 4, "Delete key, length is decremented");
      Assert (not Contains (X, 3), "Delete key, key is removed");
      Assert (Key (X, Q) = 1, "Delete key, other keys are preserved");
      Assert (Element (X, 1) = 1, "Delete key, other mappings are preserved");
   end Test_Delete_1;

   --  Delete a cursor
   procedure Test_Delete_2 with Pre => True is
      X, Y : Map;
      P, Q : Cursor;
   begin
      Create_Non_Empty_Map (X);
      P := Find (X, 1003);
      Q := Find (X, 1);
      pragma Assert (Q /= P);
      Delete (X, P);

      Assert (Length (X) = 4, "Delete cursor, length is decremented");
      Assert (not Contains (X, 3), "Delete cursor, key is removed");
      Assert (Key (X, Q) = 1, "Delete cursor, other keys are preserved");
      Assert (Element (X, 1) = 1, "Delete cursor, other mappings are preserved");
   end Test_Delete_2;

   procedure Test_Delete_First with Pre => True is
      X, Y : Map;
      Q    : Cursor;
   begin
      Delete_First (X);
      Assert (Length (X) = 0, "Delete_First, empty container");

      Create_Non_Empty_Map (X);
      Q := Find (X, 3);
      Delete_First (X);

      Assert (Length (X) = 4, "Delete_First, length is decremented");
      Assert (not Contains (X, 1), "Delete_First, first element is removed");
      Assert (Key (X, Q) = 3, "Delete_First, other keys are preserved");
      Assert (Element (X, 3) = 3, "Delete_First, other mappings are preserved");
   end Test_Delete_First;

   procedure Test_Delete_Last with Pre => True is
      X, Y : Map;
      Q    : Cursor;
   begin
      Delete_Last (X);
      Assert (Length (X) = 0, "Delete_Last, empty container");

      Create_Non_Empty_Map (X);
      Q := Find (X, 3);
      Delete_Last (X);

      Assert (Length (X) = 4, "Delete_Last, length is decremented");
      Assert (not Contains (X, 5), "Delete_Last, first element is removed");
      Assert (Key (X, Q) = 3, "Delete_Last, other keys are preserved");
      Assert (Element (X, 3) = 3, "Delete_Last, other mappings are preserved");
   end Test_Delete_Last;

   procedure Test_First with Pre => True is
      X : Map;
   begin
      Assert (First (X) = No_Element, "First on empty map");
      Create_Non_Empty_Map (X);
      Assert (Has_Element (X, First (X)) and Element (X, First (X)) = 1, "First on non empty map");
   end Test_First;

   procedure Test_First_Key with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (First_Key (X) = 1, "First_Key");
   end Test_First_Key;

   procedure Test_First_Element with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (First_Element (X) = 1, "First_Element");
   end Test_First_Element;

   procedure Test_Next with Pre => True is
      X, Y : Map;
      P : Cursor := No_Element;
   begin
      Create_Non_Empty_Map (X);

      Assert (Next (X, P) = No_Element, "Next function on No_Element");
      Next (X, P);
      Assert (P = No_Element, "Next procedure on No_Element");

      P := Last (X);
      Assert (Next (X, P) = No_Element, "Next function of last");
      Next (X, P);
      Assert (P = No_Element, "Next procedure on last");

      P := First (X);
      Assert (Has_Element (X, Next (X, P)), "Next function");
      Next (X, P);
      Assert (Has_Element (X, P), "Next procedure");
   end Test_Next;

   procedure Test_Last with Pre => True is
      X : Map;
   begin
      Assert (Last (X) = No_Element, "Last on empty map");
      Create_Non_Empty_Map (X);
      Assert (Has_Element (X, Last (X)) and Element (X, Last (X)) = 5, "Last on non empty map");
   end Test_Last;

   procedure Test_Last_Key with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (Last_Key (X) = 5, "Last_Key");
   end Test_Last_Key;

   procedure Test_Last_Element with Pre => True is
      X : Map;
   begin
      Create_Non_Empty_Map (X);
      Assert (Last_Element (X) = 5, "Last_Element");
   end Test_Last_Element;

   procedure Test_Previous with Pre => True is
      X, Y : Map;
      P : Cursor := No_Element;
   begin
      Create_Non_Empty_Map (X);

      Assert (Previous (X, P) = No_Element, "Previous function on No_Element");
      Previous (X, P);
      Assert (P = No_Element, "Previous procedure on No_Element");

      P := First (X);
      Assert (Previous (X, P) = No_Element, "Previous function of first");
      Previous (X, P);
      Assert (P = No_Element, "Previous procedure on first");

      P := Last (X);
      Assert (Has_Element (X, Previous (X, P)), "Previous function");
      Previous (X, P);
      Assert (Has_Element (X, P), "Previous procedure");
   end Test_Previous;

   procedure Test_Find with Pre => True is
      X : Map;
   begin
      Assert (Find (X, 1) = No_Element, "Find on empty map");

      Create_Non_Empty_Map (X);

      Assert (Find (X, 1) /= No_Element and Find (X, 5) /= No_Element, "Find, key is present");
      Assert (Find (X, 7) = No_Element, "Find, key is not present");
      Assert (Find (X, 1004) /= No_Element, "Find, use implicit equivalence function");
   end Test_Find;

   procedure Test_Contains with Pre => True is
      X : Map;
   begin
      Assert (not Contains (X, 1), "Contains on empty map");

      Create_Non_Empty_Map (X);

      Assert (Contains (X, 1) and Contains (X, 5), "Contains, key is present");
      Assert (not Contains (X, 7), "Contains, key is not present");
      Assert (Contains (X, 1004), "Contains, use implicit equivalence function");
   end Test_Contains;

   procedure Test_Has_Element with Pre => True is
      X : Map;
      P : Cursor;
   begin
      Create_Non_Empty_Map (X);
      Assert (not Has_Element (X, No_Element), "Has_Element on No_Element");
      P := Find (X, 3);
      Assert (Has_Element (X, P), "Has_Element returns True");
      Delete (X, 3);
      Assert (not Has_Element (X, P), "Has_Element returns False");
   end Test_Has_Element;

   procedure Test_Floor with Pre => True is
      X : Map;
   begin
      Assert (Floor (X, 1) = No_Element, "Floor on empty map");

      Create_Non_Empty_Map (X);

      Assert (Floor (X, 0) = No_Element, "Floor on too small element");
      Assert (Floor (X, 10) = Last (X), "Floor on too big element");
      Assert (Has_Element (X, Floor (X, 3)) and then Key (X, Floor (X, 3)) = 3, "Floor on existing element");

      Insert (X, 7, 7);
      Assert (Has_Element (X, Floor (X, 6)) and then Key (X, Floor (X, 6)) = 5, "Floor on missing element");
   end Test_Floor;

   procedure Test_Ceiling with Pre => True is
      X : Map;
   begin
      Assert (Ceiling (X, 1) = No_Element, "Ceiling on empty map");

      Create_Non_Empty_Map (X);

      Assert (Ceiling (X, 0) = First (X), "Ceiling on too small element");
      Assert (Ceiling (X, 10) = No_Element, "Ceiling on too big element");
      Assert (Has_Element (X, Ceiling (X, 3)) and then Key (X, Ceiling (X, 3)) = 3, "Ceiling on existing element");

      Insert (X, 7, 7);
      Assert (Has_Element (X, Ceiling (X, 6)) and then Key (X, Ceiling (X, 6)) = 7, "Ceiling on missing element");
   end Test_Ceiling;

   procedure Test_Iteration with Pre => True is
      X, Y : Map;
   begin
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, empty map");
      Assert ((for all K of X => K /= 0), "for of iteration, empty map");

      Create_Non_Empty_Map (X);
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, non-empty map");
      Assert ((for some K of X => Element (X, K) = 3), "for of iteration, non-empty map");
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
   Test_Is_Empty;
   Test_Assign;
   Test_Clear;
   Test_Copy;
   Test_Move;
   Test_Key;
   Test_Element_1;
   Test_Element_2;
   Test_Constant_Reference_1;
   Test_Constant_Reference_2;
   Test_Reference_1;
   Test_Reference_2;
   Test_Replace_Element;
   Test_Insert_1;
   Test_Insert_2;
   Test_Include;
   Test_Replace;
   Test_Exclude;
   Test_Delete_1;
   Test_Delete_2;
   Test_Delete_First;
   Test_Delete_Last;
   Test_First;
   Test_First_Key;
   Test_First_Element;
   Test_Last;
   Test_Last_Key;
   Test_Last_Element;
   Test_Next;
   Test_Previous;
   Test_Find;
   Test_Contains;
   Test_Has_Element;
   Test_Floor;
   Test_Ceiling;
   Test_Iteration;
   Test_Aggregate;

   --  Additional test to exercise the underlying structure

   Big_Test;
end;
