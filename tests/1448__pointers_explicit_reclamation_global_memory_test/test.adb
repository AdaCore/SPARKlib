with Ada.Text_IO;
with SPARK.Pointers.Handles.Plain_Handles;
with Inst; use Inst;

--  Execution test for SPARK.Pointers.Explicit_Reclamation.Global_Memory. Proof of the same API is
--  in testsuite/gnatprove/tests/U908-033__hidden_pointers.

procedure Test with SPARK_Mode => Off is

   use Pointers;
   use Ops;

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Create_Deref_Dealloc is
      P : Pointer;
   begin
      Ops.Create_Copy ((F => 1, G => 2), P);
      Assert (Deref (P).F = 1, "Deref of a fresh pointer");
      Assert (Deref (P).G = 2, "Deref of a fresh pointer");
      Dealloc (P);
      Assert (P = Null_Pointer, "Dealloc nulls out the pointer");
   end Test_Create_Deref_Dealloc;

   --  Create builds the cell from an Input, where Create_Copy copies an
   --  existing Object. It is a separate entry point and allocates its own cell.

   procedure Test_Create is
      P, Q : Pointer;
   begin
      Create_From_Int (5, P);
      Assert (Deref (P).F = 5, "Create builds the object from its input");
      Assert (Deref (P).G = 6, "Create builds the object from its input");

      Create_From_Int (5, Q);
      Assert (P /= Q, "Create allocates a fresh cell each time");
      Assert (Deref (Q).F = 5, "The second cell holds its own value");

      Dealloc (P);
      Dealloc (Q);
   end Test_Create;

   procedure Test_Aliasing is
      P, Q : Pointer;
   begin
      Ops.Create_Copy ((F => 1, G => 2), P);
      Q := P;  --  an alias, not a copy of the cell
      Assign (Q, (F => 7, G => 8));
      Assert (Deref (P).F = 7, "Write through an alias is visible");
      Assert (Deref (P).G = 8, "Write through an alias is visible");
      Dealloc (P);
   end Test_Aliasing;

   procedure Test_In_Place_Update is
      P : Pointer;
   begin
      Ops.Create_Copy ((F => 1, G => 2), P);
      declare
         C : access Object := Reference (Memory, P);
      begin
         C.F := 42;
      end;
      Assert (Deref (P).F = 42, "Update through Reference");
      Assert (Deref (P).G = 2, "Update through Reference leaves G alone");
      Assert (Constant_Reference (Memory, P).F = 42, "Constant_Reference");
      Dealloc (P);
   end Test_In_Place_Update;

   procedure Test_Handles is
      P : Pointer;
      H : SPARK.Pointers.Handles.Plain_Handles.Handle;
   begin
      Ops.Create_Copy ((F => 5, G => 6), P);
      H := Handle_Operations.To_Handle (P);
      Assert (Deref (Handle_Operations.Of_Handle (H)).F = 5,
              "Round trip through a handle");
      Assert (Handle_Operations."=" (H, Handle_Operations.To_Handle (P)),
              "Equality on handles to the same cell");
      declare
         P2 : Pointer := Handle_Operations.Of_Handle (H);
      begin
         Dealloc (P2);
      end;
   end Test_Handles;

begin
   Test_Create_Deref_Dealloc;
   Test_Create;
   Test_Aliasing;
   Test_In_Place_Update;
   Test_Handles;
end Test;
