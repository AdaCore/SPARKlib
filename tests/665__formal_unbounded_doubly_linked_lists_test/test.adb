with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with Inst; use Inst.Int_Lists; use Inst.Sorting;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  A formal doubly linked lists are implemented as a linked structure in an
   --  array. The available cells are stored in a free list.

   --  Create list structure with 5 elements

   procedure Create_Non_Empty_List (X : in out List) is
   begin
      for I in 1 .. 5 loop
         Append (X, I);
      end loop;
   end Create_Non_Empty_List;

   --  Same as above, but introduce holes in the structure to exercize the free
   --  list.

   procedure Create_Non_Empty_List_With_Holes (X : in out List) is
   begin
      for I in 1 .. 7 loop
         Append (X, I);
      end loop;
      declare
         P : Cursor := Next (X, First (X));
      begin
         --  Delete 2
         Delete (X, P);
         P := Next (X, Next (X, Next (X, First (X))));
         --  Delete 5
         Delete (X, P);
      end;
   end Create_Non_Empty_List_With_Holes;

   --  Unbounded containers are resized automatically when they grow. Test
   --  the capability by inserting enough elements in a container.

   procedure Test_Resize with Pre => True is
      X : List;
   begin
      for I in 1 .. 1000 loop
         Append (X, I);
         pragma Loop_Invariant (Length (X) = Count_Type (I));
      end loop;
   end Test_Resize;

   procedure Test_Length with Pre => True is
      X : List;
   begin
      Assert (Length (X) = 0, "Length on empty list");
      Create_Non_Empty_List (X);
      Assert (Length (X) = 5, "Length on non-empty list");
   end Test_Length;

   procedure Test_Empty_List with Pre => True is
   begin
      Assert (Length (Empty_List) = 0, "Empty list is empty");
   end Test_Empty_List;

   procedure Test_Eq with Pre => True is
      X, Y : List;
   begin
      Assert (X = Y, """="" on empty lists");
      Create_Non_Empty_List (X);
      Append (Y, 1);
      Assert (X /= Y, """="" on lists with different lengths");
      Y := X;
      Assert (X = X, """="" on same list");
      Assert (X = Y, """="" on copied list");
      Append (X, 6);
      Append (Y, 1006);
      Assert (X = Y, """="" uses equality on elements");
      Append (X, 7);
      Append (Y, 107);
      Assert (X /= Y, """="" on lists with different elements");
   end Test_Eq;

   procedure Test_Is_Empty with Pre => True is
      X : List;
   begin
      Assert (Is_Empty (X), "Is_Empty on empty list");
      for I in 1 .. 5 loop
         Append (X, I);
      end loop;
      Assert (not Is_Empty (X), "Is_Empty on non-empty list");
   end Test_Is_Empty;

   procedure Test_Clear with Pre => True is
      X : List;
   begin
      Clear (X);
      Assert (Is_Empty (X), "Clear on empty list");
      Create_Non_Empty_List (X);
      Clear (X);
      Assert (Is_Empty (X), "Clear on non-empty list");
      Create_Non_Empty_List_With_Holes (X);
      Clear (X);
      Assert (Is_Empty (X), "Clear on non-empty list with holes");
   end Test_Clear;

   procedure Test_Assign with Pre => True is
      X, Y : List;
   begin
      Create_Non_Empty_List (X);
      Assign (X, Y);
      Assert (Length (X) = 0, "Assign on empty list");
      Create_Non_Empty_List (X);
      --  Calling Assign on aliased parameters results in a high check in SPARK,
      --  but it is not really an error as leaving X as is statisfies the
      --  postcondition.
      Assign (X, X);
      Assert (Length (X) = 5, "Assign on aliased parameters");
      for I in 7 .. 9 loop
         Append (Y, I);
      end loop;
      Assign (X, Y);
      Assert (Length (X) = 3, "Assign on non-aliased parameters");
      Clear (Y);
      Create_Non_Empty_List_With_Holes (Y);
      Assign (X, Y);
      Assert (Length (X) = 5, "Assign list with holes");
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      X : List;
      W : List;
   begin
      declare
         Y : constant List := Copy (X);
      begin
         Assert (Is_Empty (Y), "Copy of empty list");
      end;
      Create_Non_Empty_List (X);
      declare
         Y : constant List := Copy (X);
      begin
         Assert (Y = X, "Copy of non-empty list");
      end;
      Create_Non_Empty_List_With_Holes (W);
      declare
         Y : constant List := Copy (W);
      begin
         Assert (Y = W, "Copy of non-empty list with holes");
      end;
   end Test_Copy;

   procedure Test_Element with Pre => True is
      X : List;
   begin
      Create_Non_Empty_List (X);
      Assert (Element (X, First (X)) = 1 and Element (X, Last (X)) = 5, "Element on non-empty list");
   end Test_Element;

   procedure Test_Replace_Element with Pre => True is
      X : List;
      P2 : Cursor;
      P4 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P2 := Next (X, First (X));
      P4 := Next (X, Next (X, P2));

      Replace_Element (X, P2, 20);

      Assert (Has_Element (X, P2) and then Element (X, P2) = 20, "Replace_Element, the element is replaced");
      Assert (Length (X) = 5, "Replace_Element, length is preserved");
      Assert (Element (X, P4) = 4, "Replace_Element, other cursor/element mappings are preserved");
      Assert (P2 = Next (X, First (X)) and P4 = Next (X, Next (X, P2)), "Replace_Element, order of cursors is preserved");
   end Test_Replace_Element;

   procedure Test_Constant_Reference with Pre => True is
      X : aliased List;
   begin
      Create_Non_Empty_List (X);
      Assert (Constant_Reference (X, First (X)).all = 1 and Constant_Reference (X, Last (X)).all = 5, "Constant_Reference on non-empty list");
   end Test_Constant_Reference;

   procedure Test_Reference with Pre => True is
      X : aliased List;
      P2 : Cursor;
      P4 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P2 := Next (X, First (X));
      P4 := Next (X, Next (X, P2));

      declare
         X_Acc : access List := X'Access;
         R     : access Integer := Reference (X_Acc, P2);
      begin
         Assert (R.all = 2, "Reference on non-empty list");
         R.all := 20;
      end;

      --  Check that the replacement has been made

      Assert (Has_Element (X, P2) and then Element (X, P2) = 20, "Reference, the element is replaced");
      Assert (Length (X) = 5, "Reference, length is preserved");
      Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Reference, other cursor/element mappings are preserved");
      Assert (P2 = Next (X, First (X)) and P4 = Next (X, Next (X, P2)), "Reference, order of cursors is preserved");
   end Test_Reference;

   procedure Test_Move with Pre => True is
      X, Y : List;
   begin
      Create_Non_Empty_List (X);
      Move (X, Y);
      Assert (Is_Empty (X) and Is_Empty (Y), "Move of empty list");
      Create_Non_Empty_List (X);
      for I in 7 .. 9 loop
         Append (Y, I);
      end loop;
      Move (X, Y);
      Assert (Length (X) = 3 and Is_Empty (Y), "Move on non-aliased parameters");
      Create_Non_Empty_List_With_Holes (Y);
      Move (X, Y);
      Assert (Length (X) = 5 and Is_Empty (Y), "Move list with holes");
   end Test_Move;

   --  Insert with no Position or Count parameters
   procedure Test_Insert_1 with Pre => True is
      procedure Test_Insert_In_The_Middle with Pre => True is
         X              : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Insert (X, P3, 7);
         Assert (Length (X) = 6, "Insert 1 element, length is incremented");
         Assert (Has_Element (X, Previous (X, P3)) and then Previous (X, Previous (X, P3)) = P2, "Insert 1 element, a new cursor has been inserted before Before");
         Assert (Element (X, Previous (X, P3)) = 7, "Insert 1 element, the new cursor designates the new value");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Insert 1 element, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Insert 1 element, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, P1), "Insert 1 element, order of previous cursors is preserved");
         Assert (P4 = Next (X, P3), "Insert 1 element, order of following cursors is preserved");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X              : List;
         P1, P2, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P5 := Last (X);
         Insert (X, No_Element, 8);
         Assert (Length (X) = 6, "Insert 1 element at the end, length is incremented");
         Assert (Previous (X, Last (X)) = P5, "Insert 1 element at the end, new cursor is inserted at the end");
         Assert (Element (X, Last (X)) = 8, "Insert 1 element at the end, new cursor designates the new value");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Insert 1 element at the end, other cursor/element mappings are preserved");
         Assert (P2 = Next (X, P1), "Insert 1 element at the end, order of other cursors is preserved");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_1;

   --  Insert with a Count but no Position parameter
   procedure Test_Insert_2 with Pre => True is
      procedure Test_Insert_No_Element with Pre => True is
         X          : List;
         P1, P2, P3 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);

         Insert (X, P3, 7, 0);
         Assert (Length (X) = 5, "Insert 0 elements");
         Insert (X, No_Element, 7, 0);
         Assert (Length (X) = 5, "Insert 0 elements at the end");
      end Test_Insert_No_Element;

      procedure Test_Insert_In_The_Middle with Pre => True is
         X              : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Insert (X, P3, 7, 3);
         Assert (Length (X) = 8, "Insert more than 1 elements, length is incremented");
         Assert (Has_Element (X, Previous (X, P3)) and then Has_Element (X, Previous (X, Previous (X, P3)))
                 and then Has_Element (X, Previous (X, Previous (X, Previous (X, P3)))) and then Previous (X, Previous (X, Previous (X, Previous (X, P3)))) = P2,
                 "Insert more than 1 elements, Count cursors have been inserted before Before");
         Assert (Element (X, Previous (X, P3)) = 7 and Element (X, Previous (X, Previous (X, P3))) = 7 and Element (X, Previous (X, Previous (X, Previous (X, P3)))) = 7,
                 "Insert more than 1 elements, inserted cursors designate the new value");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Insert more than 1 elements, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Insert more than 1 elements, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, First (X)), "Insert more than 1 elements, order of previous cursors is preserved");
         Assert (P4 = Next (X, P3), "Insert more than 1 elements, order of following cursors is preserved");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X  : List;
         P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P5 := Last (X);
         Insert (X, No_Element, 8, 3);
         Assert (Length (X) = 8, "Insert more than 1 element at the end, length is incremented");
         Assert (Previous (X, Previous (X, Previous (X, Last (X)))) = P5, "Insert more than 1 element at the end, Count new cursors are inserted at the end");
         Assert (Element (X, Last (X)) = 8 and Element (X, Previous (X, Last (X))) = 8 and Element (X, Previous (X, Previous (X, Last (X)))) = 8,
                 "Insert more than 1 element at the end, new cursors designate the new value");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_No_Element;
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_2;

   --  Insert with a Position parameter but no Count parameter
   procedure Test_Insert_3 with Pre => True is
      procedure Test_Insert_In_The_Middle with Pre => True is
         X                 : List;
         P1, P2, P3, P4, P : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Insert (X, P3, 7, P);
         Assert (Length (X) = 6, "Insert 1 element, length is incremented");
         Assert (Has_Element (X, P) and then Next (X, P) = P3 and then Previous (X, P) = P2, "Insert 1 element, Position has been inserted before Before");
         Assert (Element (X, P) = 7, "Insert 1 element, P designates the new value");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Insert 1 element, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Insert 1 element, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, First (X)), "Insert 1 element, order of previous cursors is preserved");
         Assert (P4 = Next (X, P3), "Insert 1 element, order of following cursors is preserved");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X     : List;
         P5, P : Cursor;
      begin
         Create_Non_Empty_List (X);
         P5 := Last (X);
         Insert (X, No_Element, 8, P);
         Assert (Length (X) = 6, "Insert 1 element at the end, length is incremented");
         Assert (P = Last (X) and Previous (X, P) = P5, "Insert 1 element at the end, Position is inserted at the end");
         Assert (Element (X, P) = 8, "Insert 1 element at the and, new cursor designates the new value");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_3;

   --  Insert with a Position and a Count parameter
   procedure Test_Insert_4 with Pre => True is
      procedure Test_Insert_No_Element with Pre => True is
         X             : List;
         P1, P2, P3, P : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);

         Insert (X, P3, 7, P, 0);
         Assert (Length (X) = 5 and P = P3, "Insert 0 elements");
         Insert (X, No_Element, 7, P, 0);
         Assert (Length (X) = 5 and P = No_Element, "Insert 0 elements at the end");
      end Test_Insert_No_Element;

      procedure Test_Insert_In_The_Middle with Pre => True is
         X                 : List;
         P1, P2, P3, P4, P : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Insert (X, P3, 7, P, 3);
         Assert (Length (X) = 8, "Insert more than 1 elements, length is incremented");
         Assert (Has_Element (X, P) and then Has_Element (X, Next (X, P))
                 and then Has_Element (X, Next (X, Next (X, P))) and then Next (X, Next (X, Next (X, P))) = P3 and then Previous (X, P) = P2,
                 "Insert more than 1 elements, Count cursors have been inserted starting at Position before Before");
         Assert (Element (X, P) = 7 and Element (X, Next (X, P)) = 7 and Element (X, Next (X, Next (X, P))) = 7,
                 "Insert more than 1 elements, inserted cursors designate the new value");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Insert more than 1 elements, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Insert more than 1 elements, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, First (X)), "Insert more than 1 elements, order of previous cursors is preserved");
         Assert (P4 = Next (X, P3), "Insert more than 1 elements, order of following cursors is preserved");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X     : List;
         P5, P : Cursor;
      begin
         Create_Non_Empty_List (X);
         P5 := Last (X);
         Insert (X, No_Element, 8, P, 3);
         Assert (Length (X) = 8, "Insert more than 1 element at the end, length is incremented");
         Assert (P = Previous (X, Previous (X, Last (X))) and Previous (X, P) = P5, "Insert more than 1 element at the end, Count new cursors are inserted at the end stating at Position");
         Assert (Element (X, P) = 8 and Element (X, Next (X, P)) = 8 and Element (X, Next (X, Next (X, P))) = 8,
                 "Insert more than 1 element at the end, new cursors designate the new value");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_No_Element;
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_4;

   --  Prepend with no Count parameter
   procedure Test_Prepend_1 with Pre => True is
      X      : List;
      P1, P2 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P1 := First (X);
      P2 := Next (X, P1);

      Prepend (X, 7);
      Assert (Length (X) = 6, "Prepend 1 element, length is incremented");
      Assert (Next (X, First (X)) = P1, "Prepend 1 element, a new cursor has been inserted at the beginning");
      Assert (Element (X, First (X)) = 7, "Prepend 1 element, the new cursor designates the new value");
      Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Prepend 1 element, other cursor/element mappings are preserved");
      Assert (P2 = Next (X, P1), "Prepend 1 element, order of other cursors is preserved");
   end Test_Prepend_1;

   --  Prepend with a Count parameter
   procedure Test_Prepend_2 with Pre => True is
      X      : List;
      P1, P2 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P1 := First (X);
      P2 := Next (X, P1);

      Prepend (X, 7, 0);
      Assert (Length (X) = 5, "Prepend 0 elements");

      Prepend (X, 7, 3);
      Assert (Length (X) = 8, "Prepend more than 1 elements, length is incremented");
      Assert (Next (X, Next (X, Next (X, First (X)))) = P1,
              "Prepend more than 1 elements, Count cursors have been inserted at the beginning");
      Assert (Element (X, First (X)) = 7 and Element (X, Next (X, First (X))) = 7 and Element (X, Next (X, Next (X, First (X)))) = 7,
              "Prepend more than 1 elements, inserted cursors designate the new value");
      Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Prepend more than 1 elements, other cursor/element mappings are preserved");
      Assert (P2 = Next (X, P1), "Prepend more than 1 elements, order of other cursors is preserved");
   end Test_Prepend_2;

   --  Append with no Count parameter
   procedure Test_Append_1 with Pre => True is
      X      : List;
      P4, P5 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P5 := Last (X);
      P4 := Previous (X, P5);

      Append (X, 8);
      Assert (Length (X) = 6, "Append 1 element, length is incremented");
      Assert (Previous (X, Last (X)) = P5, "Append 1 element, new cursor is inserted at the end");
      Assert (Element (X, Last (X)) = 8, "Append 1 element, new cursor designates the new value");
      Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Append 1 element, other cursor/element mappings are preserved");
      Assert (P4 = Previous (X, P5), "Append 1 element, order of other cursors is preserved");
   end Test_Append_1;


   --  Append with a Count parameter
   procedure Test_Append_2 with Pre => True is
      X      : List;
      P4, P5 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P5 := Last (X);
      P4 := Previous (X, P5);

      Append (X, 7, 0);
      Assert (Length (X) = 5, "Append 0 elements");

      Append (X, 8, 3);
      Assert (Length (X) = 8, "Append more than 1 elements, length is incremented");
      Assert (Previous (X, Previous (X, Previous (X, Last (X)))) = P5, "Append more than 1 elements, Count new cursors are inserted at the end");
      Assert (Element (X, Last (X)) = 8 and Element (X, Previous (X, Last (X))) = 8 and Element (X, Previous (X, Previous (X, Last (X)))) = 8,
              "Append more than 1 elements, new cursors designate the new value");
      Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Append more than 1 elements, other cursor/element mappings are preserved");
      Assert (P4 = Previous (X, P5), "Append more than 1 elements, order of other cursors is preserved");
   end Test_Append_2;

   --  Delete with no Count parameter
   procedure Test_Delete_1 with Pre => True is
      procedure Test_Delete_In_The_Middle with Pre => True is
         X                  : List;
         P1, P2, P3, P4, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);
         P5 := Last (X);

         Delete (X, P3);
         Assert (Length (X) = 4, "Delete 1 element, length is decremented");
         Assert (P3 = No_Element, "Delete 1 element, Position is set to No_Element");
         Assert (Next (X, P2) = P4, "Delete 1 element, Position has been removed");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Delete 1 element, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Delete 1 element, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, P1), "Delete 1 element, order of previous cursors is preserved");
         Assert (P5 = Next (X, P4), "Delete 1 element, order of following cursors is preserved");
      end Test_Delete_In_The_Middle;

      procedure Test_Delete_First with Pre => True is
         X                  : List;
         P1, P2, P3, P4, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);
         P5 := Last (X);

         Delete (X, P1);
         Assert (Length (X) = 4, "Delete first element, length is decremented");
         Assert (P1 = No_Element, "Delete first element, Position is set to No_Element");
         Assert (First (X) = P2, "Delete first element, Position has been removed");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Delete first element, other cursor/element mappings are preserved");
         Assert (P5 = Next (X, P4), "Delete first element, order of other cursors is preserved");
      end Test_Delete_First;
   begin
      Test_Delete_In_The_Middle;
      Test_Delete_First;
   end Test_Delete_1;

   --  Delete with a Count parameter
   procedure Test_Delete_2 with Pre => True is
      procedure Test_Delete_No_Element with Pre => True is
         X              : List;
         P1, P2, P3     : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);

         Delete (X, P3, 0);
         Assert (Length (X) = 5, "Delete 0 elements, no element has been deleted");
         Assert (P3 = No_Element, "Delete 0 elements, Position is set to No_Element");
      end Test_Delete_No_Element;

      procedure Test_Delete_In_The_Middle with Pre => True is
         X                  : List;
         P1, P2, P3, P6, P7 : Cursor;
      begin
         Create_Non_Empty_List (X);
         Append (X, 6);
         Append (X, 7);
         Append (X, 8);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P6 := Next (X, Next (X, Next (X, P3)));
         P7 := Next (X, P6);

         Delete (X, P3, 3);
         Assert (Length (X) = 5, "Delete more than 1 elements, length is decremented");
         Assert (P3 = No_Element, "Delete more than 1 elements, Position is set to No_Element");
         Assert (Next (X, P2) = P6, "Delete more than 1 elements, Count elements have been removed starting from Position");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Delete more than 1 elements, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P7) and then Element (X, P7) = 7, "Delete more than 1 elements, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, P1), "Delete more than 1 elements, order of previous cursors is preserved");
         Assert (P7 = Next (X, P6), "Delete more than 1 elements, order of following cursors is preserved");
      end Test_Delete_In_The_Middle;

      procedure Test_Delete_Last with Pre => True is
         X              : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Delete (X, P4, 3);
         Assert (Length (X) = 3, "Delete last elements, length is decremented");
         Assert (P4 = No_Element, "Delete last elements, Position is set to No_Element");
         Assert (Last (X) = P3, "Delete last elements, all elements following Position have been removed");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Delete last elements, previous cursor/element mappings are preserved");
         Assert (P2 = Next (X, P1), "Delete last elements, order of previous cursors is preserved");
      end Test_Delete_Last;

   begin
      Test_Delete_No_Element;
      Test_Delete_In_The_Middle;
      Test_Delete_Last;
   end Test_Delete_2;

   --  Delete_First with no Count parameter
   procedure Test_Delete_First_1 with Pre => True is
      X                  : List;
      P1, P2, P3, P4, P5 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P1 := First (X);
      P2 := Next (X, P1);
      P3 := Next (X, P2);
      P4 := Next (X, P3);
      P5 := Last (X);

      Delete_First (X);
      Assert (Length (X) = 4, "Delete_First 1 element, length is decremented");
      Assert (First (X) = P2, "Delete_First 1 element, first element has been removed");
      Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Delete_First 1 element, other cursor/element mappings are preserved");
      Assert (P5 = Next (X, P4), "Delete_First 1 element, order of other cursors is preserved");
   end Test_Delete_First_1;

   --  Delete_First with a Count parameter
   procedure Test_Delete_First_2 with Pre => True is
      X      : List;
      P4, P5 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P5 := Last (X);
      P4 := Previous (X, P5);
      Delete_First (X, 0);
      Assert (Length (X) = 5, "Delete_First 0 elements");

      Delete_First (X, 3);
      Assert (Length (X) = 2, "Delete_First more than 1 elements, length is decremented");
      Assert (First (X) = P4, "Delete_First more than 1 elements, the first Count elements have been removed");
      Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Delete_First more than 1 elements, other cursor/element mappings are preserved");
      Assert (P5 = Next (X, P4), "Delete_First more than 1 elements, order of other cursors is preserved");

      Delete_First (X, 3);
      Assert (Length (X) = 0, "Delete_First all elements");
   end Test_Delete_First_2;

   --  Delete_Last with no Count parameter
   procedure Test_Delete_Last_1 with Pre => True is
      X                  : List;
      P1, P2, P3, P4, P5 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P1 := First (X);
      P2 := Next (X, P1);
      P3 := Next (X, P2);
      P4 := Next (X, P3);
      P5 := Last (X);

      Delete_Last (X);
      Assert (Length (X) = 4, "Delete_Last 1 element, length is decremented");
      Assert (Last (X) = P4, "Delete_Last 1 element, last element has been removed");
      pragma Assert (P2 /= P5);
      Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Delete_Last 1 element, other cursor/element mappings are preserved");
      Assert (P3 = Next (X, P2), "Delete_Last 1 element, order of other cursors is preserved");
   end Test_Delete_Last_1;

   --  Delete_Last with a Count parameter
   procedure Test_Delete_Last_2 with Pre => True is
      X      : List;
      P1, P2 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P1 := First (X);
      P2 := Next (X, P1);
      Delete_Last (X, 0);
      Assert (Length (X) = 5, "Delete_Last 0 elements");

      Delete_Last (X, 3);
      Assert (Length (X) = 2, "Delete_Last more than 1 elements, length is decremented");
      Assert (Last (X) = P2, "Delete_Last more than 1 elements, the last Count elements have been removed");
      Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Delete_Last more than 1 elements, other cursor/element mappings are preserved");
      Assert (P2 = Next (X, P1), "Delete_Last more than 1 elements, order of other cursors is preserved");

      Delete_Last (X, 3);
      Assert (Length (X) = 0, "Delete_Last all elements");
   end Test_Delete_Last_2;

   procedure Test_Reverse_Elements with Pre => True is
      X  : List;
      EF : Integer;
   begin
      --  Call Reverse_Elements on lists of various lengths

      for I in 1 .. 10 loop
         Append (X, I);
         EF := Element (X, First (X));
         Reverse_Elements (X);
         Assert (Length (X) = Count_Type (I), "Reverse_Elements preserves length");
         Assert (Element (X, First (X)) = I and Element (X, Last (X)) = EF, "Reverse_Elements reverses elements");
         pragma Loop_Invariant (Length (X) = Count_Type (I));
      end loop;
   end Test_Reverse_Elements;

   procedure Test_Swap with Pre => True is
      X  : List;
      P1, P2, P3, P4 : Cursor;
   begin
      Create_Non_Empty_List (X);
      P1 := First (X);
      P2 := Next (X, P1);
      P3 := Next (X, P2);
      P4 := Next (X, P3);

      Swap (X, P4, P4);
      Assert (Length (X) = 5, "Swap same pointer, length is preserved");
      Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Swap same pointer, value of swapped pointer is preserved");
      Assert (Next (X, P3) = P4, "Swap same pointer, position of swapped pointer is preserved");
      Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Swap same pointer, other cursor/element mappings are preserved");
      Assert (P2 = Next (X, P1), "Swap same pointer, order of other cursors is preserved");

      Swap (X, P2, P4);
      Assert (Length (X) = 5, "Swap different pointers, length is preserved");
      Assert (Has_Element (X, P2) and then Element (X, P2) = 4 and then Has_Element (X, P4) and then Element (X, P4) = 2, "Swap different pointers, values of swapped pointers are swapped");
      Assert (Next (X, P1) = P2 and Next (X, P3) = P4, "Swap different pointers, positions of swapped pointers are preserved");
      Assert (Has_Element (X, P3) and then Element (X, P3) = 3, "Swap different pointers, other cursor/element mappings are preserved");
      Assert (P3 = Next (X, Next (X, P1)), "Swap different pointers, order of other cursors is preserved");
   end Test_Swap;

   procedure Test_Swap_Links with Pre => True is
      procedure Test_Swap_Links_Same_Pointer with Pre => True is
         X              : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Swap_Links (X, P4, P4);
         Assert (Length (X) = 5, "Swap_Links same pointer, length is preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Swap_Links same pointer, value of swapped pointer is preserved");
         Assert (Next (X, P3) = P4, "Swap_Links same pointer, position of swapped pointer is preserved");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Swap_Links same pointer, other cursor/element mappings are preserved");
         Assert (P2 = Next (X, P1), "Swap_Links same pointer, order of other cursors is preserved");
      end Test_Swap_Links_Same_Pointer;

      procedure Test_Swap_Links_Distinct with Pre => True is
         X              : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Swap_Links (X, P2, P4);
         Assert (Length (X) = 5, "Swap_Links different pointers, length is preserved");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2 and then Has_Element (X, P4) and then Element (X, P4) = 4, "Swap_Links different pointers, values of swapped pointers are preserved");
         Assert (Next (X, P1) = P4 and Next (X, P3) = P2, "Swap_Links different pointers, positions of swapped pointers are swapped");
         Assert (Has_Element (X, P3) and then Element (X, P3) = 3, "Swap_Links different pointers, other cursor/element mappings are preserved");
         Assert (P3 = Next (X, Next (X, P1)), "Swap_Links different pointers, order of other cursors is preserved");
      end Test_Swap_Links_Distinct;

      procedure Test_Swap_Links_Next with Pre => True is
         X              : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, P1);
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Swap_Links (X, P2, P3);
         Assert (Length (X) = 5, "Swap next, length is preserved");
         Assert (Has_Element (X, P3) and then Element (X, P3) = 3 and then Has_Element (X, P2) and then Element (X, P2) = 2, "Swap_Link next, values of swapped pointers are preserved");
         Assert (Next (X, P1) = P3 and Previous (X, P4) = P2, "Swap next, positions of swapped pointers are swapped");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Swap next, other cursor/element mappings are preserved");
         Assert (P4 = Next (X, Next (X, Next (X, P1))), "Swap next, order of other cursors is preserved");

         Swap_Links (X, P2, P3);
         Assert (Next (X, P1) = P2 and Previous (X, P4) = P3, "Swap next twice, positions of swapped pointers are preserved");
      end Test_Swap_Links_Next;

   begin
      Test_Swap_Links_Same_Pointer;
      Test_Swap_Links_Distinct;
      Test_Swap_Links_Next;
   end Test_Swap_Links;

   --  Splice with different Source and Target and no Position parameter
   procedure Test_Splice_1 with Pre => True is
      procedure Test_Splice_Empty with Pre => True is
         X, Y       : List;
         P1, P2, P3 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);

         Splice (X, P3, Y);
         Assert (Length (X) = 5, "Splice empty list, target is unchanged");
         Assert (Length (Y) = 0, "Splice empty list, source is empty");
         Splice (X, No_Element, Y);
         Assert (Length (X) = 5, "Splice empty list at the end, target is unchanged");
         Assert (Length (Y) = 0, "Splice empty list at the end, source is empty");
      end Test_Splice_Empty;

      procedure Test_Splice_In_The_Middle with Pre => True is
         X, Y           : List;
         P1, P2, P3, P4 : Cursor;
      begin
         Create_Non_Empty_List (X);
         Append (Y, 6);
         Append (Y, 7);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);

         Splice (X, P3, Y);
         Assert (Length (X) = 7, "Splice, length is increased");
         Assert (Has_Element (X, Previous (X, P3)) and then Has_Element (X, Previous (X, Previous (X, P3)))
                 and then Previous (X, Previous (X, Previous (X, P3))) = P2
                 and then ((Element (X, Next (X, P2)) = 6 and Element (X, Previous (X, P3)) = 7)
                   or (Element (X, Next (X, P2)) = 7 and Element (X, Previous (X, P3)) = 6)),
                 "Splice, Source has been inserted before Before in an unspecified order");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Splice, previous cursor/element mappings are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Splice, following cursor/element mappings are preserved");
         Assert (P2 = Next (X, First (X)), "Splice, order of previous cursors is preserved");
         Assert (P4 = Next (X, P3), "Splice, order of following cursors is preserved");
         Assert (Length (Y) = 0, "Splice, Source has been cleared");
      end Test_Splice_In_The_Middle;

      procedure Test_Splice_At_The_End with Pre => True is
         X, Y : List;
         P5   : Cursor;
      begin
         Create_Non_Empty_List (X);
         Append (Y, 6);
         Append (Y, 7);
         P5 := Last (X);

         Splice (X, No_Element, Y);
         Assert (Length (X) = 7, "Splice at the end, length is incremented");
         Assert (Previous (X, Previous (X, Last (X))) = P5
                 and then ((Element (X, Next (X, P5)) = 6 and Element (X, Last (X)) = 7)
                   or (Element (X, Next (X, P5)) = 7 and Element (X, Last (X)) = 6)),
                 "Splice at the end, Source has been inserted at the end in an unspecified order");
         Assert (Length (Y) = 0, "Splice at the end, Source has been cleared");
      end Test_Splice_At_The_End;
   begin
      Test_Splice_Empty;
      Test_Splice_In_The_Middle;
      Test_Splice_At_The_End;
   end Test_Splice_1;

   --  Splice with different Source and Target and a Position parameter
   procedure Test_Splice_2 with Pre => True is
      procedure Test_Splice_In_The_Middle with Pre => True is
         X, Y : List;
         P1, P2, P3, P4, P6, P7, P8 : Cursor;
      begin
         Create_Non_Empty_List (X);
         Append (Y, 6);
         Append (Y, 7);
         Append (Y, 8);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);
         P6 := First (Y);
         P7 := Next (Y, P6);
         P8 := Last (Y);

         Splice (X, P3, Y, P7);
         Assert (Length (X) = 6, "Splice element, length of Target is incremented");
         Assert (Has_Element (X, P7) and then Next (X, P7) = P3 and then Previous (X, P7) = P2, "Splice element, Position has been inserted in Target before Before");
         Assert (Element (X, P7) = 7, "Splice element, P designates in Target the value it used to designate in Source");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2, "Splice element, previous cursor/element mappings in Target are preserved");
         Assert (Has_Element (X, P4) and then Element (X, P4) = 4, "Splice element, following cursor/element mappings in Target are preserved");
         Assert (P2 = Next (X, First (X)), "Splice element, order of previous cursors in Target is preserved");
         Assert (P4 = Next (X, P3), "Splice element, order of following cursors in Target is preserved");

         Assert (Length (Y) = 2, "Splice element, length of Source is decremented");
         Assert (Next (Y, P6) = P8, "Splice element, Position has been removed from Source");
         Assert (Has_Element (Y, P6) and then Element (Y, P6) = 6, "Splice element, previous cursor/element mappings in Source are preserved");
         Assert (Has_Element (Y, P8) and then Element (Y, P8) = 8, "Splice element, following cursor/element mappings in Source are preserved");
         Assert (P6 = First (Y), "Splice element, order of previous cursors in Source is preserved");
         Assert (P8 = Last (Y), "Splice element, order of following cursors in Source is preserved");
      end Test_Splice_In_The_Middle;

      procedure Test_Splice_At_The_End with Pre => True is
         X, Y           : List;
         P5, P6, P7, P8 : Cursor;
      begin
         Create_Non_Empty_List (X);
         Append (Y, 6);
         Append (Y, 7);
         Append (Y, 8);
         P5 := Last (X);
         P6 := First (Y);
         P7 := Next (Y, P6);

         Splice (X, No_Element, Y, P7);
         Assert (Length (X) = 6, "Splice element at the end, length of Target is incremented");
         Assert (P7 = Last (X) and Previous (X, P7) = P5, "Splice element at the end, Position is inserted in Target at the end");
         Assert (Element (X, P7) = 7, "Splice element at the and, P designates in Target the value it used to designate in Source");
         Assert (Length (Y) = 2, "Splice element at the end, length of Source is decremented");
      end Test_Splice_At_The_End;
   begin
      Test_Splice_In_The_Middle;
      Test_Splice_At_The_End;
   end Test_Splice_2;

   --  Splice with a single Container parameter
   procedure Test_Splice_3 with Pre => True is
      procedure Test_Splice_Same_Position with Pre => True is
         X  : List;
         P2, P3, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P5 := Last (X);

         Splice (X, P3, P3);
         Assert (Length (X) = 5, "Splice single container same position, length is preserved");
         Assert (P3 = Next (X, P2), "Splice single container same position, Position is not moved");
         Splice (X, P3, P2);
         Assert (Length (X) = 5, "Splice single container before is next, length is preserved");
         Assert (P3 = Next (X, P2), "Splice single container before is next, Position is not moved");
         Splice (X, No_Element, P5);
         Assert (Last (X) = P5, "Splice single container last element at the end, Position is unchanged");
      end Test_Splice_Same_Position;

      procedure Test_Splice_In_The_Middle with Pre => True is
         X : List;
         P1, P2, P3, P4, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);
         P5 := Last (X);

         Splice (X, P2, P4);
         Assert (Length (X) = 5, "Splice single container, length is preserved");
         Assert (Next (X, P4) = P2 and Previous (X, P4) = P1 and Next (X, P3) = P5, "Splice single container, Position has been moved before Before");
         Assert (Element (X, P4) = 4, "Splice single container, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container, other mappings are preserved");

         Splice (X, P2, P5);
         Assert (Next (X, P5) = P2 and Previous (X, P5) = P4 and Last (X) = P3, "Splice single container last element, Position has been moved before Before");
         Assert (Element (X, P5) = 5, "Splice single container last element, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container last element, other mappings are preserved");

         Splice (X, P2, P1);
         Assert (Next (X, P1) = P2 and Previous (X, P1) = P5 and First (X) = P4, "Splice single container first element, Position has been moved before Before");
         Assert (Element (X, P1) = 1, "Splice single container first element, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container first element, other mappings are preserved");
      end Test_Splice_In_The_Middle;

      procedure Test_Splice_At_The_Beginning with Pre => True is
         X : List;
         P1, P2, P3, P4, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);
         P5 := Last (X);

         Splice (X, P1, P4);
         Assert (Length (X) = 5, "Splice single container at the beginning, length is preserved");
         Assert (Next (X, P4) = P1 and First (X) = P4 and Next (X, P3) = P5, "Splice single container at the beginning, Position has been moved before Before");
         Assert (Element (X, P4) = 4, "Splice single container at the beginning, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container at the beginning, other mappings are preserved");

         Splice (X, P4, P5);
         Assert (Next (X, P5) = P4 and First (X) = P5 and Last (X) = P3, "Splice single container last element at the beginning, Position has been moved before Before");
         Assert (Element (X, P5) = 5, "Splice single container last element at the beginning, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container last element at the beginning, other mappings are preserved");
      end Test_Splice_At_The_Beginning;

      procedure Test_Splice_At_The_End with Pre => True is
         X : List;
         P1, P2, P3, P4, P5 : Cursor;
      begin
         Create_Non_Empty_List (X);
         P1 := First (X);
         P2 := Next (X, First (X));
         P3 := Next (X, P2);
         P4 := Next (X, P3);
         P5 := Last (X);

         Splice (X, No_Element, P3);
         Assert (Length (X) = 5, "Splice single container at the end, length is preserved");
         Assert (Last (X) = P3 and Previous (X, P3) = P5 and Next (X, P2) = P4, "Splice single container at the end, Position has been moved at the end");
         Assert (Element (X, P4) = 4, "Splice single container at the end, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container at the end, other mappings are preserved");

         Splice (X, No_Element, P1);
         Assert (Last (X) = P1 and Previous (X, P1) = P3 and First (X) = P2, "Splice single container first element at the end, Position has been moved at the end");
         Assert (Element (X, P1) = 1, "Splice single container first element at the end, P designates the same element");
         Assert (Has_Element (X, P2) and then Element (X, P2) = 2
                 and then Has_Element (X, P3) and then Element (X, P3) = 3, "Splice single container first element at the end, other mappings are preserved");
      end Test_Splice_At_The_End;
   begin
      Test_Splice_Same_Position;
      Test_Splice_In_The_Middle;
      Test_Splice_At_The_Beginning;
      Test_Splice_At_The_End;
   end Test_Splice_3;

   procedure Test_First with Pre => True is
      X : List;
   begin
      Assert (First (X) = No_Element, "First on empty list");
      Create_Non_Empty_List (X);
      Assert (Has_Element (X, First (X)) and Element (X, First (X)) = 1, "First on non empty list");
   end Test_First;

   procedure Test_First_Element with Pre => True is
      X : List;
   begin
      Create_Non_Empty_List (X);
      Assert (First_Element (X) = 1, "First_Element");
   end Test_First_Element;

   procedure Test_Last with Pre => True is
      X : List;
   begin
      Assert (Last (X) = No_Element, "Last on empty list");
      Create_Non_Empty_List (X);
      Assert (Has_Element (X, Last (X)) and Element (X, Last (X)) = 5, "Last on non empty list");
   end Test_Last;

   procedure Test_Last_Element with Pre => True is
      X : List;
   begin
      Create_Non_Empty_List (X);
      Assert (Last_Element (X) = 5, "Last_Element");
   end Test_Last_Element;

   procedure Test_Next with Pre => True is
      X : List;
      P : Cursor := No_Element;
   begin
      Create_Non_Empty_List (X);

      Assert (Next (X, P) = No_Element, "Next function on No_Element");
      Next (X, P);
      Assert (P = No_Element, "Next procedure on No_Element");

      P := Last (X);
      Assert (Next (X, P) = No_Element, "Next function on last");
      Next (X, P);
      Assert (P = No_Element, "Next procedure on last");

      P := First (X);
      Assert (Has_Element (X, Next (X, P)) and then Element (X, Next (X, P)) = 2, "Next function on other");
      Next (X, P);
      Assert (Has_Element (X, P) and then Element (X, P) = 2, "Next procedure on other");
   end Test_Next;

   procedure Test_Previous with Pre => True is
      X : List;
      P : Cursor := No_Element;
   begin
      Create_Non_Empty_List (X);

      Assert (Previous (X, P) = No_Element, "Previous function on No_Element");
      Previous (X, P);
      Assert (P = No_Element, "Previous procedure on No_Element");

      P := First (X);
      Assert (Previous (X, P) = No_Element, "Previous function on first");
      Previous (X, P);
      Assert (P = No_Element, "Previous procedure on first");

      P := Last (X);
      Assert (Has_Element (X, Previous (X, P)) and then Element (X, Previous (X, P)) = 4, "Previous function on other");
      Previous (X, P);
      Assert (Has_Element (X, P) and then Element (X, P) = 4, "Previous procedure on other");
   end Test_Previous;

   procedure Test_Find with Pre => True is
      X              : List;
      P2, P3, P5, P4 : Cursor;
   begin
      Assert (Find (X, 1, No_Element) = No_Element, "Find on empty list");

      Create_Non_Empty_List (X);
      P2 := Next (X, First (X));
      P3 := Next (X, P2);
      P4 := Next (X, P3);
      P5 := Last (X);
      Append (X, 3);

      Assert (Find (X, 1, No_Element) = First (X) and Find (X, 5, No_Element) = P5, "Find starting from the beginning, element is present");
      Assert (Find (X, 7, No_Element) = No_Element, "Find starting from the beginning, element is not present");
      Assert (Find (X, 3, No_Element) = P3, "Find starting from the beginning, returns the first occurrence");
      Assert (Find (X, 1004, No_Element) = P4, "Find starting from the beginning, use provided equality function");

      Assert (Find (X, 2, P2) = P2 and Find (X, 5, P2) = P5, "Find, element is present after position");
      Assert (Find (X, 1, P2) = No_Element, "Find, element is present before position");
      Assert (Find (X, 7, P2) = No_Element, "Find, element is not present");
      Assert (Find (X, 3, P2) = P3, "Find, returns the first occurrence");
      Assert (Find (X, 3, P4) = Last (X), "Find, returns the first occurrence after position");
      Assert (Find (X, 1004, P2) = P4, "Find, use provided equality function");
   end Test_Find;

   procedure Test_Reverse_Find with Pre => True is
      X              : List;
      P1, P2, P3, P4 : Cursor;
   begin
      Assert (Reverse_Find (X, 1, No_Element) = No_Element, "Reverse_Find on empty list");

      Create_Non_Empty_List (X);
      Prepend (X, 3);
      P1 := Next (X, First (X));
      P2 := Next (X, P1);
      P3 := Next (X, P2);
      P4 := Next (X, P3);

      Assert (Reverse_Find (X, 5, No_Element) = Last (X) and Reverse_Find (X, 1, No_Element) = P1, "Reverse_Find starting from the end, element is present");
      Assert (Reverse_Find (X, 7, No_Element) = No_Element, "Reverse_Find starting from the end, element is not present");
      Assert (Reverse_Find (X, 3, No_Element) = P3, "Reverse_Find starting from the end, returns the last occurrence");
      Assert (Reverse_Find (X, 1002, No_Element) = P2, "Reverse_Find starting from the end, use provided equality function");

      Assert (Reverse_Find (X, 4, P4) = P4 and Reverse_Find (X, 1, P4) = P1, "Reverse_Find, element is present before position");
      Assert (Reverse_Find (X, 5, P4) = No_Element, "Reverse_Find, element is present after position");
      Assert (Reverse_Find (X, 7, P4) = No_Element, "Reverse_Find, element is not present");
      Assert (Reverse_Find (X, 3, P4) = P3, "Reverse_Find, returns the last occurrence");
      Assert (Reverse_Find (X, 3, P2) = First (X), "Reverse_Find, returns the last occurrence before position");
      Assert (Reverse_Find (X, 1002, P4) = P2, "Reverse_Find, use provided equality function");
   end Test_Reverse_Find;

   procedure Test_Contains with Pre => True is
      X : List;
   begin
      Assert (not Contains (X, 1), "Contains on empty list");

      Create_Non_Empty_List (X);

      Assert (Contains (X, 1), "Contains, element is present");
      Assert (not Contains (X, 7), "Contains, element is not present");
      Assert (Contains (X, 1004), "Contains, use provided equality function");
   end Test_Contains;

   procedure Test_Has_Element with Pre => True is
      X : List;
      P : Cursor;
   begin
      Create_Non_Empty_List (X);
      Assert (not Has_Element (X, No_Element), "Has_Element on No_Element");
      P := First (X);
      Assert (Has_Element (X, P), "Has_Element returns True");
      Delete_First (X);
      Assert (not Has_Element (X, P), "Has_Element returns False");
   end Test_Has_Element;

   procedure Test_Is_Sorted with Pre => True is
      X  : List;
      P3 : Cursor;
   begin
      Assert (Is_Sorted (X), "Is_Sorted empty list");

      Create_Non_Empty_List (X);
      P3 := Next (X, Next (X, First (X)));

      Assert (Is_Sorted (X), "Is_Sorted sorted list");

      Replace_Element (X, P3, 1003);

      Assert (Is_Sorted (X), "Is_Sorted uses user-provided <");

      Replace_Element (X, P3, 7);

      Assert (not Is_Sorted (X), "Is_Sorted unsorted list");
   end Test_Is_Sorted;

   procedure Test_Sort with Pre => True is
      X : List;
   begin
      Sort (X);
      Assert (Length (X) = 0, "Sort empty list");

      Create_Non_Empty_List (X);
      Append (X, 6);
      Append (X, 7);
      Append (X, 9);
      Append (X, 9);
      Sort (X);
      Assert (Length (X) = 9 and First_Element (X) = 1 and Last_Element (X) = 9, "Sort sorted list");

      Append (X, 1000);
      Sort (X);
      Assert (Length (X) = 10 and First_Element (X) = 1000 and Last_Element (X) = 9, "Sort uses user-provided <");
   end Test_Sort;

   procedure Test_Merge with Pre => True is
      X, Y : List;
   begin
      Merge (X, Y);
      Assert (Length (X) = 0, "Merge empty lists");
      Create_Non_Empty_List (X);
      Merge (X, Y);
      Assert (Length (Y) = 0 and Length (X) = 5 and First_Element (X) = 1 and Last_Element (X) = 5, "Merge empty list right");
      Merge (Y, X);
      Assert (Length (X) = 0 and Length (Y) = 5 and First_Element (Y) = 1 and Last_Element (Y) = 5, "Merge empty list left");

      Append (X, 0);
      Append (X, 1);
      Append (X, 3);
      Append (X, 6);
      Append (X, 7);
      Merge (X, Y);
      Assert (Is_Sorted (X), "Merge non-empty lists is sorted");
      Assert (Length (Y) = 0 and Length (X) = 10 and First_Element (X) = 0 and Last_Element (X) = 7, "Merge non-empty lists");
   end Test_Merge;

   procedure Test_Iteration with Pre => True is
      X : List;
   begin
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, empty list");
      Assert ((for all E of X => E /= 0), "for of iteration, empty list");

      Create_Non_Empty_List (X);
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, non-empty list");
      Assert ((for some E of X => E = 3), "for of iteration, non-empty list");
   end Test_Iteration;

   procedure Test_Aggregate with Pre => True is
      X : List := [1, 2, 3, 4, 5];
   begin
      Assert (Length (X) = 5, "aggregate, length");
      Assert (First_Element (X) = 1 and Last_Element (X) = 5, "aggregate, elements");
   end Test_Aggregate;

