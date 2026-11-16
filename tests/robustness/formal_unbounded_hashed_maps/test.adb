pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Hashed_Maps;
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

   function Witness (X : Natural) return Natural is (X mod 100);
   function Hash (X : Natural) return Hash_Type is (Hash_Type (X mod 10));
   function Eq (X, Y : Integer) return Boolean is ((X mod 100) = (Y mod 100));
   function Equivalent (X, Y : Natural) return Boolean is (Witness (X) = Witness (Y));
   package Int_Maps is new SPARK.Containers.Formal.Unbounded_Hashed_Maps (Natural, Integer, Hash, Equivalent, Eq);
   use Int_Maps;

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

  procedure Test_Key is
      procedure Test_Key_No_Element is
         X : Map;
         I : Integer;
      begin
         Set_Label ("Key with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            I := Key (X, No_Element);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Key_No_Element;

      procedure Test_Key_Deleted_Element is
         X : Map;
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
         X : Map;
         I : Integer;
      begin
         Set_Label ("Element with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            I := Element (X, No_Element);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_No_Element;

      procedure Test_Element_Deleted_Element is
         X : Map;
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
         X : Map;
      begin
         Set_Label ("Replace_Element with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            Replace_Element (X, No_Element, 6);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_No_Element;

      procedure Test_Replace_Element_Deleted_Element is
         X : Map;
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
         X : aliased Map;
         I : Integer;
      begin
         Set_Label ("Constant_Reference with No_Element: ");
         Create_Non_Empty_Map (X);
         begin
            declare
               I : constant Integer := Constant_Reference (X, No_Element).all;
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
         X : aliased Map;
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
         X : aliased Map;
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
         X : aliased Map;
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
      X : aliased Map;
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
      X : aliased Map;
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

--  procedure Test_Insert is
--        X : Map;
--        P : Cursor;
--        Inserted : Boolean;
--     begin
--        Set_Label ("Insert: ");
--        Create_Non_Empty_Map (X);
--        begin
--           Insert (X, 0, 0, P, Inserted);
--        exception
--           when Constraint_Error => return;
--           when others => null;
--        end;
--        Record_Failure;
--     end Test_Insert;

   procedure Test_Insert_2 is
      --  procedure Test_Insert_Full_Container is
      --     X : Map;
      --  begin
      --     Set_Label ("Insert 2 with container full: ");
      --     Create_Non_Empty_Map (X);
      --     begin
      --        Insert (X, 0, 0);
      --     exception
      --        when Constraint_Error => return;
      --        when others => null;
      --     end;
      --     Record_Failure;
      --  end Test_Insert_Full_Container;

      procedure Test_Insert_Already_Included is
         X : Map;
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
      --  Test_Insert_Full_Container;
      Test_Insert_Already_Included;
   end Test_Insert_2;

   --  procedure Test_Include is
   --     X : Map;
   --  begin
   --     Set_Label ("Include: ");
   --     Create_Non_Empty_Map (X);
   --     begin
   --        Insert (X, 0, 0);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Include;

  procedure Test_Replace is
      X : Map;
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
      X : Map;
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
         X : Map;
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
         X : Map;
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

   procedure Test_Next is
      X : Map;
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
      X : Map;
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

   procedure Test_Element_2 is
      X : Map;
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

begin
   Test_Constant_Reference;
   Test_Constant_Reference_2;
   Test_Delete;
   Test_Delete_2;
   Test_Element;
   Test_Element_2;
   --  Test_Include;
   --  Test_Insert;
   Test_Insert_2;
   Test_Key;
   Test_Next;
   Test_Next_2;
   Test_Reference;
   Test_Reference_2;
   Test_Replace;
   Test_Replace_Element;
   Check_Results;
end Test;
