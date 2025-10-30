with Ada.Text_IO;
with SPARK.Big_Integers;
with Inst; use Inst.Int_Vectors;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Last is
      X : Sequence;
   begin
      Assert (Last (X) = 0, "Last of empty sequence");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Last (X) = 10, "Last of non-empty sequence");
   end Test_Last;

   procedure Test_Get is
      X : Sequence;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Get (X, 5) = 5, "Get an element of a sequence");
   end Test_Get;

   procedure Test_Length is
      use SPARK.Big_Integers;
      X : Sequence;
   begin
      Assert (Length (X) = 0, "Length of empty sequence");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Length (X) = 10, "Length of non-empty sequence");
   end Test_Length;

   procedure Test_First is
   begin
      Assert (First = 1, "First index of a sequence");
   end Test_First;

   procedure Test_Eq is
      X, Y : Sequence;
   begin
      Assert (X = Y, """="" on empty sequences");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (X /= Y, """="" on sequences with different lengths");
      Y := X;
      Assert (X = Y, """="" on copied sequences");
      X := Add (X, 11);
      Y := Add (Y, 111);
      Assert (X = Y, """="" on sequences uses user-defined equality");
      X := Add (X, 12);
      Y := Add (Y, 22);
      Assert (X /= Y, """="" on different sequences");
   end Test_Eq;

   procedure Test_Lt is
      X, Y : Sequence;
   begin
      Assert (not (Y < X), """<"" on empty sequences");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Y < X and not (X < Y), """<"" on empty and non-empty sequences");
      Y := X;
      X := Add (X, 11);
      Assert (Y < X and not (X < Y), """<"" on copied sequences");
      Y := Add (Y, 111);
      X := Add (X, 12);
      Assert (Y < X and not (X < Y), """<"" on sequences uses user-defined equality");
      Y := Add (Y, 22);
      Assert (not (Y < X) and not (X < Y), """<"" on different sequences");
   end Test_Lt;

   procedure Test_Le is
      X, Y : Sequence;
   begin
      Assert (Y <= X, """<="" on empty sequences");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Y <= X and not (X <= Y), """<="" on sequences with different lengths");
      Y := X;
      Assert (Y <= X and X <= Y, """<="" on copied sequences");
      X := Add (X, 11);
      Y := Add (Y, 111);
      Assert (Y <= X and X <= Y, """<="" on sequences uses user-defined equality");
      X := Add (X, 12);
      Assert (Y <= X and not (X <= Y), """<="" on shorter sequences");
      Y := Add (Y, 22);
      Assert (not (Y <= X) and not (X <= Y), """<="" on different sequences");
   end Test_Le;

   procedure Test_Equivalent_Sequences is
      X, Y : Sequence;
   begin
      Assert (Equivalent_Sequences (X, Y), "Equivalent_Sequences on empty sequences");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (not Equivalent_Sequences (X, Y), "Equivalent_Sequences on sequences with different lengths");
      Y := X;
      Assert (Equivalent_Sequences (X, Y), "Equivalent_Sequences on copied sequences");
      X := Add (X, 11);
      Y := Add (Y, 21);
      Assert (Equivalent_Sequences (X, Y), "Equivalent_Sequences on sequences uses user-defined equivalence relation");
      X := Add (X, 12);
      Y := Add (Y, 113);
      Assert (not Equivalent_Sequences (X, Y), "Equivalent_Sequences on not equivalent sequences");
   end Test_Equivalent_Sequences;

   procedure Test_Contains is
      X : Sequence;
   begin
      Assert (not Contains (X, 1, 0, 5), "Contains on an empty sequence");
      for I in 1 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Contains (X, 1, 7, 5), "Contains on an element in the sequence");
      Assert (Contains (X, 1, 7, 15), "Contains on an element in the sequence modulo equivalence");
      Assert (not Contains (X, 1, 7, 9), "Contains on an element not in the sequence");
      Assert (not Contains (X, 3, 7, 1), "Contains on an element not in the subsequence");
   end Test_Contains;

   procedure Test_Find is
      X : Sequence;
   begin
      Assert (Find (X, 5) = 0, "Find on an empty sequence");
      for I in 1 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Find (X, 5) = 5, "Find on an element in the sequence");
      Assert (Find (X, 15) = 5, "Find on an element in the sequence modulo equivalence");
      Assert (Find (X, 9) = 0, "Find on an element not in the sequence");
   end Test_Find;

   procedure Test_Empty_Sequence is
      X : Sequence := Empty_Sequence;
   begin
      Assert (Last (X) = 0, "Empty_Sequence is empty");
   end Test_Empty_Sequence;

   procedure Test_Set is
      X : Sequence;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      X := Set (X, 5, 15);
      Assert (Get (X, 5) = 15, "Set updates the value at the supplied index");
      Assert (Get (X, 4) = 4 and Get (X, 6) = 6, "Set preserves other values");
      Assert (Last (X) = 10, "Set preserves last");
   end Test_Set;

   procedure Test_Add is
      X, Y : Sequence;

   begin
      --  Insertion at the end is optimized. Insert enough elements to trigger
      --  a resize.
      for I in 1 .. 150 loop
         X := Add (X, I);
         pragma Loop_Invariant (Last (X) = I);
         pragma Loop_Invariant (for all K in 1 .. I => Get (X, K) = K);
      end loop;
      Assert (Last (X) = 150, "Add at the end increments last");
      Assert (Get (X, 150) = 150, "Add at the end inserts the value at the end");
      Assert (Get (X, 1) = 1, "Add at the end preserves previous values");

      --  Insertion in the middle
      Y := Add (X, 5, 0);
      Assert (Get (Y, 5) = 0, "Add inserts the value at the supplied index");
      Assert (Get (Y, 4) = 4, "Add preserves previous values");
      Assert (Get (Y, 6) = 5, "Add slides other values");
      Assert (Last (Y) = 151, "Add increments last");
   end Test_Add;

   procedure Test_Remove is
      X : Sequence;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      X := Remove (X, 5);
      Assert (Last (X) = 9, "Remove decrements last");
      Assert (Get (X, 4) = 4, "Remove preserves previous values");
      Assert (Get (X, 5) = 6, "Remove slides other values");
   end Test_Remove;

   procedure Test_Quantification is
      X : Sequence;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert ((for all E of X => E /= 11), "Iteration primitives on sequences");
      Assert ((for some E of X => E = 5), "Iteration primitives on sequences, early exit");
   end Test_Quantification;

   procedure Test_Aggregate is
      X : Sequence := [1, 2, 3, 4, 5];
   begin
      Assert (Last (X) = 5, "Aggregate has expected length");
      Assert (Get (X, 1) = 1 and Get (X, 5) = 5, "Aggregate has expected elements");
   end Test_Aggregate;

begin
   Test_Last;
   Test_Get;
   Test_Length;
   Test_First;
   Test_Eq;
   Test_Lt;
   Test_Le;
   Test_Equivalent_Sequences;
   Test_Contains;
   Test_Find;
   Test_Empty_Sequence;
   Test_Set;
   Test_Add;
   Test_Remove;
   Test_Quantification;
   Test_Aggregate;
end Test;
