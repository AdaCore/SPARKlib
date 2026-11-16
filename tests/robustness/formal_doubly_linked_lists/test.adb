pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Doubly_Linked_Lists;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Containers.Doubly_Linked_Lists;

procedure Test is
   Last_Label    : Unbounded_String := Null_Unbounded_String;
   First_Failure : Unbounded_String := Null_Unbounded_String;
   Failure_Count : Natural := 0;

   procedure Set_Label (Label : String) is
   begin
      Last_Label := To_Unbounded_String (Label);
   end Set_Label;

   procedure Record_Failure is
   begin
      Failure_Count := Failure_Count + 1;
      if Failure_Count = 1 then
         First_Failure := Last_Label;
      end if;
   end Record_Failure;

   procedure Check_Results is
   begin
      if Failure_Count /= 0 then
         raise Program_Error with
           Natural'Image (Failure_Count)
           & " defensive checks failed; first: "
           & To_String (First_Failure);
      end if;
   end Check_Results;

   function Eq (X, Y : Integer) return Boolean is (X mod 1000 = Y mod 1000);
   function Lt (X, Y : Integer) return Boolean is (X mod 1000 < Y mod 1000);
   package Int_Lists is new SPARK.Containers.Formal.Doubly_Linked_Lists
     (Integer, "=" => Eq);
   package Sorting is new Int_Lists.Generic_Sorting (Lt);
   use Int_Lists;

   --  Create list structure with 5 elements

   procedure Create_Non_Empty_List (X : in out List) is
   begin
      for I in 1 .. 5 loop
         Append (X, I);
      end loop;
   end Create_Non_Empty_List;

   procedure Test_Element is
      procedure Test_Element_No_Element is
         X : List (5);
         I : Integer;
      begin
         Set_Label ("Element with No_Element: ");
         Create_Non_Empty_List (X);
         begin
            I := Element (X, Next (X, Last (X)));
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_No_Element;

      procedure Test_Element_Deleted_Element is
         X : List (5);
         I : Integer;
         P1, P2 : Cursor;
      begin
         Set_Label ("Element with deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            I := Element (X, P2);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_Deleted_Element;
   begin
      Test_Element_No_Element;
      Test_Element_Deleted_Element;
   end Test_Element;

   procedure Test_Replace_Element is
      procedure Test_Replace_Element_No_Element is
         X : List (5);
      begin
         Set_Label ("Replace_Element with No_Element: ");
         Create_Non_Empty_List (X);
         begin
            Replace_Element (X, Next (X, Last (X)), 1);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_No_Element;

      procedure Test_Replace_Element_Deleted_Element is
         X : List (5);
         I : Integer;
         P1, P2 : Cursor;
      begin
         Set_Label ("Replace_Element with deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            Replace_Element (X, P2, 1);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_Deleted_Element;
   begin
      Test_Replace_Element_No_Element;
      Test_Replace_Element_Deleted_Element;
   end Test_Replace_Element;

   procedure Test_Constant_Reference is
      procedure Test_Constant_Reference_No_Element is
         X : aliased List (10);
      begin
         Set_Label ("Constant_Reference with No_Element: ");
         Create_Non_Empty_List (X);
         begin
            declare
               I : constant Integer := Constant_Reference (X, Next (X, Last (X))).all;
            begin
               null;
            end;
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Constant_Reference_No_Element;

      procedure Test_Constant_Reference_Deleted_Element is
         X : aliased List (5);
         I : Integer;
         P1, P2 : Cursor;
      begin
         Set_Label ("Constant_Reference with deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            declare
               I : constant Integer := Constant_Reference (X, P2).all;
            begin
               null;
            end;
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Constant_Reference_Deleted_Element;
   begin
      Test_Constant_Reference_No_Element;
      Test_Constant_Reference_Deleted_Element;
   end Test_Constant_Reference;

   procedure Test_Reference is
      procedure Test_Reference_No_Element is
         X : aliased List (10);
      begin
         Set_Label ("Reference with No_Element: ");
         Create_Non_Empty_List (X);
         begin
            declare
               I : constant Integer := Reference (X, No_Element).all;
            begin
               null;
            end;
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Reference_No_Element;

      procedure Test_Reference_Deleted_Element is
         X : aliased List (5);
         I : Integer;
         P1, P2 : Cursor;
      begin
         Set_Label ("Reference with deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            declare
               I : constant Integer := Reference (X, P2).all;
            begin
               null;
            end;
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Reference_Deleted_Element;
   begin
      Test_Reference_No_Element;
      Test_Reference_Deleted_Element;
   end Test_Reference;

   procedure Test_Assign is
      X : List (5);
      Y : List (4);
   begin
      Set_Label ("Assign: ");
      Create_Non_Empty_List (X);
      begin
         Assign (Y, X);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Assign;

   procedure Test_Copy is
      X : List (5);
   begin
      Set_Label ("Copy: ");
      Create_Non_Empty_List (X);
      begin
         declare
            Y : List := Copy (X, 4);
         begin
            null;
         end;
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Copy;

   procedure Test_Move is
      procedure Test_Move_Full_Container is
         X : List (5);
         Y : List (4);
      begin
         Set_Label ("Move with full container: ");
         Create_Non_Empty_List (X);
         begin
            Move (Y, X);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Move_Full_Container;

   begin
      Test_Move_Full_Container;
   end Test_Move;

   procedure Test_Insert is
      procedure Test_Insert_Full_Container is
         X : List (5);
      begin
         Set_Label ("Insert with container full: ");
         Create_Non_Empty_List (X);
         begin
            Insert (X, First (X), 0);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Full_Container;

      procedure Test_Insert_Before_Deleted_Element is
         X : List (5);
         P1, P2 : Cursor;
      begin
         Set_Label ("Insert with deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Next (X, First (X));
         P2 := P1;
         Delete (X, P1);
         begin
            Insert (X, P2, 0);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Before_Deleted_Element;
   begin
      Test_Insert_Full_Container;
      Test_Insert_Before_Deleted_Element;
   end Test_Insert;

   procedure Test_Insert_2 is
      procedure Test_Insert_2_Full_Container is
         X : List (5);
      begin
         Set_Label ("Insert 2 with container full: ");
         Create_Non_Empty_List (X);
         begin
            Insert (X, First (X), 0, 1);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_2_Full_Container;

      procedure Test_Insert_2_Count is
         X : List (5);
      begin
         Set_Label ("Insert 2 with count: ");
         Create_Non_Empty_List (X);
         Delete_Last (X);
         begin
            Insert (X, First (X), 0, 2);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_2_Count;

      procedure Test_Insert_2_Before_Deleted_Element is
         X : List (5);
         P1, P2 : Cursor;
      begin
         Set_Label ("Insert 2 with not contained element: ");
         Create_Non_Empty_List (X);
         P1 := Next (X, First (X));
         P2 := P1;
         Delete (X, P1);
         begin
            Insert (X, P2, 0, 1);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_2_Before_Deleted_Element;
   begin
      Test_Insert_2_Full_Container;
      Test_Insert_2_Count;
      Test_Insert_2_Before_Deleted_Element;
   end Test_Insert_2;

   procedure Test_Insert_3 is
      procedure Test_Insert_3_Full_Container is
         X : List (5);
         P : Cursor;
      begin
         Set_Label ("Insert 3 with container full: ");
         Create_Non_Empty_List (X);
         begin
            Insert (X, First (X), 0, P);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_3_Full_Container;

      procedure Test_Insert_3_Before_Deleted_Element is
         X : List (5);
         P, P1, P2 : Cursor;
      begin
         Set_Label ("Insert 3 with not contained element: ");
         Create_Non_Empty_List (X);
         P1 := Next (X, First (X));
         P2 := P1;
         Delete (X, P1);
         begin
            Insert (X, P2, 0, P);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_3_Before_Deleted_Element;
   begin
      Test_Insert_3_Full_Container;
      Test_Insert_3_Before_Deleted_Element;
   end Test_Insert_3;

   procedure Test_Insert_4 is
      procedure Test_Insert_4_Full_Container is
         X : List (5);
         P : Cursor;
      begin
         Set_Label ("Insert 4 with container full: ");
         Create_Non_Empty_List (X);
         begin
            Insert (X, First (X), 0, P, 1);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_4_Full_Container;

      procedure Test_Insert_4_Count is
         X : List (5);
         P : Cursor;
      begin
         Set_Label ("Insert 4 with count: ");
         Create_Non_Empty_List (X);
         Delete_Last (X);
         begin
            Insert (X, First (X), 0, P, 2);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_4_Count;

      procedure Test_Insert_4_Before_Deleted_Element is
         X : List (5);
         P, P1, P2 : Cursor;
      begin
         Set_Label ("Insert 4 with not contained element: ");
         Create_Non_Empty_List (X);
         P1 := Next (X, First (X));
         P2 := P1;
         Delete (X, P1);
         begin
            Insert (X, P2, 0, P, 1);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_4_Before_Deleted_Element;
   begin
      Test_Insert_4_Full_Container;
      Test_Insert_4_Count;
      Test_Insert_4_Before_Deleted_Element;
   end Test_Insert_4;

   procedure Test_Prepend is
      X : List (5);
   begin
      Set_Label ("Prepend: ");
      Create_Non_Empty_List (X);
      begin
         Prepend (X, 0);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Prepend;

   procedure Test_Prepend_2 is
      X : List (5);
   begin
      Set_Label ("Prepend 2: ");
      Create_Non_Empty_List (X);
      Delete_Last (X);
      begin
         Prepend (X, 6, 2);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Prepend_2;

   procedure Test_Append is
      X : List (5);
   begin
      Set_Label ("Append: ");
      Create_Non_Empty_List (X);
      begin
         Append (X, 6);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Append;

   procedure Test_Append_2 is
      X : List (5);
   begin
      Set_Label ("Append 2: ");
      Create_Non_Empty_List (X);
      Delete_Last (X);
      begin
         Append (X, 6, 2);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Append_2;

   procedure Test_Delete is
      procedure Test_Delete_No_Element is
         X : List (5);
         P : Cursor;
      begin
         Set_Label ("Delete: ");
         Create_Non_Empty_List (X);
         P := Next (X, Last (X));
         begin
            Delete (X, P);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_No_Element;

      procedure Test_Delete_Deleted_Element is
         X : List (5);
         I : Integer;
         P1, P2 : Cursor;
      begin
         Set_Label ("Delete with deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            Delete (X, P2);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Deleted_Element;

      procedure Test_Delete_Count_No_Element is
         X : List (5);
         P : Cursor := No_Element;
      begin
         Set_Label ("Delete with Count and No_Element: ");
         Create_Non_Empty_List (X);
         begin
            Delete (X, P, 1);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Count_No_Element;

      procedure Test_Delete_Count_Deleted_Element is
         X : List (5);
         P1, P2 : Cursor;
      begin
         Set_Label ("Delete with Count and deleted element: ");
         Create_Non_Empty_List (X);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            Delete (X, P2, 1);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Count_Deleted_Element;
   begin
      Test_Delete_No_Element;
      Test_Delete_Deleted_Element;
      Test_Delete_Count_No_Element;
      Test_Delete_Count_Deleted_Element;
   end Test_Delete;

   procedure Test_Swap is
      procedure Test_Swap_I_No_Element is
         X : List (5);
         I, J : Cursor;
      begin
         Set_Label ("Swap with I = No_Element: ");
         Create_Non_Empty_List (X);
         I := No_Element;
         J := Last (X);
         begin
            Swap (X, I, J);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_I_No_Element;

      procedure Test_Swap_I_Deleted_Element is
         X : List (5);
         I, J, Tmp : Cursor;
      begin
         Set_Label ("Swap with not Has_Element (I): ");
         Create_Non_Empty_List (X);
         Tmp := Find (X, 3);
         I := Tmp;
         Delete (X, Tmp);
         J := Last (X);
         begin
            Swap (X, I, J);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_I_Deleted_Element;

      procedure Test_Swap_J_No_Element is
         X : List (5);
         I, J : Cursor;
      begin
         Set_Label ("Swap with J = No_Element: ");
         Create_Non_Empty_List (X);
         I := Last (X);
         J := No_Element;
         begin
            Swap (X, I, J);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_J_No_Element;

      procedure Test_Swap_J_Deleted_Element is
         X : List (5);
         I, J, Tmp : Cursor;
      begin
         Set_Label ("Swap with not Has_Element (J): ");
         Create_Non_Empty_List (X);
         Tmp := Find (X, 3);
         J := Tmp;
         Delete (X, Tmp);
         I := Last (X);
         begin
            Swap (X, I, J);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_J_Deleted_Element;
   begin
      Test_Swap_I_No_Element;
      Test_Swap_I_Deleted_Element;
      Test_Swap_J_No_Element;
      Test_Swap_J_Deleted_Element;
   end Test_Swap;

   procedure Test_Swap_Links is
      procedure Test_Swap_Links_I_No_Element is
         X : List (5);
         I, J : Cursor;
      begin
         Set_Label ("Swap_Links with I = No_Element: ");
         Create_Non_Empty_List (X);
         I := No_Element;
         J := Last (X);
         begin
            Swap_Links (X, I, J);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_Links_I_No_Element;

      procedure Test_Swap_Links_I_Deleted_Element is
         X : List (5);
         I, J, Tmp : Cursor;
      begin
         Set_Label ("Swap_Links with not Has_Element (I): ");
         Create_Non_Empty_List (X);
         Tmp := Find (X, 3);
         I := Tmp;
         Delete (X, Tmp);
         J := Last (X);
         begin
            Swap_Links (X, I, J);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_Links_I_Deleted_Element;

      procedure Test_Swap_Links_J_No_Element is
         X : List (5);
         I, J : Cursor;
      begin
         Set_Label ("Swap_Links with J = No_Element: ");
         Create_Non_Empty_List (X);
         I := Last (X);
         J := No_Element;
         begin
            Swap_Links (X, I, J);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_Links_J_No_Element;

      procedure Test_Swap_Links_J_Deleted_Element is
         X : List (5);
         I, J, Tmp : Cursor;
      begin
         Set_Label ("Swap_Links with not Has_Element (J): ");
         Create_Non_Empty_List (X);
         Tmp := Find (X, 3);
         J := Tmp;
         Delete (X, Tmp);
         I := Last (X);
         begin
            Swap_Links (X, I, J);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_Links_J_Deleted_Element;
   begin
      Test_Swap_Links_I_No_Element;
      Test_Swap_Links_I_Deleted_Element;
      Test_Swap_Links_J_No_Element;
      Test_Swap_Links_J_Deleted_Element;
   end Test_Swap_Links;

   procedure Test_Splice is
      procedure Test_Splice_Before_Deleted_Element is
         X : List (5);
         B1, B2, Position : Cursor;
      begin
         Set_Label ("Splice with not Has_Element (Before): ");
         Create_Non_Empty_List (X);
         B1 := Next (X, First (X));
         B2 := B1;
         Delete (X, B1);
         Position := Last (X);
         begin
            Splice (X, B2, Position);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_Before_Deleted_Element;

      procedure Test_Splice_Position_No_Element is
         X : List (5);
         Before, Position : Cursor;
      begin
         Set_Label ("Splice with Position = No_Element: ");
         Create_Non_Empty_List (X);
         Before := Next (X, First (X));
         Position := Next (X, Last (X));
         begin
            Splice (X, Before, Position);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_Position_No_Element;

      procedure Test_Splice_Before_Deleted_And_Position_No_Element is
         X : List (5);
         B1, B2 : Cursor;
         Position : Cursor := No_Element;
      begin
         Set_Label ("Splice with invalid Before and No_Element Position: ");
         Create_Non_Empty_List (X);
         B1 := Next (X, First (X));
         B2 := B1;
         Delete (X, B1);
         begin
            Splice (X, B2, Position);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_Before_Deleted_And_Position_No_Element;

      procedure Test_Splice_Position_Deleted_Element is
         X : List (5);
         Before, P1, P2 : Cursor;
      begin
         Set_Label ("Splice with not Has_Element (Position): ");
         Create_Non_Empty_List (X);
         Before := Next (X, First (X));
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         begin
            Splice (X, Before, P2);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_Position_Deleted_Element;
   begin
      Test_Splice_Before_Deleted_Element;
      Test_Splice_Position_No_Element;
      Test_Splice_Before_Deleted_And_Position_No_Element;
      Test_Splice_Position_Deleted_Element;
   end Test_Splice;

   procedure Test_Splice_2 is
      procedure Test_Splice_2_Full_Container is
         X : List (5);
         Y : List (10);
         Before : Cursor;
      begin
         Set_Label ("Splice 2 with full container: ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         Append (Y, 6);
         Before := Next (Y, First (Y));
         begin
            Splice (Y, Before, X);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_2_Full_container;

      procedure Test_Splice_2_Before_Deleted_Element is
         X : List (5);
         Y : List (10);
         B1, B2 : Cursor;
      begin
         Set_Label ("Splice 2 with not Has_Element (Before): ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         B1 := Next (Y, First (Y));
         B2 := B1;
         Delete (Y, B1);
         begin
            Splice (Y, B2, X);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_2_Before_Deleted_Element;

   begin
      Test_Splice_2_Full_Container;
      Test_Splice_2_Before_Deleted_Element;
   end Test_Splice_2;

   procedure Test_Splice_3 is
      procedure Test_Splice_3_Full_Container is
         X : List (5);
         Y : List (5);
         Before, Position : Cursor;
      begin
         Set_Label ("Splice 3 with full container: ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         Before := Next (Y, First (Y));
         Position := Last (X);
         begin
            Splice (Y, Before, X, Position);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_3_Full_Container;

      procedure Test_Splice_3_Before_Deleted_Element is
         X : List (5);
         Y : List (10);
         B1, B2, Position : Cursor;
      begin
         Set_Label ("Splice 3 with not Has_Element (Before): ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         B1 := Next (Y, First (Y));
         B2 := B1;
         Delete (Y, B1);
         Position := Last (X);
         begin
            Splice (Y, B2, X, Position);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_3_Before_Deleted_Element;

      procedure Test_Splice_3_Position_No_Element is
         X : List (5);
         Y : List (10);
         Before, Position : Cursor;
      begin
         Set_Label ("Splice 3 with Position = No_Element: ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         Before := Next (Y, First (Y));
         Position := Next (X, Last (X));
         begin
            Splice (Y, Before, X, Position);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_3_Position_No_Element;

      procedure Test_Splice_3_Before_Deleted_And_Position_No_Element is
         X : List (5);
         Y : List (10);
         B1, B2 : Cursor;
         Position : Cursor := No_Element;
      begin
         Set_Label ("Splice 3 with invalid Before and No_Element Position: ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         B1 := Next (Y, First (Y));
         B2 := B1;
         Delete (Y, B1);
         begin
            Splice (Y, B2, X, Position);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_3_Before_Deleted_And_Position_No_Element;

      procedure Test_Splice_3_Position_Deleted_Element is
         X : List (5);
         Y : List (10);
         Before, P1, P2 : Cursor;
      begin
         Set_Label ("Splice 3 with not Has_Element (Position):");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         P1 := Find (X, 3);
         P2 := P1;
         Delete (X, P1);
         Before := Next (Y, First (Y));
         begin
            Splice (Y, Before, X, P2);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Splice_3_Position_Deleted_Element;

   begin
      Test_Splice_3_Full_Container;
      Test_Splice_3_Before_Deleted_Element;
      Test_Splice_3_Position_No_Element;
      Test_Splice_3_Before_Deleted_And_Position_No_Element;
      Test_Splice_3_Position_Deleted_Element;
   end Test_Splice_3;

   procedure Test_First_Element is
      X : List (5) := Empty_List (5);
      I : Integer;
   begin
      Set_Label ("First_Element: ");
      begin
         I := First_Element (X);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_First_Element;

   procedure Test_Last_Element is
      X : List (5) := Empty_List (5);
      I : Integer;
   begin
      Set_Label ("Last_Element: ");
      begin
         I := Last_Element (X);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Last_Element;

   procedure Test_Next is
      X : List (5);
      P1, P2 : Cursor;
   begin
      Set_Label ("Next: ");
      Create_Non_Empty_List (X);
      P1 := Next (X, First (X));
      P2 := P1;
      Delete (X, P1);
      begin
         P2 := Next (X, P2);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Next;

   procedure Test_Next_2 is
      X : List (5);
      P1, P2 : Cursor;
   begin
      Set_Label ("Next 2: ");
      Create_Non_Empty_List (X);
      P1 := Next (X, First (X));
      P2 := P1;
      Delete (X, P1);
      begin
         Next (X, P2);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Next_2;

   procedure Test_Previous is
      X : List (5);
      P1, P2 : Cursor;
   begin
      Set_Label ("Previous: ");
      Create_Non_Empty_List (X);
      P1 := Previous (X, Last (X));
      P2 := P1;
      Delete (X, P1);
      begin
         P2 := Previous (X, P2);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Previous;

   procedure Test_Previous_2 is
      X : List (5);
      P1, P2 : Cursor;
   begin
      Set_Label ("Previous 2: ");
      Create_Non_Empty_List (X);
      P1 := Previous (X, Last (X));
      P2 := P1;
      Delete (X, P1);
      begin
         Previous (X, P2);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Previous_2;

   procedure Test_Find is
      X : List (5);
      P1, P2 : Cursor;
   begin
      Set_Label ("Find: ");
      Create_Non_Empty_List (X);
      P1 := Next (X, First (X));
      P2 := P1;
      Delete (X, P1);
      begin
         P2 := Find (X, 3, P2);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Find;

    procedure Test_Reverse_Find is
      X : List (5);
      P1, P2 : Cursor;
   begin
      Set_Label ("Reverse_Find: ");
      Create_Non_Empty_List (X);
      P1 := Next (X, First (X));
      P2 := P1;
      Delete (X, P1);
      begin
         P2 := Reverse_Find (X, 3, P2);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Reverse_Find;

   procedure Test_Merge is
      procedure Test_Merge_Full_Container is
         X : List (5);
         Y : List (9);
      begin
         Set_Label ("Merge with full container: ");
         Create_Non_Empty_List (X);
         Create_Non_Empty_List (Y);
         begin
            Sorting.Merge (Y, X);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Merge_Full_Container;

      procedure Test_Merge_Alias is
         X : List (10);
      begin
         Set_Label ("Merge with aliased parameters: ");
         Create_Non_Empty_List (X);
         begin
            Sorting.Merge (X, X);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Merge_Alias;

   begin
      Test_Merge_Full_Container;
      Test_Merge_Alias;
   end Test_Merge;

   procedure Test_Insert_Count_Overflow is
      X : List (5);
   begin
      Set_Label ("Insert with Count_Type'Last: ");
      Create_Non_Empty_List (X);
      begin
         Insert (X, First (X), 0, Count_Type'Last);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Insert_Count_Overflow;

begin
   Test_Append;
   Test_Append_2;
   Test_Assign;
   Test_Constant_Reference;
   Test_Copy;
   Test_Delete;
   Test_Element;
   Test_Find;
   Test_First_Element;
   Test_Insert;
   Test_Insert_2;
   Test_Insert_3;
   Test_Insert_4;
   Test_Last_Element;
   Test_Merge;
   Test_Move;
   Test_Next;
   Test_Next_2;
   Test_Prepend;
   Test_Prepend_2;
   Test_Previous;
   Test_Previous_2;
   Test_Reference;
   Test_Replace_Element;
   Test_Reverse_Find;
   Test_Splice;
   Test_Splice_2;
   Test_Splice_3;
   Test_Swap;
   Test_Swap_Links;
   Test_Insert_Count_Overflow;
   Check_Results;
end Test;
