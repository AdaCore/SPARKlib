pragma Extensions_Allowed (On);

with Ada.Text_IO;
with SPARK.Big_Integers; use SPARK.Big_Integers;
with Inst;               use Inst;

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
      Empty : Pointer;
      P     : Pointer := Create_Plain ((F => 1, G => 2));
      Q     : Pointer := Null_Pointer;
   begin
      Assert (Empty = Null_Pointer, "Default pointer is null");
      Assert (Q = Null_Pointer, "Explicit null pointer");
      Assert (P /= Null_Pointer, "Create returns a non-null pointer");
      Assert (Constant_Reference (P).F = 1, "Deref of a fresh pointer");
      Assert (Constant_Reference (P).G = 2, "Deref of a fresh pointer");

      Q := P;
      Assert (Constant_Reference (Q).F = 1, "Deref through an assigned copy");
      Q := Q;
      Assert (Constant_Reference (Q).G = 2, "Self-assignment preserves value");
      Q := Create_Plain ((F => 3, G => 4));
      Assert (Constant_Reference (Q).F = 3, "Replace an existing pointer");
      Assert
        (Constant_Reference (P).F = 1, "Replacement preserves other copies");
      Q := P;
      P := Null_Pointer;
      Assert
        (Constant_Reference (Q).G = 2, "Copy survives clearing its source");

      declare
         R : constant Pointer := Q;
      begin
         Assert (Constant_Reference (R).F = 1, "Deref through a scoped copy");
      end;
      Assert (Constant_Reference (Q).F = 1, "Deref after a copy is dropped");

      Assert (Plain_Ops.Deref (Q).F = 1, "Deref copies the first field");
      Assert (Plain_Ops.Deref (Q).G = 2, "Deref copies the second field");

      declare
         R : constant Pointer := Plain_Ops.Create_Copy ((F => 3, G => 4));
      begin
         Assert
           (Constant_Reference (R).F = 3,
            "Create_Copy filled the first field");
         Assert
           (Constant_Reference (R).G = 4,
            "Create_Copy filled the second field");
         Assert
           (Constant_Reference (Q).F = 1, "Create_Copy preserves other cells");
      end;
   end Test_Plain;

   procedure Test_Owning is
      use Owning_Pointers;
      O : Owning_Object := Make (42);
      P : constant Pointer := Owning_Ops.Create_Copy (O);
      Q : Pointer := Create_Owning (7);
   begin
      Assert (Constant_Reference (P).D /= null, "Create_Copy owns an integer");
      Assert
        (Constant_Reference (P).D.all = 42, "Create_Copy preserves contents");
      O.D.all := 99;
      Assert (Constant_Reference (P).D.all = 42, "Create_Copy is independent");
      Reclaim (O);
      Assert (O.D = null, "Reclaim clears the original object");

      declare
         D : Owning_Object := Owning_Ops.Deref (P);
      begin
         Assert (D.D /= null, "Deref owns an integer");
         Assert (D.D.all = 42, "Deref preserves contents");
         D.D.all := -1;
         Assert (Constant_Reference (P).D.all = 42, "Deref is independent");
         Reclaim (D);
      end;

      Q := P;
      Assert (Constant_Reference (Q).D.all = 42, "Replace an owning pointer");
      Q := Null_Pointer;
      Assert
        (Constant_Reference (P).D.all = 42, "Clearing a copy preserves P");

      declare
         R : constant Pointer := Owning_Ops.Create_Copy ((D => null));
         D : Owning_Object := Owning_Ops.Deref (R);
      begin
         Assert
           (Constant_Reference (R).D = null, "Copy of an empty owning object");
         Assert (D.D = null, "Deref of an empty owning object");
         Reclaim (D);
      end;
   end Test_Owning;

   procedure Test_Handle is
      use Owning_Pointers;
      use Owning_Handles;
      use Owning_Handle_Ops;
      P : Pointer := Create_Owning (7);
      H : Handle := To_Handle (P);
      N : Handle := Null_Handle;
   begin
      Assert
        (Of_Handle (N) = Null_Pointer, "Null_Handle designates Null_Pointer");
      Assert
        (Of_Handle (To_Handle (Null_Pointer)) = Null_Pointer,
         "Null pointer round trip");
      Assert
        (Constant_Reference (Of_Handle (H)).D.all = 7,
         "Pointer round trip through a handle");
      pragma
        Assert (Static => Owning_Handle_Ops.Extensional_Eq (H, To_Handle (P)));

      declare
         H2 : constant Handle := H;
         H3 : Handle := To_Handle (Create_Owning (9));
      begin
         H3 := H2;
         Assert
           (Constant_Reference (Of_Handle (H3)).D.all = 7,
            "Replace a handle with a copy");
         N := H3;
      end;
      P := Null_Pointer;
      H := Null_Handle;
      Assert
        (Constant_Reference (Of_Handle (N)).D.all = 7,
         "Handle copy outlives the original pointer and handle");
      N := Null_Handle;
      Assert (Of_Handle (N) = Null_Pointer, "Clear the last handle");
   end Test_Handle;

   procedure Test_Variant is
      use List_Pointers;
      use List_Handle_Ops;
      T : constant Pointer := Create_Cell ((Value => 3, Next => Null_Handle));
      M : constant Pointer :=
        Create_Cell ((Value => 2, Next => To_Handle (T)));
      H : constant Pointer :=
        Create_Cell ((Value => 1, Next => To_Handle (M)));
   begin
      Assert (Count (Null_Pointer) = 0, "Count of the empty chain");
      Assert (Count (T) = 1, "Count of a singleton chain");
      Assert (Count (M) = 2, "Count of a two-cell chain");
      Assert (Count (H) = 3, "Count of a three-cell chain");
      pragma Assert (Static => Sum (H) = 6);
   end Test_Variant;

   procedure Test_Multiway_Variant is
      use Tree_Pointers;
      use Tree_Handle_Ops;
      Leaf : constant Pointer :=
        Create_Node
          ((Value => 1, Arity => 0, Children => (others => Null_Handle)));
      Stem : constant Pointer :=
        Create_Node
          ((Value    => 2,
            Arity    => 1,
            Children => (1 => To_Handle (Leaf), others => Null_Handle)));
      Root : constant Pointer :=
        Create_Node
          ((Value    => 3,
            Arity    => 3,
            Children =>
              (1 => To_Handle (Stem),
               2 => To_Handle (Leaf),
               3 => Null_Handle)));
   begin
      Assert (Tree_Count (Null_Pointer) = 0, "Count of an empty tree");
      Assert (Tree_Count (Leaf) = 1, "Count of a leaf");
      Assert (Tree_Count (Stem) = 2, "Count of a single-child tree");
      Assert (Tree_Count (Root) = 4, "Count of a branching tree");
      Assert
        (Tree_Next (Constant_Reference (Leaf), 1) = null,
         "A leaf has no first way");
      Assert
        (Tree_Next (Constant_Reference (Stem), 2) = null,
         "A missing way returns null");
      Assert
        (Tree_Next (Constant_Reference (Root), 3) /= null,
         "An existing way can hold a null handle");
      Assert
        (Of_Handle (Tree_Next (Constant_Reference (Root), 3).all)
         = Null_Pointer,
         "A null child terminates a branch");
   end Test_Multiway_Variant;

begin
   Test_Plain;
   Test_Owning;
   Test_Handle;
   Test_Variant;
   Test_Multiway_Variant;
end Test;
