pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Ordered_Maps;
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

      function Lt (X, Y : Integer) return Boolean is
      (X mod 100 < Y mod 100);

   function Eq (X, Y : Integer) return Boolean is
      (X mod 100 = Y mod 100);

   package Int_Maps is new SPARK.Containers.Formal.Ordered_Maps (Integer, Integer, Lt, Eq);
   use Int_Maps;

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

   procedure Test_Key is
      procedure Test_Key_No_Element is
         X : Map (5);
         I : Integer;
      begin
         Set_Label ("Key with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            I := Key (X, Next (X, Last (X)));
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Key_No_Element;

      procedure Test_Key_Deleted_Element is
         X : Map (5);
         I : Integer;
         P : Cursor;
      begin
         Set_Label ("Key with deleted Element: ");
         Create_Non_Empty_Map (X);
         P := Find (X, 3);
         Delete (X, 3);
         begin
            I := Key (X, P);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Key_Deleted_Element;
   begin
      Test_Key_No_Element;
      Test_Key_Deleted_Element;
   end Test_Key;

   procedure Test_Element is
      procedure Test_Element_No_Element is
         X : Map (5);
         I : Integer;
      begin
         Set_Label ("Element with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            I := Element (X, Next (X, Last (X)));
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_No_Element;

      procedure Test_Element_Deleted_Element is
         X : Map (5);
         I : Integer;
         P : Cursor;
      begin
         Set_Label ("Element with deleted Element: ");
         Create_Non_Empty_Map (X);
         P := Find (X, 3);
         Delete (X, 3);
         begin
            I := Element (X, P);
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
         X : Map (5);
      begin
         Set_Label ("Replace_Element with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            Replace_Element (X, Next (X, Last (X)), 6);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_No_Element;

      procedure Test_Replace_Element_Deleted_Element is
         X : Map (5);
         P : Cursor;
      begin
         Set_Label ("Replace_Element with deleted Element: ");
         Create_Non_Empty_Map (X);
         P := Find (X, 3);
         Delete (X, 3);
         begin
            Replace_Element (X, P, 1003);
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
         X : aliased Map (5);
         I : Integer;
      begin
         Set_Label ("Constant_Reference with No_Element: ");
         Create_Non_Empty_Map (X);
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
         X : aliased Map (5);
         I : Integer;
         P : Cursor;
      begin
         Set_Label ("Constant_Reference with deleted Element: ");
         Create_Non_Empty_Map (X);
         P := Find (X, 3);
         Delete (X, 3);
         begin
            declare
               I : constant Integer := Constant_Reference (X, P).all;
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
         X : aliased Map (5);
         I : Integer;
      begin
         Set_Label ("Reference with No_Element: ");
         Create_Non_Empty_Map (X);
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
         X : aliased Map (5);
         I : Integer;
         P : Cursor;
      begin
         Set_Label ("Reference with deleted Element: ");
         Create_Non_Empty_Map (X);
         P := Find (X, 3);
         Delete (X, 3);
         begin
            declare
               I : constant Integer := Reference (X, P).all;
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

   procedure Test_Constant_Reference_2 is
      X : aliased Map (10);
   begin
      Set_Label ("Constant_Reference: ");
      Create_Non_Empty_Map (X);
      begin
         declare
            I : constant Integer := Constant_Reference (X, 6).all;
         begin
            null;
         end;
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Constant_Reference_2;

   procedure Test_Reference_2 is
      X : aliased Map (10);
   begin
      Set_Label ("Reference: ");
      Create_Non_Empty_Map (X);
      begin
         declare
            I : constant Integer := Reference (X, 6).all;
         begin
            null;
         end;
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Reference_2;

   procedure Test_Assign is
      X : Map (10);
      Y : Map (4);
   begin
      Set_Label ("Assign: ");
      Create_Non_Empty_Map (X);
      begin
         Assign (Y, X);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Assign;

   procedure Test_Move is
      procedure Test_Move_Full_Container is
         X : Map (5);
         Y : Map (4);
      begin
         Set_Label ("Move with full container: ");
         Create_Non_Empty_Map (X);
         begin
            Move (Y, X);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Move_Full_Container;

      procedure Test_Move_Same_Container is
         X : Map (5);
      begin
         Set_Label ("Move on same container: ");
         Create_Non_Empty_Map (X);
         Move (X, X);
         if Length (X) /= 5 or else not Contains (X, 1) or else Element (X, 1) /= 1 then
            Record_Failure;
         end if;
      end Test_Move_Same_Container;

   begin
      Test_Move_Same_Container;
      Test_Move_Full_Container;
   end Test_Move;

procedure Test_Insert is
      X : Map (5);
      P : Cursor;
      Inserted : Boolean;
   begin
      Set_Label ("Insert: ");
      Create_Non_Empty_Map (X);
      begin
         Insert (X, 0, 0, P, Inserted);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Insert;

   procedure Test_Insert_2 is
      procedure Test_Insert_Full_Container is
         X : Map (5);
      begin
         Set_Label ("Insert 2 with container full: ");
         Create_Non_Empty_Map (X);
         begin
            Insert (X, 0, 0);
         exception
            when Capacity_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Full_Container;

      procedure Test_Insert_Already_Included is
         X : Map (10);
      begin
         Set_Label ("Insert 2 with key already contained: ");
         Create_Non_Empty_Map (X);
         begin
            Insert (X, 3, 3);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Already_Included;
   begin
      Test_Insert_Full_Container;
      Test_Insert_Already_Included;
   end Test_Insert_2;

   procedure Test_Include is
      X : Map (5);
   begin
      Set_Label ("Include: ");
      Create_Non_Empty_Map (X);
      begin
         Insert (X, 0, 0);
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Include;

  procedure Test_Replace is
      X : Map (5);
   begin
      Set_Label ("Replace: ");
      Create_Non_Empty_Map (X);
      begin
         Replace (X, 6, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Replace;

   procedure Test_Delete is
      X : Map (5);
   begin
      Set_Label ("Delete: ");
      Create_Non_Empty_Map (X);
      begin
         Delete (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Delete;

   procedure Test_Delete_2 is
      procedure Test_Delete_No_Element is
         X : Map (5);
         P : Cursor := No_Element;
      begin
         Set_Label ("Delete 2 with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            Delete (X, P);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_No_Element;

      procedure Test_Delete_Deleted_Element is
         X : Map (5);
         P : Cursor;
      begin
         Set_Label ("Delete 2 with deleted Element: ");
         Create_Non_Empty_Map (X);
         P := Find (X, 3);
         Delete (X, 3);
         begin
            Delete (X, P);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Deleted_Element;
   begin
      Test_Delete_No_Element;
      Test_Delete_Deleted_Element;
   end Test_Delete_2;

   procedure Test_First_Element is
      X : Map (5);
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

   procedure Test_First_Key is
      X : Map (5);
      K : Integer;
   begin
      Set_Label ("First_Key: ");
      begin
         K := First_Key (X);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_First_Key;

   procedure Test_Last_Element is
      X : Map (5);
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

   procedure Test_Last_Key is
      X : Map (5);
      K : Integer;
   begin
      Set_Label ("Last_Key: ");
      begin
         K := Last_Key (X);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Last_Key;

   procedure Test_Next is
      X : Map (5);
      P : Cursor;
   begin
      Set_Label ("Next: ");
      Create_Non_Empty_Map (X);
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

   procedure Test_Next_2 is
      X : Map (5);
      P : Cursor;
   begin
      Set_Label ("Next_2: ");
      Create_Non_Empty_Map (X);
      P := Find (X, 3);
      Delete (X, 3);
      begin
         Next (X, P);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Next_2;

   procedure Test_Previous is
      X : Map (5);
      P : Cursor;
   begin
      Set_Label ("Previous: ");
      Create_Non_Empty_Map (X);
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

   procedure Test_Previous_2 is
      X : Map (5);
      P : Cursor;
   begin
      Set_Label ("Previous_2: ");
      Create_Non_Empty_Map (X);
      P := Find (X, 3);
      Delete (X, 3);
      begin
         Previous (X, P);
      exception
         when Program_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Previous_2;

   procedure Test_Element_2 is
      X : Map (5);
      I : Integer;
   begin
      Set_Label ("Element 2: ");
      Create_Non_Empty_Map (X);
      begin
         I := Element (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Element_2;

   procedure Test_Copy is
      X : Map (5);
   begin
      Set_Label ("Copy: ");
      Create_Non_Empty_Map (X);
      begin
         declare
            Y : Map := Copy (X, 4);
         begin
            null;
         end;
      exception
         when Capacity_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Copy;

begin
   Test_Assign;
   Test_Constant_Reference;
   Test_Constant_Reference_2;
   Test_Copy;
   Test_Delete;
   Test_Delete_2;
   Test_Element;
   Test_Element_2;
   Test_First_Element;
   Test_First_Key;
   Test_Include;
   Test_Insert;
   Test_Insert_2;
   Test_Key;
   Test_Last_Element;
   Test_Last_Key;
   Test_Move;
   Test_Next;
   Test_Next_2;
   Test_Previous;
   Test_Previous_2;
   Test_Reference;
   Test_Reference_2;
   Test_Replace;
   Test_Replace_Element;
   Check_Results;
end Test;
