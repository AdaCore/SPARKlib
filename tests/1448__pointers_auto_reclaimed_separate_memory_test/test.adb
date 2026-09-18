pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Counters;
with Inst; use Inst;

--  Execution test for SPARK.Pointers.Auto_Reclaimed.Separate_Memory, the
--  counterpart of 1448__pointers_auto_reclaimed_global_memory_test. The memory is
--  an object here, so every operation takes one, and Move_Memory carries
--  cells from one to another.

procedure Test with SPARK_Mode => Off is

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Aliasing is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M : Memory_Type := Empty_Map;
      P : Pointer;
   begin
      Create_Copy (M, (F => 1, G => 2), P);
      Assert (Deref (M, P).F = 1, "Deref of a fresh pointer");
      declare
         Q : constant Pointer := P;
      begin
         Assign (M, Q, (F => 7, G => 8));
         Assert (Deref (M, P).F = 7, "Write through an alias is visible");
         Assert (Deref (M, P).G = 8, "Write through an alias is visible");
      end;
   end Test_Aliasing;

   --  Two memories hold their own cells. This is the property the unit exists
   --  for: an operation naming one memory cannot have touched the other.

   procedure Test_Two_Memories is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M1 : Memory_Type := Empty_Map;
      M2 : Memory_Type := Empty_Map;
      P, Q : Pointer;
   begin
      Create_Copy (M1, (F => 1, G => 2), P);
      Create_Copy (M2, (F => 3, G => 4), Q);
      Assign (M2, Q, (F => 30, G => 40));
      Assert (Deref (M1, P).F = 1, "A write in one memory left the other alone");
      Assert (Deref (M2, Q).F = 30, "The written cell has its new value");
   end Test_Two_Memories;

   --  Create builds the cell from an Input, where Create_Copy copies an
   --  existing Object.

   procedure Test_Create is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M : Memory_Type := Empty_Map;
      P, Q : Pointer;
   begin
      Create_From_Int (M, 5, P);
      Assert (Deref (M, P).F = 5, "Create builds the object from its input");
      Assert (Deref (M, P).G = 6, "Create builds the object from its input");
      Create_From_Int (M, 5, Q);
      Assert (P /= Q, "Create allocates a fresh cell each time");
   end Test_Create;

   --  Move_Memory carries a cell from one memory to another. The footprint is
   --  named by pointer identity, which is all a non-ghost comprehension can
   --  say.

   procedure Test_Move_Memory is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M1 : Memory_Type := Empty_Map;
      M2 : Memory_Type := Empty_Map;
      P  : Pointer;
   begin
      Create_Copy (M1, (F => 11, G => 12), P);
      Move_Memory (M1, M2, Only (P));
      Assert (Deref (M2, P).F = 11, "Deref after a move between memories");
      Assign (M2, P, (F => 13, G => 14));
      Assert (Deref (M2, P).F = 13, "Assign in the target memory");
   end Test_Move_Memory;

   --  Reclamation is unchanged by the memory being an object: it is driven by
   --  the pointer's reference count, which the model says nothing about.

   procedure Test_Assign_Reclaims is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      use Owning_Ops;
      Before : constant Natural := Counters.Reclaimed;
      M : Memory_Type := Empty_Map;
      P : Pointer;
   begin
      Create_Owning (M, 1, P);
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert (C.D.all = 1, "Deref of an owning cell");
         Free (C.D);  --  Deref copies, so the caller owns the copy
      end;

      Assign (M, P, (D => new Integer'(2)));
      Assert (Counters.Reclaimed = Before + 1, "Assign did not reclaim");
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert (C.D.all = 2, "Deref after Assign");
         Free (C.D);
      end;
   end Test_Assign_Reclaims;

   procedure Test_Last_Pointer_Reclaims is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      Before : constant Natural := Counters.Reclaimed;
      M : Memory_Type := Empty_Map;
   begin
      declare
         P : Pointer;
      begin
         Create_Owning (M, 3, P);
         declare
            Q : constant Pointer := P;
            C : Owning_Object := Owning_Ops.Deref (M, Q);
         begin
            Assert (C.D.all = 3, "Deref through an alias");
            Free (C.D);
         end;
         Assert (Counters.Reclaimed = Before, "Reclaimed too early");
      end;
      Assert (Counters.Reclaimed = Before + 1, "Not reclaimed exactly once");
   end Test_Last_Pointer_Reclaims;

   --  A cell that outlives the memory it was created in: the memory is a
   --  proof device with no run-time content, so reclamation follows the
   --  pointer, not the memory object.

   procedure Test_Handles is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
      M : Memory_Type := Empty_Map;
   begin
      declare
         H : Strong_Handle;
         W : Weak_Handle;
      begin
         declare
            P : Pointer;
         begin
            Create_Owning (M, 7, P);
            H := To_Strong_Handle (P);
            W := To_Weak_Handle (P);
         end;
         Assert (Counters.Reclaimed = Before,
                 "A strong handle does not keep the cell alive");
         declare
            C : Owning_Object := Owning_Ops.Deref (M, Of_Strong_Handle (H));
         begin
            Assert (C.D.all = 7, "Deref through a strong handle");
            Free (C.D);
         end;

         --  The witnessed upgrade cannot fail: the caller hands over the
         --  pointer it is holding, which is what keeps the cell alive.
         declare
            P : constant Pointer := Of_Strong_Handle (H);
            Q : constant Pointer := Owning_Live_Ops.Of_Weak_Handle (W, P);
         begin
            Assert (Q = P, "Witnessed upgrade returned the same cell");
            Assert (Of_Strong_Handle
                      (Owning_Live_Ops.To_Strong_Handle (W, P)) = P,
                    "Witnessed strong handle designates another cell");

            --  The unwitnessed conversions, which may fail in general but
            --  cannot here, and equality on handles.
            Assert (Of_Weak_Handle (W) = P,
                    "Upgrade of a live weak handle");
            Assert (Of_Strong_Handle (To_Strong_Handle (W)) = P,
                    "Strong handle from a live weak handle");
            Assert (Owning_Handle_Ops."=" (H, To_Strong_Handle (P)),
                    "Two strong handles to the same cell are not equal");
            Assert (Owning_Handle_Ops."=" (W, To_Weak_Handle (H)),
                    "Two weak handles to the same cell are not equal");
         end;
      end;
      Assert (Counters.Reclaimed = Before + 1,
              "Not reclaimed when the last handle died");
   end Test_Handles;

begin
   Test_Aliasing;
   Test_Two_Memories;
   Test_Create;
   Test_Move_Memory;
   Test_Assign_Reclaims;
   Test_Last_Pointer_Reclaims;
   Test_Handles;
end Test;
