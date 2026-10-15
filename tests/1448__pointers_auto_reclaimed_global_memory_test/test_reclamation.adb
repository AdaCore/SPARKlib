pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Counters;
with Reclamation_Inst; use Reclamation_Inst;

--  Reclamation observations are outside the logical memory model

procedure Test_Reclamation with SPARK_Mode => Off is

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Assign_Reclaims is
      use Owning_Pointers;
      use Owning_Ops;
      Before : constant Natural := Counters.Reclaimed;
      P      : Pointer;
   begin
      Create_Owning (1, P);
      --  Assign reclaims the value it overwrites
      Assign (P, (D => new Integer'(2)));
      Assert (Counters.Reclaimed = Before + 1, "Assign did not reclaim");
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
            Assert
              (Counters.Reclaimed = Before, "Reclaimed while aliases live");
         end;
         Assert (Counters.Reclaimed = Before, "Reclaimed too early");
      end;
      Assert (Counters.Reclaimed = Before + 1, "Not reclaimed exactly once");
   end Test_Last_Pointer_Reclaims;

   --  A strong handle keeps the cell alive on its own

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
         Assert
           (Counters.Reclaimed = Before,
            "A strong handle does not keep the cell alive");
      end;
      Assert
        (Counters.Reclaimed = Before + 1,
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
               H := To_Strong_Handle (P);
               W1 := To_Weak_Handle (P);
            end;
            W2 := W1;
            Assert
              (Counters.Reclaimed = Before,
               "Reclaimed while a strong handle is alive");
            Assert
              (Of_Weak_Handle (W1) = Of_Strong_Handle (H),
               "A weak handle stays live while a strong handle retains the cell");
         end;

         --  Only weak handles are left, so the cell is gone

         Assert
           (Counters.Reclaimed = Before + 1,
            "Weak handles kept the cell alive");
         Assert
           (Of_Weak_Handle (W1) = Null_Pointer,
            "A stale weak handle did not resolve to null");
         Assert
           (Of_Weak_Handle (W2) = Null_Pointer,
            "A stale weak handle copy did not resolve to null");
         Assert
           (Of_Strong_Handle (To_Strong_Handle (W1)) = Null_Pointer,
            "A stale weak handle did not upgrade to a null handle");
      end;
      Assert
        (Counters.Reclaimed = Before + 1,
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
      Assert (Counters.Reclaimed = Before + 2, "The cycle was not reclaimed");

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
         Assert
           (Of_Weak_Handle (Deref (P).Prev) = Null_Pointer,
            "The back edge should be dangling");
         Assert
           (Counters.Reclaimed = Before + 1,
            "The weak handle was not reclaimed");
      end;
   end Test_Cycle_Is_Reclaimed;

begin
   Test_Assign_Reclaims;
   Test_Last_Pointer_Reclaims;
   Test_Strong_Handle;
   Test_Weak_Handle;
   Test_Cycle_Is_Reclaimed;
end Test_Reclamation;
