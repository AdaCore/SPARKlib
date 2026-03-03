with Ada.Assertions;
with Ada.Text_IO;
with Ada.Containers;
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Formal.Trees;

procedure Test with SPARK_Mode is

   use type Ada.Containers.Count_Type;

   type Small_Int is new Integer range -100 .. 100;
   subtype Small_Pos is Small_Int range 1 .. Small_Int'Last;

   package Int_Trees is new SPARK.Containers.Formal.Trees
     (Small_Pos, Integer);
   use Int_Trees;

   procedure Assert (B : Boolean; S : String) with
     Pre => (Static => B);

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
         raise Ada.Assertions.Assertion_Error;
      end if;
   end Assert;

   procedure Test_Empty_Tree with Pre => True is
      T : Tree := Empty_Tree (100);
   begin
      Assert (Is_Empty (T), "Empty_Tree is not empty");
      Assert (T.Capacity = 100, "Wrong capacity for empty tree");
   end Test_Empty_Tree;

   procedure Test_Element with Pre => True is
      T : Tree (100);
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      Assert (Element (T, Root(T)) = 10, "Get incorrect element (10)");
      Assert (Element (T, Child (T, Root(T), 1)) = 1, "Get incorrect element (1)");
      Assert (Element (T, Child (T, Root(T), 2)) = 2, "Get incorrect element (2)");
      Assert (Element (T, Child (T, Root(T), 3)) = 3, "Get incorrect element (3)");
   end Test_Element;

   procedure Test_Child with Pre => True is
      T  : Tree (100);
      C2 : Cursor;
      C7 : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      --  With a non-empty child

      C2 := Child (T, Root (T), 2);

      --  With an empty child

      C7 := Child (T, Root (T), 7);

      Assert (C2 /= No_Element and then Element (T, C2) = 2, "Child, non-empty child");
      Assert (C7 = No_Element, "Child, empty child");
   end Test_Child;

   procedure Test_Is_Root with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);

      C := Root (T);
      Assert (Is_Root (T, C), "Is_Root, root");

      C := Child (T, Root (T), 1);
      Assert (not Is_Root (T, C), "Is_Root, child");
   end Test_Is_Root;

   procedure Test_Is_Leaf with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);

      C := Root (T);
      Assert (not Is_Leaf (T, C), "Is_Leaf, non-leaf");

      C := Child (T, Root (T), 1);
      Assert (Is_Leaf (T, C), "Is_Leaf, leaf");
   end Test_Is_Leaf;

   procedure Test_Is_Ancestor_Of with Pre => True is
      T  : Tree (100);
      CR : Cursor;
      C1 : Cursor;
      C2 : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Child (T, Root (T), 1), 1);

      CR := Root (T);
      C1 := Child (T, CR, 1);
      C2 := Child (T, C1, 1);

      Assert (Is_Ancestor_Of (T, CR, C1), "root not ancestor of node 1");
      Assert (Is_Ancestor_Of (T, CR, C2), "root not ancestor of node 2");
      Assert (Is_Ancestor_Of (T, C1, C2), "node 1 not ancestor of node 2");
      Assert (not Is_Ancestor_Of (T, C1, CR), "node 1 is ancestor of root");
      Assert (not Is_Ancestor_Of (T, C1, C1), "node 1 is ancestor of itself");
   end Test_Is_Ancestor_Of;

   procedure Test_In_Subtree with Pre => True is
      T  : Tree (100);
      CR : Cursor;
      C1 : Cursor;
      C2 : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Child (T, Root (T), 1), 1);

      CR := Root (T);
      C1 := Child (T, CR, 1);
      C2 := Child (T, C1, 1);

      Assert (In_Subtree (T, C1, CR), "node 1 not in subtree at root");
      Assert (In_Subtree (T, C2, CR), "node 2 not in subtree at root");
      Assert (In_Subtree (T, C2, C1), "node 2 not in subtree at node 1");
      Assert (In_Subtree (T, C1, C1), "node 1 is in subtree at node 1");
      Assert (not In_Subtree (T, CR, C1), "root is in subtree at node 1");
   end Test_In_Subtree;

   procedure Test_Depth with Pre => True is
      T  : Tree (100);
      CR : Cursor;
      C1 : Cursor;
      C2 : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Child (T, Root (T), 1), 1);

      CR := Root (T);
      C1 := Child (T, CR, 1);
      C2 := Child (T, C1, 1);

      Assert (Depth (T, CR) = 0, "root not at depth 0");
      Assert (Depth (T, C1) = 1, "node 1 not at depth 1");
      Assert (Depth (T, C2) = 2, "node 2 not at depth 2");
   end Test_Depth;

   procedure Test_Eq_Same_Obj with Pre => True is
      T1 : Tree (100);

      B11 : Boolean;

   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);
      Insert_Child (T1, 4, Root (T1), 4);

      --  Same object

      B11 := T1 = T1;

      Assert (B11, "=, same objects");
   end Test_Eq_Same_Obj;

   procedure Test_Eq_Empty_Vs_Non_Empty with Pre => True is
      T1 : Tree (100);

      B1E : Boolean;
      BE1 : Boolean;

   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);
      Insert_Child (T1, 4, Root (T1), 4);

      --  An empty and a non-empty object

      B1E := T1 = Empty_Tree (100);
      BE1 := Empty_Tree (100) = T1;

      Assert (not B1E and not BE1, "=, empty and non-empty object");
   end Test_Eq_Empty_Vs_Non_Empty;

   procedure Test_Eq_Different_Roots with Pre => True is
      T1, T2 : Tree (100);

      B12 : Boolean;
      B21 : Boolean;

   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);
      Insert_Child (T1, 4, Root (T1), 4);

      --  Objects with different roots

      Insert_Root (T2, 11);
      Insert_Child (T2, 1, Root (T2), 1);
      Insert_Child (T2, 2, Root (T2), 2);
      Insert_Child (T2, 3, Root (T2), 3);
      Insert_Child (T2, 4, Root (T2), 4);

      B12 := T1 = T2;
      B21 := T2 = T1;

      Assert (not B12 and not B21, "=, different roots");
   end Test_Eq_Different_Roots;

   procedure Test_Eq_Different_Depths with Pre => True is
      T1, T3 : Tree (100);

      B13 : Boolean;
      B31 : Boolean;

   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);
      Insert_Child (T1, 4, Root (T1), 4);

      --  Objects with different depths

      Insert_Root (T3, 10);
      Insert_Child (T3, 1, Root (T3), 1);
      Insert_Child (T3, 2, Root (T3), 2);
      Insert_Child (T3, 3, Root (T3), 3);
      Insert_Child (T3, 1, Child (T3, Root (T3), 3), 1);

      B13 := T1 = T3;
      B31 := T3 = T1;

      Assert (not B13 and not B31, "=, different depths");
   end Test_Eq_Different_Depths;

   procedure Test_Eq_Different_Counts with Pre => True is
      T1, T4 : Tree (100);

      B14 : Boolean;
      B41 : Boolean;

   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);
      Insert_Child (T1, 4, Root (T1), 4);

      --  Objects with different counts

      Insert_Root (T4, 11);
      Insert_Child (T4, 1, Root (T4), 1);
      Insert_Child (T4, 2, Root (T4), 2);
      Insert_Child (T4, 3, Root (T4), 3);

      B14 := T1 = T4;
      B41 := T4 = T1;

      Assert (not B14 and not B41, "=, different counts");
   end Test_Eq_Different_Counts;

   procedure Test_Eq_Same_Insertion_Order with Pre => True is
      T1, T5 : Tree (100);
   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);

      --  Objects with same tree structure and elements, and same
      --  insertion order

      Insert_Root (T5, 10);
      Insert_Child (T5, 1, Root (T5), 1);
      Insert_Child (T5, 2, Root (T5), 2);
      Insert_Child (T5, 3, Root (T5), 3);

      Assert (T1 = T5, "T1 = T5, same insertion order");
      Assert (T5 = T1, "T5 = T1, same insertion order");
   end Test_Eq_Same_Insertion_Order;

   procedure Test_Eq_Different_Insertion_Order with Pre => True is
      T1, T5 : Tree (100);
   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);

      --  Objects with same tree structure and elements, but different
      --  insertion order

      Insert_Root (T5, 10);
      Insert_Child (T5, 3, Root (T5), 3);
      Insert_Child (T5, 2, Root (T5), 2);
      Insert_Child (T5, 1, Root (T5), 1);

      Assert (T1 = T5, "T1 = T5, different insertion order");
      Assert (T5 = T1, "T5 = T1, different insertion order");
   end Test_Eq_Different_Insertion_Order;

   procedure Test_Eq_Different_Capacity with Pre => True is
      T1 : Tree (100);
      T5 : Tree (101);
   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);

      Insert_Root (T5, 10);
      Insert_Child (T5, 1, Root (T5), 1);
      Insert_Child (T5, 2, Root (T5), 2);

      Assert (T1 = T5, "T1 = T5, same insertion order");
      Assert (T5 = T1, "T5 = T1, same insertion order");
   end Test_Eq_Different_Capacity;

   --  Test default initialization

   procedure Test_Default_Init with Pre => True is
      T : Tree (100);
   begin
      Assert (Is_Empty (T), "Default init, is empty");
   end Test_Default_Init;

   procedure Test_Insert_Parent_Root with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);
      Insert_Parent (T, 5, Root (T), 1);

      C := Root (T);
      Assert (Element (T, C) = 5, "Insert parent (root), wrong element (5)");

      C := Child (T, Root (T), 1);
      Assert (Element (T, C) = 10, "Insert parent (root), wrong element (10)");

      C := Child (T, Child (T, Root (T), 1), 1);
      Assert (Element (T, C) = 1, "Insert parent (root), wrong element (1)");

      C := Child (T, Child (T, Root (T), 1), 2);
      Assert (Element (T, C) = 2, "Insert parent (root), wrong element (2)");

      C := Child (T, Child (T, Root (T), 1), 3);
      Assert (Element (T, C) = 3, "Insert parent (root), wrong element (3)");
   end Test_Insert_Parent_Root;

   procedure Test_Insert_Parent_Non_Root with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);
      Insert_Parent (T, 5, Child (T, Root (T), 1), 1);

      C := Root (T);
      Assert (Element (T, C) = 10, "Insert parent (root), wrong element (10)");

      C := Child (T, Root (T), 1);
      Assert (Element (T, C) = 5, "Insert parent (root), wrong element (5)");

      C := Child (T, Child (T, Root (T), 1), 1);
      Assert (Element (T, C) = 1, "Insert parent (root), wrong element (1)");

      C := Child (T, Root (T), 2);
      Assert (Element (T, C) = 2, "Insert parent (root), wrong element (2)");

      C := Child (T, Root (T), 3);
      Assert (Element (T, C) = 3, "Insert parent (root), wrong element (3)");
   end Test_Insert_Parent_Non_Root;

   procedure Test_Delete_Leaf with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      Delete (T, Child (T, Root (T), 2));

      C := Root (T);
      Assert (Has_Element (T, C), "No element for root node");
      Assert (Element (T, C) = 10, "Wrong element for root node");

      C := Child (T, Root (T), 1);
      Assert (Has_Element (T, C), "No element for node 1");
      Assert (Element (T, C) = 1, "Wrong element for node 1");

      C := Child (T, Root (T), 2);
      Assert (not Has_Element (T, C), "node 2 was not deleted");

      C := Child (T, Root (T), 3);
      Assert (Has_Element (T, C), "No element for node 3");
      Assert (Element (T, C) = 3, "Wrong element for node 3");
   end Test_Delete_Leaf;

   procedure Test_Delete_Root with Pre => True is
      T : Tree (100);
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      Delete (T, Root (T));

      Assert (Is_Empty (T), "Tree not empty after deleted root");
      Assert (Root (T) = No_Element, "Root not No_Element after deletion");
   end Test_Delete_Root;

   procedure Test_Replace_Element with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Replace_Element (T, 11, Root (T));

      C := Root (T);
      Assert (Element (T, C) = 11, "Wrong element for root node");

      C := Child (T, Root (T), 1);
      Assert (Element (T, C) = 1, "Wrong element for node 1");
   end Test_Replace_Element;

   procedure Test_First_Child with Pre => True is
      T : Tree (100);
   begin
      Insert_Root (T, 10);

      Assert
        (First_Child (T, Root (T)) = No_Element,
         "First child of leaf is not No_Element");

      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);
      Insert_Child (T, 4, Root (T), 4);

      Assert
        (First_Child (T, Root (T)) = Child (T, Root (T), 2),
         "First child not node 2");
   end Test_First_Child;

   procedure Test_Last_Child with Pre => True is
      T : Tree (100);
   begin
      Insert_Root (T, 10);

      Assert
        (Last_Child (T, Root (T)) = No_Element,
         "Last child of leaf is not No_Element");

      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      Assert
        (Last_Child (T, Root (T)) = Child (T, Root (T), 3),
         "Last child not node 3");
   end Test_Last_Child;

   procedure Test_Next_Sibling with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);

      Assert
        (Next_Sibling (T, Root (T)) = No_Element,
         "Next sibling of root is not No_Element");

      C := Next_Sibling (T, Child (T, Root (T), 1));
      Assert
        (Has_Element (T, C) and then C = Child (T, Root (T), 2),
         "Next sibling of node 1 is not node 2");

      C := Next_Sibling (T, C);
      Assert
        (C = No_Element, "Next sibling of node 2 is not No_Element");
   end Test_Next_Sibling;

   procedure Test_Previous_Sibling with Pre => True is
      T : Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);

      Assert
        (Previous_Sibling (T, Root (T)) = No_Element,
         "Previous sibling of root is not No_Element");

      C := Previous_Sibling (T, Child (T, Root (T), 2));
      Assert
        (Has_Element (T, C) and then C = Child (T, Root (T), 1),
         "Previous sibling of node 2 is not node 1");

      C := Previous_Sibling (T, C);
      Assert
        (C = No_Element, "Previous sibling of node 1 is not No_Element");
   end Test_Previous_Sibling;

   procedure Test_Reference with Pre => True is
      T : aliased Tree (100);
      C : Cursor;
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      C := Child (T, Root (T), 2);

      declare
         Ref : constant not null access Integer := Reference (T, C);
      begin
         Ref.all := 20;
      end;

      Assert (Element (T, Root (T)) = 10, "Root element changed");
      Assert (Element (T, Child (T, Root (T), 1)) = 1, "Node 1 changed");
      Assert (Element (T, Child (T, Root (T), 2)) = 20, "Node 2 not changed");
      Assert (Element (T, Child (T, Root (T), 3)) = 3, "Node 3 changed");
   end Test_Reference;

   procedure Test_Constant_Reference with Pre => True is
      T : aliased Tree (100);
   begin
      Insert_Root (T, 10);
      Insert_Child (T, 1, Root (T), 1);
      Insert_Child (T, 2, Root (T), 2);
      Insert_Child (T, 3, Root (T), 3);

      declare
         Ref_R : constant not null access constant Integer :=
           Constant_Reference (T, Root (T));

         Ref_1 : constant not null access constant Integer :=
           Constant_Reference (T, Child (T, Root (T), 1));

         Ref_2 : constant not null access constant Integer :=
           Constant_Reference (T, Child (T, Root (T), 2));

         Ref_3 : constant not null access constant Integer :=
           Constant_Reference (T, Child (T, Root (T), 3));
      begin
         Assert (Element (T, Root (T)) = 10, "Wrong value for root");

         Assert
           (Element (T, Child (T, Root (T), 1)) = 1, "Wrong value for node 1");

         Assert
           (Element (T, Child (T, Root (T), 2)) = 2, "Wrong value for node 2");

         Assert
           (Element (T, Child (T, Root (T), 3)) = 3, "Wrong value for node 3");
      end;
   end Test_Constant_Reference;

   procedure Test_Move with Pre => True is
      T1 : Tree (100);
      T2 : Tree (100);
   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);

      Move (Target => T2, Source => T1);

      Assert (Is_Empty (T1), "T1 not empty after move");

      Assert (Element (T2, Root (T2)) = 10, "Wrong root value after move");
      Assert (Element (T2, Child (T2, Root (T2), 1)) = 1, "Wrong value for node 1 after move");
      Assert (Element (T2, Child (T2, Root (T2), 2)) = 2, "Wrong value for node 2 after move");
      Assert (Element (T2, Child (T2, Root (T2), 3)) = 3, "Wrong value for node 3 after move");
   end Test_Move;

   procedure Test_Assign with Pre => True is
      T1 : Tree (100);
      T2 : Tree (100);
   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);

      Assign (Target => T2, Source => T1);

      Assert (Element (T2, Root (T2)) = 10, "Wrong root value after assign");
      Assert (Element (T2, Child (T2, Root (T2), 1)) = 1, "Wrong value for node 1 after assign");
      Assert (Element (T2, Child (T2, Root (T2), 2)) = 2, "Wrong value for node 2 after assign");
      Assert (Element (T2, Child (T2, Root (T2), 3)) = 3, "Wrong value for node 3 after assign");
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      T1 : Tree (100);
      T2 : Tree (100);
   begin
      Insert_Root (T1, 10);
      Insert_Child (T1, 1, Root (T1), 1);
      Insert_Child (T1, 2, Root (T1), 2);
      Insert_Child (T1, 3, Root (T1), 3);

      T2 := Copy (T1);

      Assert (Element (T2, Root (T2)) = 10, "Wrong root value after copy");
      Assert (Element (T2, Child (T2, Root (T2), 1)) = 1, "Wrong value for node 1 after copy");
      Assert (Element (T2, Child (T2, Root (T2), 2)) = 2, "Wrong value for node 2 after copy");
      Assert (Element (T2, Child (T2, Root (T2), 3)) = 3, "Wrong value for node 3 after copy");
   end Test_Copy;

begin
   Test_Empty_Tree;
   Test_Element;
   Test_Child;
   Test_Is_Root;
   Test_Is_Leaf;
   Test_Is_Ancestor_Of;
   Test_In_Subtree;
   Test_Depth;
   Test_Eq_Same_Obj;
   Test_Eq_Empty_Vs_Non_Empty;
   Test_Eq_Different_Roots;
   Test_Eq_Different_Depths;
   Test_Eq_Different_Counts;
   Test_Eq_Same_Insertion_Order;
   Test_Eq_Different_Insertion_Order;
   Test_Eq_Different_Capacity;
   Test_Default_Init;
   Test_Insert_Parent_Root;
   Test_Insert_Parent_Non_Root;
   Test_Delete_Leaf;
   Test_Delete_Root;
   Test_Replace_Element;
   Test_First_Child;
   Test_Last_Child;
   Test_Next_Sibling;
   Test_Previous_Sibling;
   Test_Reference;
   Test_Constant_Reference;
   Test_Move;
   Test_Assign;
   Test_Copy;
end Test;
