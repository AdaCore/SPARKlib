pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Counters;
with Reclamation_Inst; use Reclamation_Inst;

procedure Test_Reclamation with SPARK_Mode => Off is

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Last_Pointer is
      use Owning_Pointers;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         P : constant Pointer := Create_Owning (42);
      begin
         declare
            Q : constant Pointer := P;
         begin
            Assert
              (Counters.Reclaimed = Before, "Reclaimed while aliases live");
         end;
         Assert
           (Counters.Reclaimed = Before, "Reclaimed while a pointer lives");
      end;
      Assert (Counters.Reclaimed = Before + 1, "Not reclaimed exactly once");
   end Test_Last_Pointer;

   procedure Test_Sharing is
      use Owning_Pointers;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         A : constant Pointer := Create_Owning (1);
         B : constant Pointer := Create_Owning (2);
         C : constant Pointer := A;
      begin
         Assert
           (Counters.Reclaimed = Before, "Reclaimed while shared cells live");
      end;
      Assert (Counters.Reclaimed = Before + 2, "Not reclaimed once per cell");
   end Test_Sharing;

   procedure Test_Replacement is
      use Owning_Pointers;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         P : Pointer := Create_Owning (1);
         Q : Pointer := Create_Owning (2);
      begin
         Q := P;
         Assert
           (Counters.Reclaimed = Before + 1, "Replacement did not reclaim");
         P := Null_Pointer;
         Assert (Counters.Reclaimed = Before + 1, "Reclaimed a shared cell");
         Q := Null_Pointer;
         Assert (Counters.Reclaimed = Before + 2, "Clearing did not reclaim");
      end;
      Assert (Counters.Reclaimed = Before + 2, "Reclaimed a cell twice");
   end Test_Replacement;

   procedure Test_Handle is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      Before : constant Natural := Counters.Reclaimed;
   begin
      declare
         H : Handle := Null_Handle;
      begin
         declare
            P : constant Pointer := Create_Owning (7);
         begin
            H := To_Handle (P);
         end;
         Assert
           (Counters.Reclaimed = Before, "A handle did not retain its cell");
         declare
            H2 : constant Handle := To_Handle (Of_Handle (H));
            H3 : constant Handle := H2;
         begin
            Assert
              (Counters.Reclaimed = Before,
               "Reclaimed while handle copies live");
         end;
         Assert
           (Counters.Reclaimed = Before, "Reclaimed while a handle lives");
      end;
      Assert
        (Counters.Reclaimed = Before + 1,
         "Not reclaimed when the last handle disappears");
   end Test_Handle;

begin
   Test_Last_Pointer;
   Test_Sharing;
   Test_Replacement;
   Test_Handle;
end Test_Reclamation;
