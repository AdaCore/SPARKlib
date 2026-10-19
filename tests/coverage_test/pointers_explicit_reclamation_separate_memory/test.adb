with Ada.Text_IO;
with SPARK.Pointers.Handles.Plain_Handles;
with Inst; use Inst;

--  Proof and execution tests for explicit reclamation with separate memories

procedure Test with SPARK_Mode is

   use Pointers;
   use Pointers.Memory_Model;
   use Ops;

   procedure Assert (B : Boolean; S : String)
   with Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Create_Deref_Dealloc is
      M : aliased Memory_Type := Empty_Map;
      P : Pointer;
   begin
      Ops.Create_Copy (M, (F => 1, G => 2), P);
      Assert (Deref (M, P).F = 1, "Deref of a fresh pointer");
      Assign (M, P, (F => 7, G => 8));
      Assert (Deref (M, P).F = 7, "Deref after Assign");
      Dealloc (M, P);
      Assert (P = Null_Pointer, "Dealloc nulls out the pointer");
   end Test_Create_Deref_Dealloc;

   --  Create builds the cell from an Input, where Create_Copy copies an
   --  existing Object. Each memory allocates its own cells.

   procedure Test_Create is
      M1   : aliased Memory_Type := Empty_Map;
      M2   : aliased Memory_Type := Empty_Map;
      P, Q : Pointer;
   begin
      Create_From_Int (M1, 5, P);
      Assert (Deref (M1, P).F = 5, "Create builds the object from its input");
      Assert (Deref (M1, P).G = 6, "Create builds the object from its input");
      --  Inequality is expected unproved: freshness is local to each memory
      Create_From_Int (M2, 9, Q);
      Assert (P /= Q, "Cells from two memories are distinct");
      Assert (Deref (M2, Q).F = 9, "The second memory holds its own cell");

      Dealloc (M1, P);
      Dealloc (M2, Q);
   end Test_Create;

   procedure Test_In_Place_Update is
      M : aliased Memory_Type := Empty_Map;
      P : Pointer;
   begin
      Ops.Create_Copy (M, (F => 1, G => 2), P);
      declare
         C : access Object := Reference (M, P);
      begin
         C.F := 42;
      end;
      Assert (Deref (M, P).F = 42, "Update through Reference");
      Assert (Constant_Reference (M, P).G = 2, "Constant_Reference");
      Dealloc (M, P);
   end Test_In_Place_Update;

   --  Handles let a pointer be stored inside the designated object, which is
   --  what makes recursive structures possible. Separate_Memory reclaims
   --  explicitly, so the flavour is Plain_Handles: the handle owns nothing.

   procedure Test_Handles is
      M : aliased Memory_Type := Empty_Map;
      P : Pointer;
      H : aliased SPARK.Pointers.Handles.Plain_Handles.Handle;
   begin
      Ops.Create_Copy (M, (F => 5, G => 6), P);
      H := Handle_Operations.To_Handle (P);
      Assert
        (Deref (M, Handle_Operations.Of_Handle (H)).F = 5,
         "Round trip through a handle");

      --  Pointer is not subject to ownership here, so Of_Handle returning a
      --  copy is all that is needed; there is no in-place accessor to test.
      Assert
        (Handle_Operations."=" (H, Handle_Operations.To_Handle (P)),
         "Equality on handles to the same cell");

      Assert
        (Handle_Operations.Of_Handle (Handle_Operations.Null_Handle)
         = Null_Pointer,
         "Null_Handle designates Null_Pointer");

      declare
         P2 : Pointer := Handle_Operations.Of_Handle (H);
      begin
         Dealloc (M, P2);
      end;
   end Test_Handles;

   procedure Test_Move_Memory is
      M1 : aliased Memory_Type := Empty_Map;
      M2 : aliased Memory_Type := Empty_Map;
      P  : Pointer;
      Q  : Pointer;

      function Is_Q (A : Pointer) return Boolean
      is (A = Q);
      --  A set comprehension: Elements never calls this at run time, but it
      --  has to be a real subprogram because its access is taken. It can only
      --  mention non-ghost entities, hence pointer equality rather than the
      --  memory model.

   begin
      Ops.Create_Copy (M1, (F => 3, G => 4), P);
      Ops.Create_Copy (M1, (F => 5, G => 6), Q);

      --  Move a single cell out of M1

      Move_Memory (M1, M2, Only (P));
      Assert (Deref (M2, P).F = 3, "Deref after the cell moved memories");
      Assert (Deref (M1, Q).F = 5, "The other cell stayed in M1");

      --  Move the remaining cell, designated through a set comprehension

      Move_Memory (M1, M2, Elements (Is_Q'Access));
      Assert (Deref (M2, Q).F = 5, "Deref after a comprehension move");

      Dealloc (M2, P);
      Dealloc (M2, Q);
   end Test_Move_Memory;

   procedure Test_Empty_And_Multiple_Moves is
      M1      : Memory_Type := Empty_Map;
      M2      : Memory_Type := Empty_Map;
      P, Q, R : Pointer;
   begin
      Move_Memory (M1, M2, None);
      pragma Assert (Static => Is_Empty (+M1) and Is_Empty (+M2));
      Ops.Create_Copy (M1, (F => 1, G => 2), P);
      Ops.Create_Copy (M1, (F => 3, G => 4), Q);
      Ops.Create_Copy (M2, (F => 5, G => 6), R);
      Move_Memory (M1, M2, Add (Only (P), Q));
      pragma Assert (Static => Is_Empty (+M1));
      Assert
        (Deref (M2, P).F = 1 and Deref (M2, Q).F = 3,
         "Moving several cells preserves their values");
      Assert (Deref (M2, R).F = 5, "Moving cells preserves the target memory");
      Move_Memory (M2, M1, Only (P));
      Assign (M1, P, (F => 7, G => 8));
      Assert
        (Deref (M1, P).F = 7, "A cell can move back to its source memory");
      Assert (Deref (M2, Q).F = 3, "Moving one cell preserves the others");
      Dealloc (M1, P);
      Dealloc (M2, Q);
      Dealloc (M2, R);
      pragma Assert (Static => Is_Empty (+M1) and Is_Empty (+M2));
   end Test_Empty_And_Multiple_Moves;

   procedure Test_Owning_Copy is
      package Cells renames Owning.Pointers;
      package Copies renames Owning.Ops;
      use type Owning.Int_Access;
      M : aliased Cells.Memory_Model.Memory_Type :=
        Cells.Memory_Model.Empty_Map;
      O : Owning.Object := (D => new Integer'(5));
      P : Cells.Pointer;
   begin
      Copies.Create_Copy (M, O, P);
      O.D.all := 7;
      declare
         C : Owning.Object := Copies.Deref (M, P);
      begin
         Assert (C.D.all = 5, "Create_Copy duplicates owned data");
         C.D.all := 9;
         Owning.Free (C.D);
      end;
      declare
         R : access Owning.Object := Cells.Reference (M, P);
      begin
         Assert (R.D.all = 5, "Changing a copy leaves its source alone");
         Owning.Free (R.D);
      end;
      Copies.Assign (M, P, O);
      Owning.Free (O.D);
      declare
         R : access Owning.Object := Cells.Reference (M, P);
      begin
         Assert (R.D.all = 7, "Assign duplicates owned data");
         Owning.Free (R.D);
      end;
      Cells.Dealloc (M, P);
      Copies.Create_Copy (M, O, P);
      declare
         C : Owning.Object := Copies.Deref (M, P);
      begin
         Assert (C.D = null, "Copying a reclaimed object preserves null");
      end;
      Cells.Dealloc (M, P);
   end Test_Owning_Copy;

   procedure Test_Null_And_Reuse is
      M : Memory_Type := Empty_Map;
      P : Pointer;
   begin
      Assert (P = Null_Pointer, "Default pointer is null");
      Ops.Create_Copy (M, (F => 0, G => 0), P);
      Assign (M, P, (F => Integer'First, G => Integer'Last));
      Assert
        (Deref (M, P).F = Integer'First and Deref (M, P).G = Integer'Last,
         "Assign preserves boundary values");
      Dealloc (M, P);
      Ops.Create_Copy (M, (F => 9, G => 10), P);
      Assert (Deref (M, P).F = 9, "A reclaimed pointer can be reused");
      Dealloc (M, P);
   end Test_Null_And_Reuse;

begin
   Test_Create_Deref_Dealloc;
   Test_Create;
   Test_In_Place_Update;
   Test_Handles;
   Test_Move_Memory;
   Test_Empty_And_Multiple_Moves;
   Test_Null_And_Reuse;
   Test_Owning_Copy;
end Test;
