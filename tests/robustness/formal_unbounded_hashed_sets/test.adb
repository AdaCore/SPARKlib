pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Hashed_Sets;
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
   package Int_Sets is new SPARK.Containers.Formal.Unbounded_Hashed_Sets (Natural, Hash, Equivalent, Eq);
   use Int_Sets;

   subtype Key_Type is Natural range 0 .. 99;
   function Hash_Key (X : Key_Type) return Hash_Type is (Hash_Type (X mod 100));
   package Int_Sets_Keys is new Int_Sets.Generic_Keys (Key_Type, Witness, Hash_Key, "=");

   procedure Create_Non_Empty_Set (X : in out Set) is
   begin
      for I in 1 .. 5 loop
         Insert (X, I);
      end loop;
   end Create_Non_Empty_Set;

   procedure Test_Element is
      procedure Test_Element_No_Element is
         X : Set;
         I : Integer;
      begin
         Set_Label ("Element with No_Element: ");
         Create_Non_Empty_Set (X);
         begin
            I := Element (X, No_Element);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_No_Element;

      procedure Test_Element_Deleted_Element is
         X : Set;
         I : Integer;
         P : Cursor;
      begin
         Set_Label ("Element with deleted Element: ");
         Create_Non_Empty_Set (X);
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
         X : Set;
      begin
         Set_Label ("Replace_Element with No_Element: ");
         Create_Non_Empty_Set (X);
         begin
            Replace_Element (X, No_Element, 6);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Element_No_Element;

      procedure Test_Replace_Element_Deleted_Element is
         X : Set;
         P : Cursor;
      begin
         Set_Label ("Replace_Element with deleted Element: ");
         Create_Non_Empty_Set (X);
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
      procedure Test_Replace_Element_Existing is
         X : Set;
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
      Test_Replace_Element_Deleted_Element;
      Test_Replace_Element_Existing;
   end Test_Replace_Element;

   procedure Test_Constant_Reference is
      procedure Test_Constant_Reference_No_Element is
         X : aliased Set;
      begin
         Set_Label ("Constant_Reference with No_Element: ");
         Create_Non_Empty_Set (X);
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
         X : aliased Set;
         P : Cursor;
      begin
         Set_Label ("Constant_Reference with deleted Element: ");
         Create_Non_Empty_Set (X);
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

   --  procedure Test_Insert is
   --     X : Set;
   --     P : Cursor;
   --     Inserted : Boolean;
   --  begin
   --     Set_Label ("Insert: ");
   --     Create_Non_Empty_Set (X);
   --     begin
   --        Insert (X, 0, P, Inserted);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Insert;

   procedure Test_Insert_2 is
      --  procedure Test_Insert_Full_Container is
      --     X : Set;
      --  begin
      --     Set_Label ("Insert 2 with container full: ");
      --     Create_Non_Empty_Set (X);
      --     begin
      --        Insert (X, 0);
      --     exception
      --        when Constraint_Error => return;
      --        when others => null;
      --     end;
      --     Record_Failure;
      --  end Test_Insert_Full_Container;

      procedure Test_Insert_Already_Included is
         X : Set;
      begin
         Set_Label ("Insert 2 with key already contained: ");
         Create_Non_Empty_Set (X);
         begin
            Insert (X, 3);
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
   --     X : Set;
   --  begin
   --     Set_Label ("Include: ");
   --     Create_Non_Empty_Set (X);
   --     begin
   --        Insert (X, 0);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Include;

  procedure Test_Replace is
      X : Set;
   begin
      Set_Label ("Replace: ");
      Create_Non_Empty_Set (X);
      begin
         Replace (X, 1006);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Replace;

   procedure Test_Delete is
      X : Set;
   begin
      Set_Label ("Delete: ");
      Create_Non_Empty_Set (X);
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
         X : Set;
         P : Cursor := No_Element;
      begin
         Set_Label ("Delete 2 with No_Element: ");
         Create_Non_Empty_Set (X);
         begin
            Delete (X, P);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_No_Element;

      procedure Test_Delete_Deleted_Element is
         X : Set;
         P : Cursor;
      begin
         Set_Label ("Delete 2 with deleted Element: ");
         Create_Non_Empty_Set (X);
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

   --  procedure Test_Union is
   --     X, Y, Z: Set;
   --  begin
   --     Set_Label ("Union: ");
   --     Create_Non_Empty_Set (X);
   --     Create_Non_Empty_Set (Y);
   --     begin
   --        Z := Union (X, Y);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Union;

   --  procedure Test_Union_2 is
   --     X : Set;
   --     Y : Set;
   --  begin
   --     Set_Label ("Union 2: ");
   --     Create_Non_Empty_Set (X);
   --     begin
   --        Union (Y, X);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Union_2;

   --  procedure Test_Symmetric_Difference is
   --     X, Y, Z : Set;
   --  begin
   --     Set_Label ("Symmetric_Difference: ");
   --     Create_Non_Empty_Set (X);
   --     Create_Non_Empty_Set (Y);
   --     begin
   --        Z := Symmetric_Difference (X, Y);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Symmetric_Difference;

   --  procedure Test_Symmetric_Difference_2 is
   --     X : Set;
   --     Y : Set;
   --  begin
   --     Set_Label ("Symmetric_Difference 2: ");
   --     Create_Non_Empty_Set (X);
   --     begin
   --        Symmetric_Difference (Y, X);
   --     exception
   --        when Constraint_Error => return;
   --        when others => null;
   --     end;
   --     Record_Failure;
   --  end Test_Symmetric_Difference_2;

   procedure Test_Next is
      X : Set;
      P : Cursor;
   begin
      Set_Label ("Next: ");
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

   procedure Test_Next_2 is
      X : Set;
      P : Cursor;
   begin
      Set_Label ("Next_2: ");
      Create_Non_Empty_Set (X);
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

   procedure Test_Generic_Keys is

      procedure Test_Key is
         procedure Test_Key_No_Element is
            X : Set;
            K : Key_Type;
         begin
            Set_Label ("Key with No_Element: ");
            Create_Non_Empty_Set (X);
            begin
               K := Int_Sets_Keys.Key (X, No_Element);
            exception
               when Constraint_Error => return;
               when others => null;
            end;
            Record_Failure;
         end Test_Key_No_Element;

         procedure Test_Key_Deleted_Element is
            X : Set;
            K : Key_Type;
            P : Cursor;
         begin
            Set_Label ("Key with deleted Element: ");
            Create_Non_Empty_Set (X);
            P := Find (X, 3);
            Delete (X, 3);
            begin
               K := Int_Sets_Keys.Key (X, P);
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

      procedure Test_Replace_Key is
         X : Set;
         K : Key_Type;
      begin
         Set_Label ("Generic_Keys.Replace: ");
         Create_Non_Empty_Set (X);
         K := Int_Sets_Keys.Key (X, Find (X, 3));
         Delete (X, 3);
         begin
            Int_Sets_Keys.Replace (X, K, 103);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Replace_Key;

      procedure Test_Delete_Key is
         X : Set;
         K : Key_Type;
      begin
         Set_Label ("Generic_Keys.Delete: ");
         Create_Non_Empty_Set (X);
         K := Int_Sets_Keys.Key (X, Find (X, 3));
         Delete (X, 3);
         begin
            Int_Sets_Keys.Delete (X, K);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Key;

      procedure Test_Element_Key is
         X : Set;
         K : Key_Type;
         E : Natural;
      begin
         Set_Label ("Generic_Keys.Element: ");
         Create_Non_Empty_Set (X);
         K := Int_Sets_Keys.Key (X, Find (X, 3));
         Delete (X, 3);
         begin
            E := Int_Sets_Keys.Element (X, K);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Element_Key;

   begin
      Test_Delete_Key;
      Test_Element_Key;
      Test_Key;
      Test_Replace_Key;
   end Test_Generic_Keys;

begin
   Test_Constant_Reference;
   Test_Delete;
   Test_Delete_2;
   Test_Element;
   Test_Generic_Keys;
   --  Test_Include;
   --  Test_Insert;
   Test_Insert_2;
   Test_Next;
   Test_Next_2;
   Test_Replace;
   Test_Replace_Element;
   --  Test_Symmetric_Difference;
   --  Test_Symmetric_Difference_2;
   --  Test_Union;
   --  Test_Union_2;
   Check_Results;
end Test;
