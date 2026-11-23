pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Ordered_Sets;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

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

   package Int_Sets is new SPARK.Containers.Formal.Ordered_Sets (Integer);
   use Int_Sets;

   function Id (X : Integer) return Integer is (X);

   package Int_Keys is new Int_Sets.Generic_Keys (Integer, Id);

   --  Create a Set structure with 5 elements

   procedure Create_Non_Empty_Set (X : in out Set) with
     Pre  => X.Capacity >= 5,
     Post => Length (X) = 5
     and (for all E of X => E in 1 .. 5)
     and (for all E in 1 .. 5 => Contains (X, E)) is
   begin
      Clear (X);
      for I in 1 .. 5 loop
         Insert (X, I);
      end loop;
   end Create_Non_Empty_Set;

   procedure Test_Assign is
      X : Set (5);
      Y : Set (3);
   begin
      Set_Label ("Assign: ");
      Create_Non_Empty_Set (X);
      begin
         Assign (Y, X);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Assign;

   procedure Test_Constant_Reference is
      procedure Test_Constant_Reference_No_Element is
         X : aliased Set (5);
      begin
         Set_Label ("Constant_Reference: ");
         Create_Non_Empty_Set (X);
         begin
            declare
               I : constant Integer :=
                 Constant_Reference (X, Next (X, Last (X))).all;
            begin
               null;
            end;
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Constant_Reference_No_Element;

   begin
      Test_Constant_Reference_No_Element;
   end Test_Constant_Reference;

   procedure Test_Copy is
      X : Set (5);
   begin
      Set_Label ("Copy: ");
      Create_Non_Empty_Set (X);
      begin
         declare
            Y : constant Set := Copy (X, 4);
         begin
            null;
         end;
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Copy;

   procedure Test_Delete is
      procedure Test_Delete_No_Element is
         X : Set (5);
         P : Cursor := No_Element;
      begin
         Set_Label ("Delete: ");
         Create_Non_Empty_Set (X);
         begin
            Delete (X, P);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_No_Element;

   begin
      Test_Delete_No_Element;
   end Test_Delete;

   procedure Test_Delete_2 is
      X : Set (5);
   begin
      Set_Label ("Delete 2: ");
      Create_Non_Empty_Set (X);
      begin
         Delete (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Delete_2;

   procedure Test_Element is
      procedure Test_Element_No_Element is
         X : Set (5);
         I : Integer;
      begin
         Set_Label ("Element: ");
         Create_Non_Empty_Set (X);
         begin
            I := Element (X, Next (X, Last (X)));
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_No_Element;

   begin
      Test_Element_No_Element;
   end Test_Element;

   procedure Test_First_Element is
      X : Set (5);
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

   procedure Test_Insert is
      X : Set (5);
   begin
      Set_Label ("Insert with element already in set: ");
      Create_Non_Empty_Set (X);
      begin
         Insert (X, 3);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Insert;

   procedure Test_Last_Element is
      X : Set (5);
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

   procedure Test_Move is
      X : Set (5);
      Y : Set (3);
      procedure Test_Move_Same_Container is
         X : Set (5);
      begin
         Set_Label ("Move on same container: ");
         Create_Non_Empty_Set (X);
         Move (X, X);
         if Length (X) /= 5 or else not Contains (X, 1) then
            Record_Failure;
         end if;
      end Test_Move_Same_Container;

   begin
      Test_Move_Same_Container;
      Set_Label ("Move with full container: ");
      Create_Non_Empty_Set (X);
      begin
         Move (Y, X);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Move;

   procedure Test_Next is
      X : Set (5);
      P : Cursor;
   begin
      Set_Label ("Next with deleted element: ");
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      begin
         P := Next (X, P);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Next;

   procedure Test_Previous is
      X : Set (5);
      P : Cursor;
   begin
      Set_Label ("Previous with deleted element: ");
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      begin
         P := Previous (X, P);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Previous;

   procedure Test_Replace is
      X : Set (5);
   begin
      Set_Label ("Replace with element not in set: ");
      Create_Non_Empty_Set (X);
      begin
         Replace (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Replace;

   procedure Test_Replace_Element is
      procedure Test_Replace_Element_No_Element is
         X : Set (5);
      begin
         Set_Label ("Replace_Element with No_Element: ");
         Create_Non_Empty_Set (X);
         begin
            Replace_Element (X, Next (X, Last (X)), 6);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_No_Element;

      procedure Test_Replace_Element_Existing is
         X : Set (5);
      begin
         Set_Label ("Replace_Element with element already in set: ");
         Create_Non_Empty_Set (X);
         begin
            Replace_Element (X, Find (X, 1), 2);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_Existing;
   begin
      Test_Replace_Element_No_Element;
      Test_Replace_Element_Existing;
   end Test_Replace_Element;

   procedure Test_Keys_Delete is
      X : Set (5);
   begin
      Set_Label ("Generic_Keys.Delete with key not in set: ");
      Create_Non_Empty_Set (X);
      begin
         Int_Keys.Delete (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Keys_Delete;

   procedure Test_Keys_Element is
      X : Set (5);
      I : Integer;
   begin
      Set_Label ("Generic_Keys.Element with key not in set: ");
      Create_Non_Empty_Set (X);
      begin
         I := Int_Keys.Element (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Keys_Element;

   procedure Test_Keys_Key is
      X : Set (5);
      I : Integer;
   begin
      Set_Label ("Generic_Keys.Key with No_Element: ");
      Create_Non_Empty_Set (X);
      begin
         I := Int_Keys.Key (X, Next (X, Last (X)));
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Keys_Key;

   procedure Test_Keys_Replace is
      X : Set (5);
   begin
      Set_Label ("Generic_Keys.Replace with key not in set: ");
      Create_Non_Empty_Set (X);
      begin
         Int_Keys.Replace (X, 6, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Keys_Replace;

   procedure Test_Deleted_Cursors is
      X : aliased Set (5);
      P : Cursor;
      I : Integer;
   begin
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      Set_Label ("Constant_Reference with deleted cursor: ");
      begin
         I := Constant_Reference (X, P).all;
         Record_Failure;
      exception
         when Program_Error => null;
         when others => Record_Failure;
      end;
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      Set_Label ("Delete with deleted cursor: ");
      begin
         Delete (X, P);
         Record_Failure;
      exception
         when Program_Error => null;
         when others => Record_Failure;
      end;
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      Set_Label ("Element with deleted cursor: ");
      begin
         I := Element (X, P);
         Record_Failure;
      exception
         when Program_Error => null;
         when others => Record_Failure;
      end;
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      Set_Label ("Generic_Keys.Key with deleted cursor: ");
      begin
         I := Int_Keys.Key (X, P);
         Record_Failure;
      exception
         when Program_Error => null;
         when others => Record_Failure;
      end;
      Create_Non_Empty_Set (X);
      P := Find (X, 3);
      Delete (X, 3);
      Set_Label ("Replace_Element with deleted cursor: ");
      begin
         Replace_Element (X, P, 6);
         Record_Failure;
      exception
         when Program_Error => null;
         when others => Record_Failure;
      end;
   end Test_Deleted_Cursors;

begin
   Test_Assign;
   Test_Constant_Reference;
   Test_Deleted_Cursors;
   Test_Copy;
   Test_Delete;
   Test_Delete_2;
   Test_Element;
   Test_First_Element;
   Test_Insert;
   Test_Keys_Delete;
   Test_Keys_Element;
   Test_Keys_Key;
   Test_Keys_Replace;
   Test_Last_Element;
   Test_Move;
   Test_Next;
   Test_Previous;
   Test_Replace;
   Test_Replace_Element;
   Check_Results;
end Test;
