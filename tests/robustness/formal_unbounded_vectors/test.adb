pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Unbounded_Vectors;
with Ada.Containers;
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

   type Index_Type is range 1 .. 100;
   function Eq (X, Y : Integer) return Boolean is (X mod 100 = Y mod 100);
   function Lt (X, Y : Integer) return Boolean is (X mod 100 < Y mod 100);
   package Int_Vectors is new SPARK.Containers.Formal.Unbounded_Vectors
     (Index_Type, Integer, "=" => Eq);
   package Sorting is new Int_Vectors.Generic_Sorting (Lt);
   use Int_Vectors;

   --  Create Vector structure with 5 elements

   procedure Create_Non_Empty_Vector (X : in out Vector; C : Integer := 5) is
   begin
      for I in 1 .. C loop
         Append (X, I);
      end loop;
   end Create_Non_Empty_Vector;

   procedure Test_Element is
      procedure Test_Out_Of_Range is
         X : Vector;
         I : Integer;
      begin
         Set_Label ("Element: ");
         Create_Non_Empty_Vector (X);
         begin
            I := Element (X, 6);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Out_Of_Range;

      procedure Test_Empty is
         X : Vector;
         I : Integer;
      begin
         Set_Label ("Element on empty vector: ");
         begin
            I := Element (X, 1);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Empty;
   begin
      Test_Out_Of_Range;
      Test_Empty;
   end Test_Element;

   procedure Test_Replace_Element is
      X : Vector;
   begin
      Set_Label ("Replace_Element: ");
      Create_Non_Empty_Vector (X);
      begin
         Replace_Element (X, 6, 1);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Replace_Element;

   procedure Test_Constant_Reference is
      X : aliased Vector;
   begin
      Set_Label ("Constant_Reference: ");
      Create_Non_Empty_Vector (X);
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
   end Test_Constant_Reference;

   procedure Test_Reference is
      X : aliased Vector;
   begin
      Set_Label ("Reference: ");
      Create_Non_Empty_Vector (X);
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
   end Test_Reference;

   procedure Test_Insert_Vector is
      procedure Test_Insert_Vector_Full_Container is
         X : Vector;
         Y : Vector;
      begin
         Set_Label ("Insert_Vector with container full: ");
         Create_Non_Empty_Vector (X, 51);
         Create_Non_Empty_Vector (Y, 50);
         begin
            Insert_Vector (X, 1, Y);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Vector_Full_Container;

      procedure Test_Insert_Vector_Before_No_Element is
         X : Vector;
         Y : Vector;
      begin
         Set_Label ("Insert_Vector with Before not in range: ");
         Create_Non_Empty_Vector (X);
         Create_Non_Empty_Vector (Y);
         begin
            Insert_Vector (X, 7, Y);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Vector_Before_No_Element;

      procedure Test_Insert_Vector_Alias is
         X : Vector;
      begin
         Set_Label ("Insert_Vector with container full: ");
         Create_Non_Empty_Vector (X);
         begin
            Insert_Vector (X, 1, X);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Vector_Alias;
   begin
      Test_Insert_Vector_Full_Container;
      Test_Insert_Vector_Before_No_Element;
      Test_Insert_Vector_Alias;
   end Test_Insert_Vector;

   procedure Test_Insert is
      procedure Test_Insert_Full_Container is
         X : Vector;
      begin
         Set_Label ("Insert with container full: ");
         Create_Non_Empty_Vector (X, 100);
         begin
            Insert (X, 1, 0);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Full_Container;

      procedure Test_Insert_Before_No_Element is
         X : Vector;
      begin
         Set_Label ("Insert with Before not in range: ");
         Create_Non_Empty_Vector (X);
         begin
            Insert (X, 7, 0);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Before_No_Element;
   begin
      Test_Insert_Full_Container;
      Test_Insert_Before_No_Element;
   end Test_Insert;

   procedure Test_Insert_2 is
      procedure Test_Insert_2_Full_Container is
         X : Vector;
      begin
         Set_Label ("Insert 2 with container full: ");
         Create_Non_Empty_Vector (X, 100);
         begin
            Insert (X, 1, 0, 1);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_2_Full_Container;

      procedure Test_Insert_2_Count is
         X : Vector;
      begin
         Set_Label ("Insert 2 with count: ");
         Create_Non_Empty_Vector (X);
         begin
            Insert (X, 1, 0, 100);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_2_Count;

      procedure Test_Insert_2_Before_No_Element is
         X : Vector;
      begin
         Set_Label ("Insert 2 with Before not in range: ");
         Create_Non_Empty_Vector (X);
         begin
            Insert (X, 0, 0, 1);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_2_Before_No_Element;
   begin
      Test_Insert_2_Full_Container;
      Test_Insert_2_Count;
      Test_Insert_2_Before_No_Element;
   end Test_Insert_2;

   procedure Test_Prepend_Vector is
      procedure Test_Prepend_Vector_Full_Container is
         X : Vector;
         Y : Vector;
      begin
         Set_Label ("Prepend_Vector with container full:");
         Create_Non_Empty_Vector (X, 51);
         Create_Non_Empty_Vector (Y, 50);
         begin
            Prepend_Vector (X, Y);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Prepend_Vector_Full_Container;

      procedure Test_Prepend_Vector_Alias is
         X : Vector;
      begin
         Set_Label ("Prepend_Vector with aliased parameters: ");
         Create_Non_Empty_Vector (X);
         begin
            Prepend_Vector (X, X);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Prepend_Vector_Alias;
   begin
      Test_Prepend_Vector_Full_Container;
      Test_Prepend_Vector_Alias;
   end Test_Prepend_Vector;

   procedure Test_Prepend is
      X : Vector;
   begin
      Set_Label ("Prepend: ");
      Create_Non_Empty_Vector (X, 100);
      begin
         Prepend (X, 0);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Prepend;

   procedure Test_Prepend_2 is
      X : Vector;
   begin
      Set_Label ("Prepend 2: ");
      Create_Non_Empty_Vector (X);
      Delete_Last (X);
      begin
         Prepend (X, 6, 100);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Prepend_2;

   procedure Test_Append_Vector is
      procedure Test_Append_Vector_Full_Container is
         X : Vector;
         Y : Vector;
      begin
         Set_Label ("Append_Vector with container full:");
         Create_Non_Empty_Vector (X, 51);
         Create_Non_Empty_Vector (Y, 50);
         begin
            Append_Vector (X, Y);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Append_Vector_Full_Container;

      procedure Test_Append_Vector_Alias is
         X : Vector;
      begin
         Set_Label ("Append_Vector with aliased parameters: ");
         Create_Non_Empty_Vector (X);
         begin
            Append_Vector (X, X);
         exception
            when Program_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Append_Vector_Alias;
   begin
      Test_Append_Vector_Full_Container;
      Test_Append_Vector_Alias;
   end Test_Append_Vector;

   procedure Test_Append is
      X : Vector;
   begin
      Set_Label ("Append: ");
      Create_Non_Empty_Vector (X, 100);
      begin
         Append (X, 6);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Append;

   procedure Test_Append_2 is
      X : Vector;
   begin
      Set_Label ("Append 2: ");
      Create_Non_Empty_Vector (X);
      Delete_Last (X);
      begin
         Append (X, 6, 100);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Append_2;

   procedure Test_Delete is
      procedure Test_Delete_Too_Large is
         X : Vector;
      begin
         Set_Label ("Delete with index too large: ");
         Create_Non_Empty_Vector (X);
         begin
            Delete (X, 7);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Too_Large;

      procedure Test_Delete_Too_Small is
         X : Vector;
      begin
         Set_Label ("Delete with index too small: ");
         Create_Non_Empty_Vector (X);
         begin
            Delete (X, 0);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Delete_Too_Small;

   begin
      Test_Delete_Too_Large;
      Test_Delete_Too_Small;
   end Test_Delete;

   procedure Test_Delete_2 is
      X : Vector;
      procedure Test_Delete_After_Last is
         X : Vector;
      begin
         Set_Label ("Delete immediately after last index: ");
         Create_Non_Empty_Vector (X);
         Delete (X, 6, 2);
         if Length (X) /= 5 or else Element (X, 5) /= 5 then
            Record_Failure;
         end if;
      end Test_Delete_After_Last;

   begin
      Test_Delete_After_Last;
      Set_Label ("Delete 2: ");
      Create_Non_Empty_Vector (X);
      begin
         Delete (X, 7, 2);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Delete_2;

   procedure Test_Swap is
      procedure Test_Swap_I_Not_Contained is
         X : Vector;
      begin
         Set_Label ("Swap with not Has_Element (I): ");
         Create_Non_Empty_Vector (X);
         begin
            Swap (X, 7, 3);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_I_Not_Contained;

      procedure Test_Swap_J_Not_Contained is
         X : Vector;
      begin
         Set_Label ("Swap with not Has_Element (J): ");
         Create_Non_Empty_Vector (X);
         begin
            Swap (X, 3, 6);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Swap_J_Not_Contained;
   begin
      Test_Swap_I_Not_Contained;
      Test_Swap_J_Not_Contained;
   end Test_Swap;

   procedure Test_First_Element is
      X : Vector;
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
      X : Vector;
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

   procedure Test_Merge is
      procedure Test_Merge_Full_Container is
         X : Vector;
         Y : Vector;
      begin
         Set_Label ("Merge with full container: ");
         Create_Non_Empty_Vector (X, 51);
         Create_Non_Empty_Vector (Y, 50);
         begin
            Sorting.Merge (Y, X);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Merge_Full_Container;

      procedure Test_Merge_Alias is
         X : Vector;
      begin
         Set_Label ("Merge with aliased parameters: ");
         Create_Non_Empty_Vector (X);
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

   procedure Test_Defensive_Limits is
      procedure Test_Append_Vector_At_Last_Index is
         X, Y : Vector;
      begin
         Set_Label ("Append_Vector at maximum index: ");
         Create_Non_Empty_Vector (X, 100);
         Append (Y, 0);
         begin
            Append_Vector (X, Y);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Append_Vector_At_Last_Index;

      procedure Test_Insert_Count_Overflow is
         X : Vector;
      begin
         Set_Label ("Insert with Count_Type'Last: ");
         Append (X, 0);
         begin
            Insert (X, 1, 0, Ada.Containers.Count_Type'Last);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Count_Overflow;
   begin
      Test_Append_Vector_At_Last_Index;
      Test_Insert_Count_Overflow;
   end Test_Defensive_Limits;

   procedure Test_Move is
      procedure Test_Move_Same_Container is
         X : Vector;
      begin
         Set_Label ("Move on same container: ");
         Create_Non_Empty_Vector (X);
         Move (X, X);
         if Length (X) /= 5 or else Element (X, 1) /= 1 or else Element (X, 5) /= 5 then
            Record_Failure;
         end if;
      end Test_Move_Same_Container;
   begin
      Test_Move_Same_Container;
   end Test_Move;

begin
   Test_Append;
   Test_Append_2;
   Test_Append_Vector;
   Test_Constant_Reference;
   Test_Delete;
   Test_Delete_2;
   Test_Element;
   Test_First_Element;
   Test_Insert;
   Test_Insert_2;
   Test_Insert_Vector;
   Test_Last_Element;
   Test_Merge;
   Test_Prepend;
   Test_Prepend_2;
   Test_Prepend_Vector;
   Test_Reference;
   Test_Replace_Element;
   Test_Swap;
   Test_Defensive_Limits;
   Test_Move;
   Check_Results;
end Test;
