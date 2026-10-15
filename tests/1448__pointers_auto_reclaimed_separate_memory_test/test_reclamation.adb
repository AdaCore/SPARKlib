pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Counters;
with Reclamation_Inst; use Reclamation_Inst;

--  Reclamation timing and weak expiration are outside the logical model

procedure Test_Reclamation with SPARK_Mode => Off is

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Assign_Reclaims is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      use Owning_Ops;
      Before : constant Natural := Counters.Reclaimed;
      M      : Memory_Type := Empty_Map;
      P      : Pointer;
      O      : Owning_Object := Make (2);
   begin
      Create_Owning (M, 1, P);
      Assign (M, P, O);
      Free (O.D);
      Assert
        (Counters.Reclaimed = Before + 1,
         "Assign reclaims the old object once");
      P := Null_Pointer;
      Assert
        (Counters.Reclaimed = Before + 2,
         "Dropping the final pointer reclaims once");
   end Test_Assign_Reclaims;

   procedure Test_Last_Pointer_Reclaims is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      Before : constant Natural := Counters.Reclaimed;
      M      : Memory_Type := Empty_Map;
   begin
      declare
         P : Pointer;
      begin
         Create_Owning (M, 3, P);
         declare
            Q : Pointer := P;
         begin
            P := Null_Pointer;
            Assert
              (Counters.Reclaimed = Before, "An alias keeps the cell alive");
            Q := Null_Pointer;
            Assert
              (Counters.Reclaimed = Before + 1,
               "The last alias reclaims once");
         end;
      end;
      Assert
        (Counters.Reclaimed = Before + 1,
         "Null finalization does not reclaim again");
   end Test_Last_Pointer_Reclaims;

   procedure Test_Handles is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
      M      : Memory_Type := Empty_Map;
      W      : Weak_Handle := Null_Weak_Handle;
   begin
      declare
         H : Strong_Handle := Null_Strong_Handle;
      begin
         declare
            P : Pointer;
         begin
            Create_Owning (M, 7, P);
            H := To_Strong_Handle (P);
            W := To_Weak_Handle (P);
         end;
         Assert
           (Counters.Reclaimed = Before,
            "A strong handle keeps the cell alive");
         declare
            P : constant Pointer := Of_Strong_Handle (H);
            Q : constant Pointer := Of_Weak_Handle (W);
         begin
            Assert (Q = P, "A live weak handle upgrades successfully");
            Assert
              (Of_Strong_Handle (To_Strong_Handle (W)) = P,
               "A live weak handle upgrades to a strong handle");
         end;
      end;
      Assert
        (Counters.Reclaimed = Before + 1,
         "The last strong handle reclaims once");
      Assert
        (To_Strong_Handle (W) = Null_Strong_Handle,
         "An expired weak handle upgrades to a null strong handle");
      Assert
        (Of_Weak_Handle (W) = Null_Pointer,
         "An expired weak handle upgrades to a null pointer");
      W := Null_Weak_Handle;
      Assert
        (Counters.Reclaimed = Before + 1,
         "Dropping the weak handle does not reclaim again");
   end Test_Handles;

begin
   Test_Assign_Reclaims;
   Test_Last_Pointer_Reclaims;
   Test_Handles;
end Test_Reclamation;
