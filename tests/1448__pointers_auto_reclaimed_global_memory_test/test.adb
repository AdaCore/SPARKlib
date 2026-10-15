pragma Extensions_Allowed (On);

with Ada.Text_IO;
with Inst; use Inst;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String)
   with Pre => B;

   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Plain is
      use Plain_Pointers;
      use Plain_Pointers.Memory_Model;
      use Plain_Ops;
      P, Q : Pointer;
   begin
      Assert
        (P = Null_Pointer and Q = Null_Pointer, "Default pointers are null");
      Create_Plain (Integer'First, P);
      Assert (Deref (P) = (Integer'First, 0), "Create at an integer boundary");
      Create_Copy ((F => Integer'Last, G => -1), Q);
      Assert (P /= Q, "Separate creations have distinct identities");
      Assert
        (Deref (P) = (Integer'First, 0), "Creation preserves other cells");
      pragma Assert (Static => In_Memory (Model, P) and In_Memory (Model, Q));
      declare
         Alias : constant Pointer := P;
      begin
         Assert (Alias = P, "A pointer copy aliases its source");
         Assign (Alias, (F => 7, G => 8));
         Assert (Deref (P) = (7, 8), "Assignment is visible through aliases");
         Assert
           (Deref (Q) = (Integer'Last, -1),
            "Assignment preserves distinct cells");
      end;
      Assign (P, Deref (P));
      Assert (Deref (P) = (7, 8), "Assignment of the current value");
      Create_Copy ((F => 0, G => 0), P);
      Assert (Deref (P) = (0, 0), "Creation replaces an existing pointer");
      Assert
        (Deref (Q) = (Integer'Last, -1), "Replacement preserves other cells");
      Q := P;
      P := Null_Pointer;
      Assert (P = Null_Pointer, "A pointer can be reset to null");
      Assert (Deref (Q) = (0, 0), "An alias retains the cell after a reset");
   end Test_Plain;

   procedure Test_Owning is
      use Owning_Pointers;
      use Owning_Ops;
      P, Q     : Pointer;
      Original : Owning_Object := (D => new Integer'(42));
   begin
      Create_Copy (Original, P);
      Original.D.all := -42;
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert
           (C.D /= null and then C.D.all = 42,
            "Create_Copy duplicates owned data");
         C.D.all := 43;
         Free (C.D);
      end;
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert
           (C.D /= null and then C.D.all = 42,
            "Deref returns an independent copy");
         Free (C.D);
      end;
      Assign (P, Original);
      Reclaim (Original);
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert
           (C.D /= null and then C.D.all = -42,
            "Assign duplicates owned data");
         Free (C.D);
      end;
      Assign (P, (D => null));
      declare
         C : Owning_Object := Deref (P);
      begin
         Assert (C.D = null, "Assign and Deref of a null owned value");
         Reclaim (C);
      end;
      Create_Copy ((D => null), Q);
      declare
         C : Owning_Object := Deref (Q);
      begin
         Assert (C.D = null, "Create_Copy of a null owned value");
         Reclaim (C);
      end;
      Create_Owning (0, Q);
      declare
         C : Owning_Object := Deref (Q);
      begin
         Assert (C.D /= null and then C.D.all = 0, "Create of owned data");
         Free (C.D);
      end;
   end Test_Owning;

   procedure Test_Handles is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      P, Q   : Pointer;
      H1, H2 : Strong_Handle;
      W1, W2 : Weak_Handle;
   begin
      --  Default handles have no validity contract; initialize before use

      H1 := Null_Strong_Handle;
      W1 := Null_Weak_Handle;
      Assert (Of_Strong_Handle (H1) = Null_Pointer, "Null strong handle");
      Q := Of_Weak_Handle (W1);
      Assert (Q = Null_Pointer, "Null weak handle");
      H2 := To_Strong_Handle (W1);
      Assert
        (Of_Strong_Handle (H2) = Null_Pointer, "Upgrade of a null handle");
      Assert
        (Owning_Live_Ops.Of_Weak_Handle (W1, P) = Null_Pointer,
         "Witnessed conversion of a null handle");
      H2 := Owning_Live_Ops.To_Strong_Handle (W1, P);
      Assert
        (Of_Strong_Handle (H2) = Null_Pointer,
         "Witnessed upgrade of a null handle");
      Create_Owning (8, P);
      Create_Owning (8, Q);
      H1 := To_Strong_Handle (P);
      H2 := To_Strong_Handle (Q);
      Assert
        (not Owning_Handle_Ops."=" (H1, H2),
         "Strong handles distinguish cells with equal values");
      W1 := To_Weak_Handle (H1);
      W2 := To_Weak_Handle (H2);
      Assert
        (not Owning_Handle_Ops."=" (W1, W2),
         "Weak handles distinguish cells with equal values");
      H2 := H1;
      Assert
        (Owning_Handle_Ops."=" (H1, H2), "Copied strong handles are equal");
      W2 := To_Weak_Handle (P);
      Assert (Owning_Handle_Ops."=" (W1, W2), "Equivalent weak conversions");
      W2 := W1;
      Assert (Owning_Handle_Ops."=" (W1, W2), "Copied weak handles are equal");
      Assert (Of_Strong_Handle (H2) = P, "Strong handle round trip");
      Assert
        (Owning_Live_Ops.Of_Weak_Handle (W1, P) = P,
         "Witnessed weak conversion");
      H2 := Owning_Live_Ops.To_Strong_Handle (W1, P);
      Assert (Of_Strong_Handle (H2) = P, "Witnessed strong conversion");
      Q := Of_Weak_Handle (W2);
      Assert (Q = P or Q = Null_Pointer, "Unwitnessed weak conversion");
      H2 := To_Strong_Handle (W2);
      Assert
        (Of_Strong_Handle (H2) = P or Of_Strong_Handle (H2) = Null_Pointer,
         "Unwitnessed weak upgrade");
      P := Null_Pointer;
      declare
         C : Owning_Object := Owning_Ops.Deref (Of_Strong_Handle (H1));
      begin
         Assert
           (C.D /= null and then C.D.all = 8,
            "A strong handle retains access to its value");
         Free (C.D);
      end;
   end Test_Handles;

   procedure Test_Weak_Edges is
      use Cyclic_Pointers;
      use Cyclic_Handle_Ops;
      use Cyclic_Ops;
   begin
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
            Assert
              (Deref (P).Value = 6 and Deref (Q).Value = 7,
               "Adding edges preserves payloads");
            Assert
              (Of_Strong_Handle (Deref (P).Next) = Q,
               "A strong forward edge designates its target");
            Assert
              (Cyclic_Handle_Ops."=" (Deref (Q).Prev, To_Weak_Handle (P)),
               "A weak back edge designates its target");
         end;
         declare
            Child : constant Pointer := Of_Strong_Handle (Deref (P).Next);
         begin
            Assert
              (Deref (Child).Value = 7,
               "A strong forward edge retains access to its target");
            Assert
              (Cyclic_Handle_Ops."=" (Deref (Child).Prev, To_Weak_Handle (P)),
               "The child retains its weak back edge");
         end;
      end;
      declare
         P : Pointer;
      begin
         Create_Cell (8, P);
         Assign (P, (Deref (P) with delta Prev => To_Weak_Handle (P)));
         Assert
           (Deref (P).Value = 8, "A weak self edge preserves the payload");
         Assert
           (Of_Strong_Handle (Deref (P).Next) = Null_Pointer,
            "A weak self edge preserves the null forward edge");
         Assert
           (Cyclic_Handle_Ops."=" (Deref (P).Prev, To_Weak_Handle (P)),
            "A weak self edge designates its own cell");
      end;
   end Test_Weak_Edges;

begin
   Test_Plain;
   Test_Owning;
   Test_Handles;
   Test_Weak_Edges;
end Test;
