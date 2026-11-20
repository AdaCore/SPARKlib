pragma Check_Policy (SPARKlib_Defensive => Disable);

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Trees;
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

   type Way_Type is (Left, Right);

   package Int_Trees is new SPARK.Containers.Formal.Trees (Way_Type, Integer);
   use Int_Trees;

   --  Create a Tree structure with 3 nodes: a root and its two children

   procedure Create_Non_Empty_Tree (X : in out Tree) with
     Pre  => X.Capacity >= 3,
     Post => Node_Count (X) = 3 is
   begin
      Clear (X);
      Insert_Root (X, 1);
      Insert_Child (X, 2, Root (X), Left);
      Insert_Child (X, 3, Root (X), Right);
   end Create_Non_Empty_Tree;

   procedure Test_Assign is
      X : Tree (5);
      Y : Tree (2);
   begin
      Set_Label ("Assign: ");
      Create_Non_Empty_Tree (X);
      begin
         Assign (Y, X);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Assign;

   procedure Test_Child is
      X : Tree (5);
      P : Cursor;
   begin
      Set_Label ("Child: ");
      Create_Non_Empty_Tree (X);
      begin
         P := Child (X, No_Element, Left);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Child;

   procedure Test_Constant_Reference is
      X : aliased Tree (5);
   begin
      Set_Label ("Constant_Reference: ");
      Create_Non_Empty_Tree (X);
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
   end Test_Constant_Reference;

   procedure Test_Copy is
      X : Tree (5);
   begin
      Set_Label ("Copy: ");
      Create_Non_Empty_Tree (X);
      begin
         declare
            Y : constant Tree := Copy (X, 4);
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
      X : Tree (5);
   begin
      Set_Label ("Delete: ");
      Create_Non_Empty_Tree (X);
      begin
         Delete (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Delete;

   procedure Test_Depth is
      X : Tree (5);
      N : Count_Type;
   begin
      Set_Label ("Depth: ");
      Create_Non_Empty_Tree (X);
      begin
         N := Depth (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Depth;

   procedure Test_Direction is
      X : Tree (5);
      W : Way_Type;
   begin
      Set_Label ("Direction: ");
      Create_Non_Empty_Tree (X);
      begin
         W := Direction (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Direction;

   procedure Test_Element is
      X : Tree (5);
      I : Integer;
   begin
      Set_Label ("Element: ");
      Create_Non_Empty_Tree (X);
      begin
         I := Element (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Element;

   procedure Test_First_Child is
      X : Tree (5);
      P : Cursor;
   begin
      Set_Label ("First_Child: ");
      Create_Non_Empty_Tree (X);
      begin
         P := First_Child (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_First_Child;

   procedure Test_Has_Child is
      X : Tree (5);
      B : Boolean;
   begin
      Set_Label ("Has_Child: ");
      Create_Non_Empty_Tree (X);
      begin
         B := Has_Child (X, No_Element, Left);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Has_Child;

   procedure Test_In_Subtree is
      X : Tree (5);
      B : Boolean;
   begin
      Set_Label ("In_Subtree: ");
      Create_Non_Empty_Tree (X);
      begin
         B := In_Subtree (X, No_Element, Root (X));
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_In_Subtree;

   procedure Test_Insert_Child is
      procedure Test_Insert_Child_Occupied_Way is
         X : Tree (5);
      begin
         Set_Label ("Insert_Child with an occupied Way: ");
         Create_Non_Empty_Tree (X);
         begin
            Insert_Child (X, 4, Root (X), Left);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Child_Occupied_Way;

      procedure Test_Insert_Child_Full_Container is
         X : Tree (3);
      begin
         Set_Label ("Insert_Child with a full container: ");
         Create_Non_Empty_Tree (X);
         begin
            Insert_Child (X, 4, First_Child (X, Root (X)), Left);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Child_Full_Container;
   begin
      Test_Insert_Child_Occupied_Way;
      Test_Insert_Child_Full_Container;
   end Test_Insert_Child;

   procedure Test_Insert_Parent is
      procedure Test_Insert_Parent_No_Element is
         X : Tree (5);
      begin
         Set_Label ("Insert_Parent with No_Element: ");
         Create_Non_Empty_Tree (X);
         begin
            Insert_Parent (X, 4, No_Element, Left);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Parent_No_Element;

      procedure Test_Insert_Parent_Full_Container is
         X : Tree (3);
      begin
         Set_Label ("Insert_Parent with a full container: ");
         Create_Non_Empty_Tree (X);
         begin
            Insert_Parent (X, 4, Root (X), Left);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Insert_Parent_Full_Container;
   begin
      Test_Insert_Parent_No_Element;
      Test_Insert_Parent_Full_Container;
   end Test_Insert_Parent;

   procedure Test_Is_Ancestor_Of is
      procedure Test_Is_Ancestor_Of_Parent is
         X : Tree (5);
         B : Boolean;
      begin
         Set_Label ("Is_Ancestor_Of with Parent = No_Element: ");
         Create_Non_Empty_Tree (X);
         begin
            B := Is_Ancestor_Of (X, No_Element, Root (X));
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Is_Ancestor_Of_Parent;

      procedure Test_Is_Ancestor_Of_Position is
         X : Tree (5);
         B : Boolean;
      begin
         Set_Label ("Is_Ancestor_Of with Position = No_Element: ");
         Create_Non_Empty_Tree (X);
         begin
            B := Is_Ancestor_Of (X, Root (X), No_Element);
         exception
            when Constraint_Error => return;
            when others => null;
         end;
         Record_Failure;
      end Test_Is_Ancestor_Of_Position;
   begin
      Test_Is_Ancestor_Of_Parent;
      Test_Is_Ancestor_Of_Position;
   end Test_Is_Ancestor_Of;

   procedure Test_Is_Leaf is
      X : Tree (5);
      B : Boolean;
   begin
      Set_Label ("Is_Leaf: ");
      Create_Non_Empty_Tree (X);
      begin
         B := Is_Leaf (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Is_Leaf;

   procedure Test_Last_Child is
      X : Tree (5);
      P : Cursor;
   begin
      Set_Label ("Last_Child: ");
      Create_Non_Empty_Tree (X);
      begin
         P := Last_Child (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Last_Child;

   procedure Test_Next_Sibling is
      X : Tree (5);
      P : Cursor;
   begin
      Set_Label ("Next_Sibling: ");
      Create_Non_Empty_Tree (X);
      begin
         P := Next_Sibling (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Next_Sibling;

   procedure Test_Node_Count is
      X : Tree (5);
      N : Count_Type;
   begin
      Set_Label ("Node_Count: ");
      Create_Non_Empty_Tree (X);
      begin
         N := Node_Count (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Node_Count;

   procedure Test_Parent is
      X : Tree (5);
      P : Cursor;
   begin
      Set_Label ("Parent: ");
      Create_Non_Empty_Tree (X);
      begin
         P := Parent (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Parent;

   procedure Test_Previous_Sibling is
      X : Tree (5);
      P : Cursor;
   begin
      Set_Label ("Previous_Sibling: ");
      Create_Non_Empty_Tree (X);
      begin
         P := Previous_Sibling (X, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Previous_Sibling;

   procedure Test_Reference is
      X : aliased Tree (5);
   begin
      Set_Label ("Reference: ");
      Create_Non_Empty_Tree (X);
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
   end Test_Reference;

   procedure Test_Replace_Element is
      X : Tree (5);
   begin
      Set_Label ("Replace_Element: ");
      Create_Non_Empty_Tree (X);
      begin
         Replace_Element (X, 4, No_Element);
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Replace_Element;

begin
   Test_Assign;
   Test_Child;
   Test_Constant_Reference;
   Test_Copy;
   Test_Delete;
   Test_Depth;
   Test_Direction;
   Test_Element;
   Test_First_Child;
   Test_Has_Child;
   Test_In_Subtree;
   Test_Insert_Child;
   Test_Insert_Parent;
   Test_Is_Ancestor_Of;
   Test_Is_Leaf;
   Test_Last_Child;
   Test_Next_Sibling;
   Test_Node_Count;
   Test_Parent;
   Test_Previous_Sibling;
   Test_Reference;
   Test_Replace_Element;
   Check_Results;
end Test;
