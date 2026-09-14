with Ada.Text_IO;
with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Functional.Trees;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   type Small_Int is new Integer range -100 .. 100;
   subtype Small_Pos is Small_Int range 1 .. Small_Int'Last;

   package Int_Trees is new SPARK.Containers.Functional.Trees
     (Small_Pos, Integer, Use_Logical_equality => True);
   use Int_Trees;

   procedure Test_Empty_Tree is
      T : Tree := Empty_Tree;
   begin
      Assert (Is_Empty (T), "Empty_Tree is not empty");
   end Test_Empty_Tree;

   procedure Test_Get is
      T : Tree := Create (10, (Create (1), Create (2), Create (3)));
      I : Integer := Get (T);
   begin
      Assert (I = 10, "Get incorrect element");
   end Test_Get;

   procedure Test_Child is
      T  : Tree := Create (10, (Create (1), Create (2), Create (3)));

      --  With a non-empty child

      C2 : Tree := Child (T, 2);

      --  With an empty child

      C7 : Tree := Child (T, 7);
   begin
      Assert (not Is_Empty (C2) and Get (C2) = 2, "Child, non-empty child");
      Assert (Is_Empty (C7), "Child, empty child");
   end Test_Child;

   procedure Test_Eq is
      T1 : Tree := Create (10, (Create (1), Create (2), Create (3), Create (4)));

      --  Same object

      B11 : Boolean := T1 = T1;

      --  An empty and a non-empty object

      B1E : Boolean := T1 = Empty_Tree;
      BE1 : Boolean := Empty_Tree = T1;

      --  Objects with different roots

      T2 : Tree := Set_Root (T1, 11);
      B12 : Boolean := T1 = T2;

      --  Objects with different depths

      T3 : Tree := Create (10, (Create (1), Create (2), Create (3, (1 => Create (1)))));
      B13 : Boolean := T1 = T3;

      --  Objects with different counts

      T4 : Tree := Create (10, (Create (1), Create (2), Create (3)));
      B14 : Boolean := T1 = T4;

      --  Objects with same children pointers

      T5 : Tree := Set_Root (T2, 10);
      B15 : Boolean := T1 = T5;

      --  Objects with different children

      T6 : Tree := Create (10, (Create (1, (Create (2), Create (3))), Create (2), Create (1, (1 => Create (3)))));
      T7 : Tree := Set_Child (Set_Child (T6, 3, Create (1, (Create (3), Create (2)))), 2, Empty_Tree);
      B76 : Boolean := T7 = T6;

      --  Objects with same children

      T8 : Tree := Create (10, (Create (1, (Create (2), Create (3))), Create (2), Create (1, (1 => Create (3)))));
      B86 : Boolean := T8 = T6;
   begin
      Assert (B11, "=, same objects");
      Assert (not B1E and not BE1, "=, empty and non-empty object");
      Assert (not B12, "=, different roots");
      Assert (not B13, "=, different depths");
      Assert (not B14, "=, different counts");
      Assert (B15, "=, same children pointer");
      Assert (not B76, "=, different children");
      Assert (B86, "=, same children");
   end Test_Eq;

   procedure Test_Height is
      T : Tree := Create (10, (Create (1), Create (2), Create (3, (1 => Create (1)))));

      --  With a non-empty tree

      D : Big_Natural := Height (T);

      --  With an empty tree

      DE : Big_Natural := Height (Empty_Tree);
   begin
      Assert (D = 3, "Height, non-empty tree");
      Assert (DE = 0, "Height, empty tree");
   end Test_Height;

   procedure Test_Count is
      T : Tree := Create (10, (Create (1), Create (2), Create (3, (1 => Create (1)))));

      --  With a non-empty tree

      C : Big_Natural := Count (T);

      --  With an empty tree

      CE : Big_Natural := Count (Empty_Tree);
   begin
      Assert (C = 5, "Count, non-empty tree");
      Assert (CE = 0, "Count, empty tree");
   end Test_Count;

   procedure Test_Count_Children with Ghost => SPARKlib_Full is
      T : Tree := Create (10, (Create (1), Create (2), Create (3, (1 => Create (1)))));

      --  Test that Count_Children works as expected

      C1 : Big_Natural := Count_Children (T, 1);
      C2 : Big_Natural := Count_Children (T, 2);
      C3 : Big_Natural := Count_Children (T, 3);
      C4 : Big_Natural := Count_Children (T, 4);

      --  Test it on the last element

      C5 : Big_Natural := Count_Children (T, Small_Pos'Last);

      --  Same test, but with elements inserted out of order

      T2 : Tree := Set_Child (Set_Child (Set_Child (Create (10), 3, Create (3, (1 => Create (1)))), 1, Create (1)), 2, Create (2));

      C6 : Big_Natural := Count_Children (T, 1);
      C7 : Big_Natural := Count_Children (T, 2);
      C8 : Big_Natural := Count_Children (T, 3);
      C9 : Big_Natural := Count_Children (T, 4);

   begin
      Assert (C1 = 4 and C2 = 3 and C3 = 2 and C4 = 0, "Count_Children");
      Assert (C5 = 0, "Count_Children, last element");
      Assert (C6 = 4 and C7 = 3 and C8 = 2 and C9 = 0, "Count_Children, out of order");

      --  Call Lemma_Count_Children_Tail to check its postcondition

      Lemma_Count_Children_Tail (T, 4);
   end Test_Count_Children;

   --  Create with empty children

   procedure Test_Create_1 is
      T : Tree := Create (10);
   begin
      Assert (not Is_Empty (T), "Create no children, not is empty");
      Assert (Get (T) = 10, "Create no children, get");
      Assert ((for all I in Small_Pos => Is_Empty (Child (T, I))), "Create no children, children");
      Assert (Count (T) = 1, "Create no children, count");
      Assert (Height (T) = 1, "Create no children, depth");
   end Test_Create_1;

   --  Create with children array

   procedure Test_Create_2 is

      --  Empty children array

      T1 : Tree := Create (10, []);

      --  Array of empty children

      T2 : Tree := Create (10, [1 .. 20 => Empty_Tree]);

      --  Array of non-empty children

      T3 : Tree := Create (10, (Create (1), Create (2), Create (3, (6 => Create (1), 7 .. 10 => Create (5))), Create (4)));
   begin
      Assert (not Is_Empty (T1), "Create with empty array, not is empty");
      Assert (Get (T1) = 10, "Create with empty array, get");
      Assert ((for all I in Small_Pos => Is_Empty (Child (T1, I))), "Create with empty array, children");
      Assert (Count (T1) = 1, "Create with empty array, count");
      Assert (Height (T1) = 1, "Create with empty array, depth");

      Assert (not Is_Empty (T2), "Create with empty children, not is empty");
      Assert (Get (T2) = 10, "Create with empty children, get");
      Assert ((for all I in Small_Pos => Is_Empty (Child (T2, I))), "Create with empty children, children");
      Assert (Count (T2) = 1, "Create with empty children, count");
      Assert (Height (T2) = 1, "Create with empty children, depth");

      Assert (not Is_Empty (T3), "Create, not is empty");
      Assert (Get (T3) = 10, "Create, get");
      Assert (Count (T3) = 10, "Create, count");
      Assert (Height (T3) = 3, "Create, depth");
      Assert (Child (T3, 1) = Create (1)
              and Child (T3, 2) = Create (2)
              and Child (T3, 4) = Create (4)
              and Child (Child (T3, 3), 6) = Create (1)
              and (for all I in Small_Pos range 7 .. 10 => Child (Child (T3, 3), I) = Create (5))
              and (for all I in Small_Pos => (if I not in 6 .. 10 then Is_Empty (Child (Child (T3, 3), I))))
              and (for all I in 5 .. Small_Pos'Last => Is_Empty (Child (T3, I))),
	      "Create, children");
   end Test_Create_2;

   procedure Test_Set_Child is

      --  On a tree with no children

      T1 : Tree := Set_Child (Create (10), 1, Create (1));

      --  On a tree with distinct children

      T2 : Tree := Set_Child (Set_Child (Set_Child (T1, 2, Create (2)), 4, Create (4, (1 => Create (1)))), 3, Create (3));

      --  On a tree with an existing child

      T3 : Tree := Set_Child (T2, 3, Create (6, (1 => Create (1, (1 => Create (1))))));
      T4 : Tree := Set_Child (T2, 4, Create (6));

      --  On a tree with an empty child

      T5 : Tree := Set_Child (Set_Child (T2, 3, Empty_Tree), 3, Create (6, (1 => Create (1, (1 => Create (1))))));
      T6 : Tree := Set_Child (Set_Child (T2, 4, Empty_Tree), 4, Create (6));
   begin
      Assert (Get (T1) = 10, "Set_Child on empty tree, get");
      Assert (Child (T1, 1) = Create (1), "Set_Child on empty tree, child");
      Assert (Count (T1) = 2, "Set_Child on empty tree, count");
      Assert (Height (T1) = 2, "Set_Child on empty tree, depth");

      Assert (Get (T2) = 10, "Set_Child distinct child, get");
      Assert (Child (T2, 1) = Create (1)
              and Child (T2, 2) = Create (2)
              and Child (T2, 3) = Create (3)
              and Child (T2, 4) = Create (4, (1 => Create (1))),
	      "Set_Child distinct child, children");
      Assert (Count (T2) = 6, "Set_Child distinct child, count");
      Assert (Height (T2) = 3, "Set_Child distinct child, depth");

      Assert (Get (T3) = 10, "Set_Child with existing child ex1, get");
      Assert (Child (T3, 1) = Create (1)
              and Child (T3, 2) = Create (2)
              and Child (T3, 3) = Create (6, (1 => Create (1, (1 => Create (1)))))
              and Child (T3, 4) = Create (4, (1 => Create (1))),
	      "Set_Child with existing child ex1, children");
      Assert (Count (T3) = 8, "Set_Child with existing child ex1, count");
      Assert (Height (T3) = 4, "Set_Child with existing child ex1, depth");

      Assert (Get (T4) = 10, "Set_Child with existing child ex2, get");
      Assert (Child (T4, 1) = Create (1)
              and Child (T4, 2) = Create (2)
              and Child (T4, 3) = Create (3)
              and Child (T4, 4) = Create (6),
	      "Set_Child with existing child ex2, children");
      Assert (Count (T4) = 5, "Set_Child with existing child ex2, count");
      Assert (Height (T4) = 2, "Set_Child with existing child ex2, depth");

      Assert (Get (T5) = 10, "Set_Child with empty child ex1, get");
      Assert (Child (T5, 1) = Create (1)
              and Child (T5, 2) = Create (2)
              and Child (T5, 3) = Create (6, (1 => Create (1, (1 => Create (1)))))
              and Child (T5, 4) = Create (4, (1 => Create (1))),
	      "Set_Child with empty child ex1, children");
      Assert (Count (T5) = 8, "Set_Child with empty child ex1, count");
      Assert (Height (T5) = 4, "Set_Child with empty child ex1, depth");

      Assert (Get (T6) = 10, "Set_Child with empty child ex2, get");
      Assert (Child (T6, 1) = Create (1)
              and Child (T6, 2) = Create (2)
              and Child (T6, 3) = Create (3)
              and Child (T6, 4) = Create (6),
	      "Set_Child with empty child ex2, children");
      Assert (Count (T6) = 5, "Set_Child with empty child ex2, count");
      Assert (Height (T6) = 2, "Set_Child with empty child ex2, depth");
   end Test_Set_Child;

   procedure Test_Set_Root is
      T : Tree := Create (10, (Create (1), Create (2)));
      T2 : Tree := Set_Root (T, 13);
   begin
      Assert (Get (T2) = 13, "Set_Root, get");
      Assert (Count (T2) = 3, "Set_Root, count");
      Assert (Height (T2) = 2, "Set_Root, depth");
      Assert (Child (T2, 1) = Create (1) and Child (T2, 2) = Create (2)
              and (for all I in 3 .. Small_Pos'Last => Is_Empty (Child (T2, I))),
              "Set_Root, children");
   end Test_Set_Root;

   --  Test default initialization

   procedure Test_Default_Init is
      T : Tree;
   begin
      Assert (Is_Empty (T), "Default init, is empty");
   end Test_Default_Init;

begin
   Test_Empty_Tree;
   Test_Get;
   Test_Child;
   Test_Eq;
   Test_Height;
   Test_Count;
   Test_Count_Children;
   Test_Create_1;
   Test_Create_2;
   Test_Set_Child;
   Test_Set_Root;
   Test_Default_Init;
end Test;
