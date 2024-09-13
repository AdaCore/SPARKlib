with Ada.Text_IO;
with SPARK.Containers.Types; use SPARK.Containers.Types;

procedure Test_Gen with SPARK_Mode is
   use Inst.Int_Vectors; use Inst.Sorting;

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   --  A formal vector is implemented as an array slice.

   --  Create vector with 5 elements

   procedure Create_Non_Empty_Vector (X : in out Vector) is
   begin
      for I in 1 .. 5 loop
         Append (X, I);
      end loop;
   end Create_Non_Empty_Vector;

   procedure Test_Empty_Vector with Pre => True is
      X : Vector := Empty_Vector;
   begin
      Assert (Length (X) = 0, "Empty_Vector is empty");
   end Test_Empty_Vector;

   procedure Test_Length with Pre => True is
      X : Vector;
   begin
      Assert (Length (X) = 0, "Length on empty vector");
      Create_Non_Empty_Vector (X);
      Assert (Length (X) = 5, "Length on non-empty vector");
   end Test_Length;

   procedure Test_Eq with Pre => True is
      X, Y : Vector;
   begin
      Assert (X = Y, """="" on empty vectors");
      Create_Non_Empty_Vector (X);
      Append (Y, 1);
      Assert (X /= Y, """="" on vectors with different lengths");
      Y := X;
      Assert (X = X, """="" on same vector");
      Assert (X = Y, """="" on copied vector");
      Append (X, 6);
      Append (Y, 1006);
      Assert (X = Y, """="" uses equality on elements");
      Append (X, 7);
      Append (Y, 107);
      Assert (X /= Y, """="" on vectors with different elements");
   end Test_Eq;

   procedure Test_To_Vector with Pre => True is
   begin
      Assert (Is_Empty (To_Vector (1, 0)), "To_Vector with Length = 0 is empty");
      Assert (Length (To_Vector (1, 10)) = 10, "To_Vector, Length is Length");
      Assert (First_Element (To_Vector (1, 10)) = 1 and Last_Element (To_Vector (1, 10)) = 1, "To_Vector, elements are New_Item");
   end Test_To_Vector;

   procedure Test_Is_Empty with Pre => True is
      X : Vector;
   begin
      Assert (Is_Empty (X), "Is_Empty on empty vector");
      Create_Non_Empty_Vector (X);
      Assert (not Is_Empty (X), "Is_Empty on non-empty vector");
   end Test_Is_Empty;

   procedure Test_Clear with Pre => True is
      X : Vector;
   begin
      Clear (X);
      Assert (Is_Empty (X), "Clear on empty vector");
      Create_Non_Empty_Vector (X);
      Clear (X);
      Assert (Is_Empty (X), "Clear on non-empty vector");
   end Test_Clear;

   procedure Test_Assign with Pre => True is
      X, Y : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Assign (X, Y);
      Assert (Length (X) = 0, "Assign on empty vector");
      Create_Non_Empty_Vector (X);
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
   end Test_Assign;

   procedure Test_Copy with Pre => True is
      X : Vector;
   begin
      declare
         Y : constant Vector := Copy (X);
      begin
         Assert (Is_Empty (Y), "Copy of empty vector");
      end;
      Create_Non_Empty_Vector (X);
      declare
         Y : constant Vector := Copy (X);
      begin
         Assert (Y = X, "Copy of non-empty vector");
      end;
   end Test_Copy;

   procedure Test_Move with Pre => True is
      X, Y : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Move (X, Y);
      Assert (Is_Empty (X) and Is_Empty (Y), "Move of empty vector");
      Create_Non_Empty_Vector (X);
      for I in 7 .. 9 loop
         Append (Y, I);
      end loop;
      Move (X, Y);
      Assert (Length (X) = 3 and Is_Empty (Y), "Move on non-aliased parameters");
   end Test_Move;

   procedure Test_Element with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Assert (Element (X, 1) = 1 and Element (X, Last_Index (X)) = 5, "Element on non-empty vector");
   end Test_Element;

   procedure Test_Replace_Element with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Replace_Element (X, 2, 20);

      Assert (Element (X, 2) = 20, "Replace_Element, the element is replaced");
      Assert (Length (X) = 5, "Replace_Element, length is preserved");
      Assert (Element (X, 4) = 4, "Replace_Element, other elements are preserved");
   end Test_Replace_Element;

   procedure Test_Constant_Reference with Pre => True is
      X : aliased Vector;
   begin
      Create_Non_Empty_Vector (X);
      Assert (Constant_Reference (X, 1).all = 1 and Constant_Reference (X, Last_Index (X)).all = 5, "Constant_Reference on non-empty vector");
   end Test_Constant_Reference;

   procedure Test_Reference with Pre => True is
      X : aliased Vector;
   begin
      Create_Non_Empty_Vector (X);

      declare
         X_Acc : access Vector := X'Access;
         R     : access Integer := Reference (X_Acc, 2);
      begin
         Assert (R.all = 2, "Reference on non-empty vector");
         R.all := 20;
      end;

      --  Check that the replacement has been made

      Assert (Element (X, 2) = 20, "Reference, the element is replaced");
      Assert (Length (X) = 5, "Reference, length is preserved");
      Assert (Element (X, 4) = 4, "Reference, other elements are preserved");
   end Test_Reference;

   --  Insert vector
   procedure Test_Insert_1 with Pre => True is
      procedure Test_Insert_In_The_Middle with Pre => True is
         X, Y : Vector;
      begin
         Create_Non_Empty_Vector (X);
         Append (Y, 6);
         Append (Y, 7);
         Append (Y, 8);

         Insert (X, 3, Y);
         Assert (Length (X) = 8, "Insert vector, length is incremented");
         Assert (Element (X, 3) = 6 and Element (X, 4) = 7 and Element (X, 5) = 8, "Insert vector, a new vector has been inserted before Before");
         Assert (Element (X, 2) = 2, "Insert vector, previous elements are preserved");
         Assert (Element (X, 7) = 4, "Insert vector, following elements are shifted");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X, Y : Vector;
      begin
         Create_Non_Empty_Vector (X);
         Append (Y, 6);
         Append (Y, 7);
         Append (Y, 8);

         Insert (X, 6, Y);
         Assert (Length (X) = 8, "Insert vector at the end, length is incremented");
         Assert (Element (X, 6) = 6 and Element (X, 7) = 7 and Element (X, 8) = 8, "Insert vector at the end, new vector is inserted at the end");
         Assert (Element (X, 2) = 2, "Insert vector at the end, other elements are preserved");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_1;

   --  Insert element with no Count parameter
   procedure Test_Insert_2 with Pre => True is
      procedure Test_Insert_In_The_Middle with Pre => True is
         X  : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Insert (X, 3, 7);
         Assert (Length (X) = 6, "Insert 1 element, length is incremented");
         Assert (Element (X, 3) = 7, "Insert 1 element, the new value is stored at index Before");
         Assert (Element (X, 2) = 2, "Insert 1 element, previous elements are preserved");
         Assert (Element (X, 5) = 4, "Insert 1 element, following elements are shifted");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Insert (X, 6, 8);
         Assert (Length (X) = 6, "Insert 1 element at the end, length is incremented");
         Assert (Element (X, Last_Index (X)) = 8, "Insert 1 element at the end, new value is inserted at the end");
         Assert (Has_Element (X, 2) and then Element (X, 2) = 2, "Insert 1 element at the end, other elements are preserved");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_2;

   --  Insert elements with a Count parameter
   procedure Test_Insert_3 with Pre => True is
      procedure Test_Insert_No_Element with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Insert (X, 3, 7, 0);
         Assert (Length (X) = 5, "Insert 0 elements");
         Insert (X, 6, 7, 0);
         Assert (Length (X) = 5, "Insert 0 elements at the end");
      end Test_Insert_No_Element;

      procedure Test_Insert_In_The_Middle with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Insert (X, 3, 7, 3);
         Assert (Length (X) = 8, "Insert more than 1 elements, length is incremented");
         Assert (Element (X, 3) = 7 and Element (X, 4) = 7 and Element (X, 5) = 7,
                 "Insert more than 1 elements, Count times New_Item have been inserted before Before");
         Assert (Element (X, 2) = 2, "Insert more than 1 elements, previous elements are preserved");
         Assert (Element (X, 7) = 4, "Insert more than 1 elements, following elements are shifted");
      end Test_Insert_In_The_Middle;

      procedure Test_Insert_At_The_End with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Insert (X, 6, 8, 3);
         Assert (Length (X) = 8, "Insert more than 1 element at the end, length is incremented");
         Assert (Element (X, 6) = 8 and Element (X, 7) = 8 and Element (X, 8) = 8,
                 "Insert more than 1 element at the end, Count times New_Item are inserted at the end");
         Assert (Element (X, 2) = 2, "Insert more than 1 elements at the end, previous elements are preserved");
      end Test_Insert_At_The_End;
   begin
      Test_Insert_No_Element;
      Test_Insert_In_The_Middle;
      Test_Insert_At_The_End;
   end Test_Insert_3;

   --  Prepend vector
   procedure Test_Prepend_1 with Pre => True is
      X, Y : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Append (Y, 6);
      Append (Y, 7);
      Append (Y, 8);

      Prepend (X, Y);
      Assert (Length (X) = 8, "Prepend vector, length is incremented");
      Assert (Element (X, 1) = 6 and Element (X, 2) = 7 and Element (X, 3) = 8, "Prepend vector, New_Item has been inserted at the beginning");
      Assert (Element (X, 5) = 2, "Prepend vector, other elements are shifted");
   end Test_Prepend_1;

   --  Prepend element with no Count parameter
   procedure Test_Prepend_2 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Prepend (X, 7);
      Assert (Length (X) = 6, "Prepend 1 element, length is incremented");
      Assert (Element (X, 1) = 7, "Prepend 1 element, New_Item has been inserted at the beginning");
      Assert (Element (X, 3) = 2, "Prepend 1 element, other elements are shifted");
   end Test_Prepend_2;

   --  Prepend element with a Count parameter
   procedure Test_Prepend_3 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Prepend (X, 7, 0);
      Assert (Length (X) = 5, "Prepend 0 elements");

      Prepend (X, 7, 3);
      Assert (Length (X) = 8, "Prepend more than 1 elements, length is incremented");
      Assert (Element (X, 1) = 7 and Element (X, 2) = 7 and Element (X, 3) = 7,
              "Prepend more than 1 elements, Count times New_Item have been inserted at the beginning");
      Assert (Element (X, 5) = 2, "Prepend more than 1 elements, other elements are shifted");
   end Test_Prepend_3;

   --  Append vector
   procedure Test_Append_1 with Pre => True is
      X, Y : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Append (Y, 6);
      Append (Y, 7);
      Append (Y, 8);

      Append (X, Y);
      Assert (Length (X) = 8, "Append vector, length is incremented");
      Assert (Element (X, 6) = 6 and Element (X, 7) = 7 and Element (X, 8) = 8, "Append vector, New_Item has been inserted at the end");
      Assert (Element (X, 2) = 2, "Append vector, other elements are preserved");
   end Test_Append_1;

   --  Append with no Count parameter
   procedure Test_Append_2 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Append (X, 8);
      Assert (Length (X) = 6, "Append 1 element, length is incremented");
      Assert (Element (X, 6) = 8, "Append 1 element, New_Item has been inserted at the end");
      Assert (Element (X, 2) = 2, "Append 1 element, other elements are preserved");
   end Test_Append_2;

   --  Append with a Count parameter
   procedure Test_Append_3 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Append (X, 7, 0);
      Assert (Length (X) = 5, "Append 0 elements");

      Append (X, 8, 3);
      Assert (Length (X) = 8, "Append more than 1 elements, length is incremented");
      Assert (Element (X, 6) = 8 and Element (X, 7) = 8 and Element (X, 8) = 8, "Append more than 1 elements, Count times New_Item have been inserted at the end");
      Assert (Element (X, 2) = 2, "Append more than 1 element, other elements are preserved");
   end Test_Append_3;

   --  Delete with no Count parameter

   procedure Test_Delete_1 with Pre => True is
      procedure Test_Delete_In_The_Middle with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Delete (X, 3);
         Assert (Length (X) = 4, "Delete 1 element, length is decremented");
         Assert (Element (X, 1) = 1 and Element (X, 2) = 2, "Delete 1 element, previous elements are preserved");
         Assert (Element (X, 3) = 4 and Element (X, 4) = 5, "Delete 1 element, following elements are slided");
      end Test_Delete_In_The_Middle;

      procedure Test_Delete_First with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Delete (X, 1);
         Assert (Length (X) = 4, "Delete first element, length is decremented");
         Assert (Element (X, 1) = 2 and Element (X, 2) = 3 and Element (X, 3) = 4 and Element (X, 4) = 5, "Delete 1 element, following elements are slided");
      end Test_Delete_First;
   begin
      Test_Delete_In_The_Middle;
      Test_Delete_First;
   end Test_Delete_1;

   --  Delete with a Count parameter
   procedure Test_Delete_2 with Pre => True is
      procedure Test_Delete_No_Element with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Delete (X, 3, 0);
         Assert (Length (X) = 5, "Delete 0 elements, no element has been deleted");
      end Test_Delete_No_Element;

      procedure Test_Delete_In_The_Middle with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);
         Append (X, 6);
         Append (X, 7);

         Delete (X, 3, 3);
         Assert (Length (X) = 4, "Delete more than 1 elements, length is decremented");
         Assert (Element (X, 1) = 1 and Element (X, 2) = 2, "Delete more than 1 elements, previous elements are preserved");
         Assert (Element (X, 3) = 6 and Element (X, 4) = 7, "Delete more than 1 elements, following elements are slided");
      end Test_Delete_In_The_Middle;

      procedure Test_Delete_Last with Pre => True is
         X : Vector;
      begin
         Create_Non_Empty_Vector (X);

         Delete (X, 4, 3);
         Assert (Length (X) = 3, "Delete last elements, length is decremented");
         Assert (Element (X, 1) = 1 and Element (X, 2) = 2 and Element (X, 3) = 3, "Delete last elements, previous elements are preserved");
      end Test_Delete_Last;

   begin
      Test_Delete_No_Element;
      Test_Delete_In_The_Middle;
      Test_Delete_Last;
   end Test_Delete_2;

   --  Delete_First with no Count parameter
   procedure Test_Delete_First_1 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Delete_First (X);
      Assert (Length (X) = 4, "Delete_First 1 element, length is decremented");
      Assert (Element (X, 1) = 2 and then Element (X, 3) = 4, "Delete_First 1 element, other elements are shifted");
   end Test_Delete_First_1;

   --  Delete_First with a Count parameter
   procedure Test_Delete_First_2 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Delete_First (X, 0);
      Assert (Length (X) = 5, "Delete_First 0 elements");

      Delete_First (X, 3);
      Assert (Length (X) = 2, "Delete_First more than 1 elements, length is decremented");
      Assert (Element (X, 1) = 4 and then Element (X, 2) = 5, "Delete_First more than 1 element, other elements are shifted");

      Delete_First (X, 3);
      Assert (Length (X) = 0, "Delete_First all elements");
   end Test_Delete_First_2;

   --  Delete_Last with no Count parameter
   procedure Test_Delete_Last_1 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Delete_Last (X);
      Assert (Length (X) = 4, "Delete_Last 1 element, length is decremented");
      Assert (Element (X, 1) = 1 and then Element (X, 3) = 3, "Delete_Last 1 element, other elements are preserved");
   end Test_Delete_Last_1;

   --  Delete_Last with a Count parameter
   procedure Test_Delete_Last_2 with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Delete_Last (X, 0);
      Assert (Length (X) = 5, "Delete_Last 0 elements");

      Delete_Last (X, 3);
      Assert (Length (X) = 2, "Delete_Last more than 1 elements, length is decremented");
      Assert (Element (X, 1) = 1 and then Element (X, 2) = 2, "Delete_Last more than 1 element, other elements are preserved");

      Delete_Last (X, 3);
      Assert (Length (X) = 0, "Delete_Last all elements");
   end Test_Delete_Last_2;

   procedure Test_Reverse_Elements with Pre => True is
      X : Vector;
   begin
      Reverse_Elements (X);
      Assert (Length (X) = 0, "Reverse_Elements on empty vector");

      Append (X, 0);
      Reverse_Elements (X);
      Assert (Length (X) = 1 and Element (X, 1) = 0, "Reverse_Elements on singleton");

      Create_Non_Empty_Vector (X);
      Reverse_Elements (X);
      Assert (Length (X) = 6 and Element (X, 6) = 0 and Element (X, 1) = 5, "Reverse_Elements on longer vector");
   end Test_Reverse_Elements;

   procedure Test_Swap with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);

      Swap (X, 4, 4);
      Assert (Length (X) = 5, "Swap same index, length is preserved");
      Assert (Element (X, 4) = 4, "Swap same index, value of swapped index is preserved");
      Assert (Element (X, 2) = 2 and Element (X, 5) = 5, "Swap same index, other indexes are preserved");

      Swap (X, 2, 4);
      Assert (Length (X) = 5, "Swap different indexes, length is preserved");
      Assert (Element (X, 2) = 4 and then Element (X, 4) = 2, "Swap different indexes, values of swapped indexes are swapped");
      Assert (Element (X, 1) = 1 and then Element (X, 3) = 3 and then Element (X, 5) = 5, "Swap different indexes, other indexes are preserved");
   end Test_Swap;

   procedure Test_First_Element with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Assert (First_Element (X) = 1, "First_Element");
   end Test_First_Element;

   procedure Test_Last_Element with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Assert (Last_Element (X) = 5, "Last_Element");
   end Test_Last_Element;

   procedure Test_Find_Index with Pre => True is
      X : Vector;
   begin
      Assert (Find_Index (X, 1) = No_Index, "Find_Index on empty vector");

      Create_Non_Empty_Vector (X);
      Append (X, 3);

      Assert (Find_Index (X, 1) = 1 and Find_Index (X, 5, 1) = 5, "Find_Index starting from the beginning, element is present");
      Assert (Find_Index (X, 7) = No_Index, "Find_Index starting from the beginning, element is not present");
      Assert (Find_Index (X, 3) = 3, "Find_Index starting from the beginning, returns the first occurrence");
      Assert (Find_Index (X, 1004) = 4, "Find_Index starting from the beginning, use provided equality function");

      Assert (Find_Index (X, 2, 2) = 2 and Find_Index (X, 5, 2) = 5, "Find_Index, element is present after index");
      Assert (Find_Index (X, 1, 2) = No_Index, "Find_Index, element is present before index");
      Assert (Find_Index (X, 7, 2) = No_Index, "Find_Index, element is not present");
      Assert (Find_Index (X, 3, 2) = 3, "Find_Index, returns the first occurrence");
      Assert (Find_Index (X, 3, 4) = 6, "Find_Index, returns the first occurrence after index");
      Assert (Find_Index (X, 1004, 2) = 4, "Find_Index, use provided equality function");
   end Test_Find_Index;

   procedure Test_Reverse_Find_Index with Pre => True is
      X : Vector;
   begin
      Assert (Reverse_Find_Index (X, 1) = No_Index, "Reverse_Find_Index on empty vector");

      Create_Non_Empty_Vector (X);
      Prepend (X, 3);

      Assert (Reverse_Find_Index (X, 5) = 6 and Reverse_Find_Index (X, 1) = 2, "Reverse_Find_Index starting from the end, element is present");
      Assert (Reverse_Find_Index (X, 7) = No_Index, "Reverse_Find_Index starting from the end, element is not present");
      Assert (Reverse_Find_Index (X, 3) = 4, "Reverse_Find_Index starting from the end, returns the last occurrence");
      Assert (Reverse_Find_Index (X, 1002) = 3, "Reverse_Find_Index starting from the end, use provided equality function");

      Assert (Reverse_Find_Index (X, 4, 5) = 5 and Reverse_Find_Index (X, 1, 5) = 2, "Reverse_Find_Index, element is present before index");
      Assert (Reverse_Find_Index (X, 5, 5) = No_Index, "Reverse_Find_Index, element is present after index");
      Assert (Reverse_Find_Index (X, 7, 5) = No_Index, "Reverse_Find_Index, element is not present");
      Assert (Reverse_Find_Index (X, 3, 5) = 4, "Reverse_Find_Index, returns the last occurrence");
      Assert (Reverse_Find_Index (X, 3, 3) = 1, "Reverse_Find_Index, returns the last occurrence before index");
      Assert (Reverse_Find_Index (X, 1002, 5) = 3, "Reverse_Find_Index, use provided equality function");
   end Test_Reverse_Find_Index;

   procedure Test_Contains with Pre => True is
      X : Vector;
   begin
      Assert (not Contains (X, 1), "Contains on empty vector");

      Create_Non_Empty_Vector (X);

      Assert (Contains (X, 1), "Contains, element is present");
      Assert (not Contains (X, 7), "Contains, element is not present");
      Assert (Contains (X, 1004), "Contains, use provided equality function");
   end Test_Contains;

   procedure Test_Has_Element with Pre => True is
      X : Vector;
   begin
      Create_Non_Empty_Vector (X);
      Assert (not Has_Element (X, No_Index), "Has_Element on No_Index");
      Assert (Has_Element (X, 3), "Has_Element returns True");
      Assert (not Has_Element (X, 6), "Has_Element returns False");
   end Test_Has_Element;

   procedure Test_Is_Sorted with Pre => True is
      X : Vector;
   begin
      Assert (Is_Sorted (X), "Is_Sorted empty vector");

      Create_Non_Empty_Vector (X);

      Assert (Is_Sorted (X), "Is_Sorted sorted vector");

      Replace_Element (X, 3, 1003);

      Assert (Is_Sorted (X), "Is_Sorted uses user-provided <");

      Replace_Element (X, 3, 7);

      Assert (not Is_Sorted (X), "Is_Sorted unsorted vector");
   end Test_Is_Sorted;

   procedure Test_Sort with Pre => True is
      X : Vector;
   begin
      Sort (X);
      Assert (Length (X) = 0, "Sort empty vector");

      Create_Non_Empty_Vector (X);
      Append (X, 6);
      Append (X, 7);
      Append (X, 9);
      Append (X, 9);
      Sort (X);
      Assert (Length (X) = 9 and First_Element (X) = 1 and Last_Element (X) = 9, "Sort sorted vector");

      Append (X, 1000);
      Sort (X);
      Assert (Length (X) = 10 and First_Element (X) = 1000 and Last_Element (X) = 9, "Sort uses user-provided <");
   end Test_Sort;

   procedure Test_Merge with Pre => True is
      X, Y : Vector;
   begin
      Merge (X, Y);
      Assert (Length (X) = 0, "Merge empty vectors");
      Create_Non_Empty_Vector (X);
      Merge (X, Y);
      Assert (Length (Y) = 0 and Length (X) = 5 and First_Element (X) = 1 and Last_Element (X) = 5, "Merge empty vector right");
      Merge (Y, X);
      Assert (Length (X) = 0 and Length (Y) = 5 and First_Element (Y) = 1 and Last_Element (Y) = 5, "Merge empty vector left");

      Append (X, 0);
      Append (X, 1);
      Append (X, 3);
      Append (X, 6);
      Append (X, 7);
      Merge (X, Y);
      Assert (Is_Sorted (X), "Merge non-empty vectors is sorted");
      Assert (Length (Y) = 0 and Length (X) = 10 and First_Element (X) = 0 and Last_Element (X) = 7, "Merge non-empty vectors");
   end Test_Merge;

   procedure Test_Iteration with Pre => True is
      X : Vector;
   begin
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, empty vector");
      Assert ((for all E of X => E /= 0), "for of iteration, empty vector");

      Create_Non_Empty_Vector (X);
      Assert ((for all P in X => Element (X,  P) /= 0), "for in iteration, non-empty vector");
      Assert ((for some E of X => E = 3), "for of iteration, non-empty vector");
   end Test_Iteration;

   procedure Test_Aggregate with Pre => True is
      X : Vector := [1, 2, 3, 4, 5];
   begin
      Assert (Length (X) = 5, "aggregate, length");
      Assert (First_Element (X) = 1 and Last_Element (X) = 5, "aggregate, elements");
   end Test_Aggregate;

begin
   Test_Empty_Vector;
   Test_Length;
   Test_Eq;
   Test_To_Vector;
   Test_Is_Empty;
   Test_Clear;
   Test_Assign;
   Test_Copy;
   Test_Move;
   Test_Element;
   Test_Replace_Element;
   Test_Constant_Reference;
   Test_Reference;
   Test_Insert_1;
   Test_Insert_2;
   Test_Insert_3;
   Test_Prepend_1;
   Test_Prepend_2;
   Test_Prepend_3;
   Test_Append_1;
   Test_Append_2;
   Test_Append_3;
   Test_Delete_1;
   Test_Delete_2;
   Test_Delete_First_1;
   Test_Delete_First_2;
   Test_Delete_Last_1;
   Test_Delete_Last_2;
   Test_Reverse_Elements;
   Test_Swap;
   Test_First_Element;
   Test_Last_Element;
   Test_Find_Index;
   Test_Reverse_Find_Index;
   Test_Contains;
   Test_Has_Element;
   Test_Is_Sorted;
   Test_Sort;
   Test_Merge;
   Test_Iteration;
   Test_Aggregate;
end Test_Gen;
