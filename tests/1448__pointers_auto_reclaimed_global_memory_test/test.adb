pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Counters;
with Inst; use Inst;

--  Execution test for SPARK.Pointers.Auto_Reclaimed.Global_Memory. Proof of the
--  same API is in testsuite/gnatprove/tests/1448__pointers_auto_reclaimed_mutable.

procedure Test with SPARK_Mode => Off is

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Aliasing is
      use Plain_Pointers;
      use Plain_Ops;
      P : Pointer;
   begin
      Plain_Ops.Create_Copy ((F => 1, G => 2), P);
      Assert (Deref (P).F = 1, "Deref of a fresh pointer");
      declare
         Q : constant Pointer := P;
      begin
         Assign (Q, (F => 7, G => 8));
         Assert (Deref (P).F = 7, "Write through an alias is visible");
         Assert (Deref (P).G = 8, "Write through an alias is visible");
      end;
   end Test_Aliasing;

   procedure Test_Distinct_Cells is
      use Plain_Pointers;
      use Plain_Ops;
      P, Q : Pointer;
   begin
      Plain_Ops.Create_Copy ((F => 1, G => 2), P);
      Plain_Ops.Create_Copy ((F => 3, G => 4), Q);
      Assign (Q, (F => 30, G => 40));
      Assert (Deref (P).F = 1, "Two created cells are distinct");
      Assert (Deref (Q).F = 30, "Two created cells are distinct");
   end Test_Distinct_Cells;

   procedure Test_Assign_Reclaims is
      use Owning_Pointers;
      use Owning_Ops;
      Before : constant Natural := Counters.Reclaimed;
      P : Pointer;
   begin
      Create_Owning (1, P);
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert (C.D.all = 1, "Deref of an owning cell");
         Free (C.D);  --  Deref copies, so the caller owns the copy
      end;

      --  Assign reclaims the value it overwrites
      Assign (P, (D => new Integer'(2)));
      Assert (Counters.Reclaimed = Before + 1, "Assign did not reclaim");
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert (C.D.all = 2, "Deref after Assign");
         Free (C.D);
      end;
   end Test_Assign_Reclaims;

   procedure Test_Last_Pointer_Reclaims is
      use Owning_Pointers;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         P : Pointer;
      begin
         Create_Owning (3, P);
         declare
            Q : constant Pointer := P;
         begin
            declare
               C : Owning_Object := Owning_Ops.Deref (Q);
            begin
               Assert (C.D.all = 3, "Deref through an alias");
               Free (C.D);
            end;
         end;
         Assert (Counters.Reclaimed = Before, "Reclaimed too early");
      end;
      Assert (Counters.Reclaimed = Before + 1, "Not reclaimed exactly once");
   end Test_Last_Pointer_Reclaims;

   --  A strong handle keeps the cell alive on its own, and hands back a
   --  pointer to the same cell.

   procedure Test_Strong_Handle is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         H : Strong_Handle;
      begin
         declare
            P : Pointer;
         begin
            Create_Owning (4, P);
            H := To_Strong_Handle (P);
         end;
         Assert (Counters.Reclaimed = Before,
                 "A strong handle does not keep the cell alive");
         declare
            C : Owning_Object := Owning_Ops.Deref (Of_Strong_Handle (H));
         begin
            Assert (C.D.all = 4, "Deref through a strong handle");
            Free (C.D);
         end;
      end;
      Assert (Counters.Reclaimed = Before + 1,
              "Not reclaimed exactly once when the strong handle dies");
   end Test_Strong_Handle;

   --  A weak handle does not keep the cell alive, and resolves to a null
   --  pointer once the cell has been reclaimed.

   procedure Test_Weak_Handle is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         W1, W2 : Weak_Handle;
      begin
         declare
            H : Strong_Handle;
         begin
            declare
               P : Pointer;
            begin
               Create_Owning (5, P);
               H  := To_Strong_Handle (P);
               W1 := To_Weak_Handle (P);
            end;
            W2 := W1;
            Assert (Counters.Reclaimed = Before,
                    "Reclaimed while a strong handle is alive");
            declare
               C : Owning_Object := Owning_Ops.Deref (Of_Weak_Handle (W1));
            begin
               Assert (C.D.all = 5, "Deref through a live weak handle");
               Free (C.D);
            end;
         end;

         --  Only weak handles are left, so the cell is gone

         Assert (Counters.Reclaimed = Before + 1,
                 "Weak handles kept the cell alive");
         Assert (Of_Weak_Handle (W1) = Null_Pointer,
                 "A stale weak handle did not resolve to null");
         Assert (Of_Weak_Handle (W2) = Null_Pointer,
                 "A stale weak handle copy did not resolve to null");
         Assert (Of_Strong_Handle (To_Strong_Handle (W1)) = Null_Pointer,
                 "A stale weak handle did not upgrade to a null handle");
      end;
      Assert (Counters.Reclaimed = Before + 1,
              "Reclaimed again when the weak handles died");
   end Test_Weak_Handle;

   --  What weak handles are for: a cycle that is still reclaimed. Two cells
   --  are held by strong handles, and one holds a weak handle back to the
   --  other. Both are reclaimed when the strong handles go.

   procedure Test_Cycle_Is_Reclaimed is
      use Cyclic_Pointers;
      use Cyclic_Handles;
      use Cyclic_Handle_Ops;
      use Cyclic_Ops;
      Before : Natural;
   begin
      --  Create P -> Q, Q is not reclaimed when it goes out of scope, both
      --  are reclaimed when P goes out of scope.
      declare
         P : Pointer;
      begin
         Create_Cell (6, P);
         declare
            Q : Pointer;
         begin
            Create_Cell (7, Q);
            Assign (Q, (Deref (Q) with delta Prev => To_Weak_Handle (P)));
            Assign (P, (Deref (P) with delta Next => To_Strong_Handle (Q)));
            Before := Counters.Reclaimed;
         end;
         Assert (Counters.Reclaimed = Before, "Reclaimed too early");
      end;
      Assert (Counters.Reclaimed = Before + 2,
              "The cycle was not reclaimed");

      --  Create Q -> P, Q is reclaimed when it goes out of scope, it leaves
      --  P with a dangling back edge.
      declare
         P : Pointer;
      begin
         Create_Cell (6, P);
         declare
            Q : Pointer;
         begin
            Create_Cell (7, Q);
            Assign (P, (Deref (P) with delta Prev => To_Weak_Handle (Q)));
            Assign (Q, (Deref (Q) with delta Next => To_Strong_Handle (P)));
            Before := Counters.Reclaimed;
         end;
         Assert (Of_Weak_Handle (Deref (P).Prev) = Null_Pointer,
                 "The back edge should be dangling");
         Assert (Counters.Reclaimed = Before + 1,
                 "The weak handle was not reclaimed");
      end;
   end Test_Cycle_Is_Reclaimed;

   --  The handle operations the tests above do not reach: equality, the
   --  weak-to-strong upgrade of a live handle, and the witnessed conversions,
   --  whose witness is the pointer the caller is already holding.

   procedure Test_Handle_Operations is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         P : Pointer;
      begin
         Create_Owning (8, P);
         declare
            H1 : constant Strong_Handle := To_Strong_Handle (P);
            H2 : constant Strong_Handle := To_Strong_Handle (P);
            W1 : constant Weak_Handle := To_Weak_Handle (H1);
            W2 : constant Weak_Handle := To_Weak_Handle (P);
         begin
            Assert (Owning_Handle_Ops."=" (H1, H2),
                    "Two strong handles to the same cell are not equal");
            Assert (Owning_Handle_Ops."=" (W1, W2),
                    "Two weak handles to the same cell are not equal");

            --  P holds the cell, so the upgrade cannot fail
            Assert (Of_Strong_Handle (To_Strong_Handle (W1)) = P,
                    "Upgrade of a live weak handle");
            Assert (Owning_Live_Ops.Of_Weak_Handle (W1, P) = P,
                    "Witnessed upgrade returned another cell");
            Assert (Of_Strong_Handle (Owning_Live_Ops.To_Strong_Handle (W1, P))
                    = P,
                    "Witnessed strong handle designates another cell");
         end;
      end;
      Assert (Counters.Reclaimed = Before + 1,
              "Not reclaimed exactly once when every handle died");
   end Test_Handle_Operations;

begin
   Test_Aliasing;
   Test_Distinct_Cells;
   Test_Assign_Reclaims;
   Test_Last_Pointer_Reclaims;
   Test_Strong_Handle;
   Test_Weak_Handle;
   Test_Cycle_Is_Reclaimed;
   Test_Handle_Operations;
end Test;
