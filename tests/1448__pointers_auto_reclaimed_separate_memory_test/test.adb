pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Inst; use Inst;

--  Ordinary clients are both proved against the contracts and executed

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String)
   with Pre => B;

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
      M    : Memory_Type := Empty_Map;
      P, Q : Pointer;
   begin
      Assert
        (P = Null_Pointer and Q = Null_Pointer, "Default pointers are null");
      pragma Assert (Static => Is_Empty (+M));
      Create_Copy (M, (F => 1, G => 2), P);
      Assert (Deref (M, P).F = 1, "Deref of a fresh pointer");
      Assert (Deref (M, P).G = 2, "Deref preserves the other field");
      Q := P;
      Assign (M, Q, (F => 7, G => 8));
      Assert (Deref (M, P).F = 7, "Write through an alias is visible");
      Assert
        (Deref (M, P).G = 8, "Write through an alias preserves both fields");
      Q := Null_Pointer;
      Assert
        (Deref (M, P).F = 7, "Dropping an alias preserves the other owner");
      Create_Copy (M, (F => 9, G => 10), Q);
      Assert (P /= Q, "Create_Copy allocates a distinct cell");
      Q := P;
      Assert
        (Deref (M, Q).G = 8, "Replacing a pointer preserves its new cell");
   end Test_Aliasing;

   procedure Test_Two_Memories is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M1   : Memory_Type := Empty_Map;
      M2   : Memory_Type := Empty_Map;
      P, Q : Pointer;
   begin
      Create_Copy (M1, (F => 1, G => 2), P);
      Create_Copy (M2, (F => 3, G => 4), Q);
      Assign (M2, Q, (F => 30, G => 40));
      Assert
        (Deref (M1, P).F = 1, "A write in one memory leaves the other alone");
      Assert (Deref (M1, P).G = 2, "The other field is preserved too");
      Assert (Deref (M2, Q).F = 30, "The written cell has its new value");
      Assert (Deref (M2, Q).G = 40, "The whole written object is replaced");
   end Test_Two_Memories;

   procedure Test_Create is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M    : Memory_Type := Empty_Map;
      P, Q : Pointer;
   begin
      Create_From_Int (M, Integer'First, P);
      Assert
        (Deref (M, P).F = Integer'First, "Create accepts the lower bound");
      Assert
        (Deref (M, P).G = Integer'First, "Create initializes both fields");
      Create_From_Int (M, Integer'Last, Q);
      Assert (Deref (M, Q).F = Integer'Last, "Create accepts the upper bound");
      Assert (P /= Q, "Create allocates a fresh cell each time");
      Create_From_Int (M, 0, P);
      Assert (Deref (M, P).F = 0, "Create can replace a nonnull pointer");
      Assert
        (Deref (M, Q).G = Integer'Last, "Create preserves existing cells");
   end Test_Create;

   procedure Test_Move_Memory is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      M1      : Memory_Type := Empty_Map;
      M2      : Memory_Type := Empty_Map;
      P, Q, R : Pointer;
   begin
      Move_Memory (M1, M2, None);
      pragma Assert (Static => Is_Empty (+M1) and Is_Empty (+M2));
      Create_Copy (M1, (F => 11, G => 12), P);
      Create_Copy (M1, (F => 21, G => 22), Q);
      Create_Copy (M2, (F => 31, G => 32), R);
      Move_Memory (M1, M2, None);
      Assert (Deref (M1, P).F = 11, "An empty move preserves its source");
      Assert (Deref (M2, R).F = 31, "An empty move preserves its target");
      Move_Memory (M1, M2, Only (P));
      pragma Assert (Static => not In_Memory (+M1, P));
      Assert (Deref (M2, P).F = 11, "A singleton move preserves the object");
      Assert
        (Deref (M1, Q).F = 21,
         "A singleton move preserves other source cells");
      Assert (Deref (M2, R).F = 31, "A singleton move preserves target cells");
      Assign (M2, P, (F => 13, G => 14));
      Move_Memory (M2, M1, Only (P));
      Assert (Deref (M1, P).G = 14, "A cell can move back after an update");
      Move_Memory (M1, M2, Add (Only (P), Q));
      pragma Assert (Static => Is_Empty (+M1));
      Assert
        (Deref (M2, P).F = 13,
         "A multiple-cell move preserves the first cell");
      Assert
        (Deref (M2, Q).G = 22,
         "A multiple-cell move preserves the second cell");
      Assert
        (Deref (M2, R).G = 32, "A multiple-cell move retains target data");
      Move_Memory (M2, M1, Add (Only (P), Q));
      Assert (Deref (M1, P).F = 13, "Multiple cells can move back");
      Assert (Deref (M1, Q).F = 21, "The second cell also moves back");
      Assert (Deref (M2, R).F = 31, "Other cells remain in the source");
   end Test_Move_Memory;

   procedure Test_Owning_Copies is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      use Owning_Ops;
      M : Memory_Type := Empty_Map;
      P : Pointer;
      O : Owning_Object := (D => null);
   begin
      Create_Copy (M, O, P);
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert (C.D = null, "An empty owned object can be copied");
         Free (C.D);
      end;
      O := Make (1);
      Assign (M, P, O);
      O.D.all := 2;
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert
           (C.D /= null and then C.D.all = 1,
            "Assign makes an independent copy");
         C.D.all := 3;
         Free (C.D);
      end;
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert
           (C.D /= null and then C.D.all = 1,
            "Deref makes an independent copy");
         Free (C.D);
      end;
      Create_Copy (M, O, P);
      Free (O.D);
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert
           (C.D /= null and then C.D.all = 2,
            "Create_Copy owns a distinct copy");
         Free (C.D);
      end;
      Assign (M, P, O);
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert (C.D = null, "Assign accepts an empty owned object");
         Free (C.D);
      end;
      Create_Owning (M, 7, P);
      declare
         C : Owning_Object := Deref (M, P);
      begin
         Assert
           (C.D /= null and then C.D.all = 7,
            "Create builds an owning object");
         Free (C.D);
      end;
   end Test_Owning_Copies;

   procedure Test_Handles is
      use Owning_Pointers;
      use Owning_Pointers.Memory_Model;
      use Owning_Handles;
      use Owning_Handle_Ops;
      M    : Memory_Type := Empty_Map;
      P, Q : Pointer;
      H    : Strong_Handle := Null_Strong_Handle;
      W    : Weak_Handle := Null_Weak_Handle;
   begin
      Assert
        (Of_Strong_Handle (H) = Null_Pointer,
         "The null strong handle is null");
      Q := Of_Weak_Handle (W);
      Assert
        (Q = Null_Pointer, "The null weak handle upgrades to a null pointer");
      H := To_Strong_Handle (W);
      Assert
        (Of_Strong_Handle (H) = Null_Pointer,
         "The null weak handle stays null");
      W := To_Weak_Handle (H);
      Assert
        (W = Null_Weak_Handle, "Downgrading a null strong handle gives null");
      Q := Owning_Live_Ops.Of_Weak_Handle (W, Null_Pointer);
      Assert (Q = Null_Pointer, "Witnessed conversion of a null weak handle");
      H := Owning_Live_Ops.To_Strong_Handle (W, Null_Pointer);
      Assert
        (H = Null_Strong_Handle,
         "Witnessed conversion to a null strong handle");

      Create_Owning (M, 7, P);
      Create_Owning (M, 8, Q);
      H := To_Strong_Handle (P);
      W := To_Weak_Handle (P);
      Assert
        (Of_Strong_Handle (H) = P,
         "Strong handle conversion preserves identity");
      Assert
        (H = To_Strong_Handle (P), "Strong handles to one cell are equal");
      Assert (W = To_Weak_Handle (H), "Weak handles to one cell are equal");
      Assert
        (H /= To_Strong_Handle (Q), "Strong handles to distinct cells differ");
      Assert
        (W /= To_Weak_Handle (Q), "Weak handles to distinct cells differ");
      declare
         H2 : Strong_Handle := H;
         W2 : Weak_Handle := W;
      begin
         H2 := To_Strong_Handle (Q);
         W2 := To_Weak_Handle (Q);
         Assert (Of_Strong_Handle (H2) = Q, "Strong handle replacement");
         Assert (W2 = To_Weak_Handle (Q), "Weak handle replacement");
         H2 := H;
         W2 := W;
         Assert
           (Of_Strong_Handle (H2) = P,
            "Strong handle copies preserve identity");
         Assert (W2 = W, "Weak handle copies preserve identity");
      end;
      Q := Owning_Live_Ops.Of_Weak_Handle (W, P);
      Assert (Q = P, "A witnessed upgrade returns the same cell");
      H := Owning_Live_Ops.To_Strong_Handle (W, P);
      Assert
        (Of_Strong_Handle (H) = P, "A witnessed strong handle keeps identity");
      declare
         C : Owning_Object := Owning_Ops.Deref (M, Of_Strong_Handle (H));
      begin
         Assert
           (C.D /= null and then C.D.all = 7, "Deref through a strong handle");
         Free (C.D);
      end;
      Q := Of_Weak_Handle (W);
      Assert
        (Q = P or Q = Null_Pointer,
         "An unwitnessed upgrade respects its contract");
      H := To_Strong_Handle (W);
      Q := Of_Strong_Handle (H);
      Assert
        (Q = P or Q = Null_Pointer,
         "An unwitnessed strong upgrade respects its contract");
   end Test_Handles;

begin
   Test_Aliasing;
   Test_Two_Memories;
   Test_Create;
   Test_Move_Memory;
   Test_Owning_Copies;
   Test_Handles;
end Test;
