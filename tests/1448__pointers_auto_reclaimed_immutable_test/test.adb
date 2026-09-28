pragma Extensions_Allowed (On);

with Ada.Text_IO;
with SPARK.Big_Integers; use SPARK.Big_Integers;
with Counters;
with Inst; use Inst;

--  Execution test for SPARK.Pointers.Auto_Reclaimed. Proof of the same API is
--  in testsuite/gnatprove/tests/1448__pointers_auto_reclaimed.

procedure Test with SPARK_Mode => Off is
--  Execution only: the same API is proved by the testsuite test above.

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Plain is
      use Plain_Pointers;
      P : Pointer := Create_Plain ((F => 1, G => 2));
   begin
      Assert (Constant_Reference (P).F = 1, "Deref of a fresh pointer");
      Assert (Constant_Reference (P).G = 2, "Deref of a fresh pointer");

      declare
         Q : constant Pointer := P;
      begin
         Assert (Constant_Reference (Q).F = 1, "Deref through a copy");
      end;

      --  The copy is gone; P still designates a live cell
      Assert (Constant_Reference (P).F = 1, "Deref after a copy is dropped");

      --  Deref hands back a copy of the designated value
      Assert (Plain_Ops.Deref (P).F = 1, "Deref of a fresh pointer");
      Assert (Plain_Ops.Deref (P).G = 2, "Deref of a fresh pointer");

      --  Create_Copy builds a fresh cell from an existing Object
      declare
         R : constant Pointer := Plain_Ops.Create_Copy ((F => 3, G => 4));
      begin
         Assert (Constant_Reference (R).F = 3, "Create_Copy filled the cell");
         Assert (Constant_Reference (R).G = 4, "Create_Copy filled the cell");
         Assert (Constant_Reference (P).F = 1, "Create_Copy left P alone");
      end;
   end Test_Plain;

   procedure Test_Reclamation is
      use Owning_Pointers;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         P : constant Pointer := Create_Owning (42);
      begin
         Assert (Constant_Reference (P).D.all = 42, "Deref of an owning cell");
         declare
            Q : constant Pointer := P;
         begin
            Assert (Constant_Reference (Q).D.all = 42, "Deref through a copy");
         end;
         --  Q is gone but P is not, so nothing has been reclaimed yet
         Assert (Counters.Reclaimed = Before, "Reclaimed too early");
      end;
      --  The last pointer is gone
      Assert (Counters.Reclaimed = Before + 1, "Not reclaimed exactly once");
   end Test_Reclamation;

   procedure Test_Sharing is
      use Owning_Pointers;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         A : constant Pointer := Create_Owning (1);
         B : constant Pointer := Create_Owning (2);
         C : constant Pointer := A;
      begin
         Assert (Constant_Reference (C).D.all = 1, "Deref through a copy");
         Assert (Constant_Reference (B).D.all = 2, "Deref of a second cell");
      end;
      --  Two cells were created and three pointers dropped
      Assert (Counters.Reclaimed = Before + 2, "Not reclaimed once per cell");
   end Test_Sharing;

   --  A handle keeps the cell alive on its own, and hands back a pointer to
   --  the same cell.

   procedure Test_Handle is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         H : Handle;
      begin
         declare
            P : constant Pointer := Create_Owning (7);
         begin
            H := To_Handle (P);
         end;
         Assert (Counters.Reclaimed = Before,
                 "A handle does not keep the cell alive");
         Assert (Constant_Reference (Of_Handle (H)).D.all = 7,
                 "Deref through a handle");

         Assert (Of_Handle (Null_Handle) = Null_Pointer,
                 "Null_Handle designates Null_Pointer");

         --  A second handle to the same cell, and a copy of one
         declare
            H2 : constant Handle := To_Handle (Of_Handle (H));
            H3 : constant Handle := H2;
         begin
            Assert (Constant_Reference (Of_Handle (H3)).D.all = 7,
                    "Deref through a handle copy");
         end;
         Assert (Counters.Reclaimed = Before, "Reclaimed while a handle lives");
      end;
      Assert (Counters.Reclaimed = Before + 1,
              "Not reclaimed exactly once when the last handle dies");
   end Test_Handle;

   --  A chain walked by a non-ghost recursive function whose termination
   --  rests on List_Variant.Weight, the library's Static ghost measure.

   procedure Test_Variant is
      use List_Pointers;
      use List_Handle_Ops;
      T : constant Pointer :=
        Create_Cell ((Value => 3, Next => Null_Handle));
      M : constant Pointer := Create_Cell ((Value => 2, Next => To_Handle (T)));
      H : constant Pointer := Create_Cell ((Value => 1, Next => To_Handle (M)));
   begin
      Assert (Count (H) = 3, "Count of a three-cell chain");
      Assert (Count (M) = 2, "Count of its tail");
      Assert (Count (Null_Pointer) = 0, "Count of the empty chain");
   end Test_Variant;

begin
   Test_Plain;
   Test_Reclamation;
   Test_Sharing;
   Test_Handle;
   Test_Variant;
end Test;