begin
   Test_Resize;
   Test_Length;
   Test_Empty_List;
   Test_Eq;
   Test_Is_Empty;
   Test_Clear;
   Test_Assign;
   Test_Copy;
   Test_Element;
   Test_Replace_Element;
   Test_Constant_Reference;
   Test_Reference;
   Test_Move;
   Test_Insert_1;
   Test_Insert_2;
   Test_Insert_3;
   Test_Insert_4;
   Test_Prepend_1;
   Test_Prepend_2;
   Test_Append_1;
   Test_Append_2;
   Test_Delete_1;
   Test_Delete_2;
   Test_Delete_First_1;
   Test_Delete_First_2;
   Test_Delete_Last_1;
   Test_Delete_Last_2;
   Test_Reverse_Elements;
   Test_Swap;
   Test_Swap_Links;
   Test_Splice_1;
   Test_Splice_2;
   Test_Splice_3;
   Test_First;
   Test_First_Element;
   Test_Last;
   Test_Last_Element;
   Test_Next;
   Test_Previous;
   Test_Find;
   Test_Reverse_Find;
   Test_Contains;
   Test_Has_Element;
   Test_Is_Sorted;
   Test_Sort;
   Test_Merge;
   Test_Iteration;
   Test_Aggregate;
end Test;
