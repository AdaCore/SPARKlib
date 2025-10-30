with Ada.Text_IO;
with SPARK.Big_Integers;
with Inst; use Inst.Int_Maps;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Has_Key is
      X : Map;
   begin
      Assert (not Has_Key (X, 5), "Has_Key on empty map");
      for I in 1 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (Has_Key (X, 5) and Has_Key (X, 105), "Has_Key on key of the map");
      Assert (not Has_Key (X, 9) and not Has_Key (X, 109), "Has_Key on key not in the map");
   end Test_Has_Key;

   procedure Test_Get is
      X : Map;
   begin
      for I in 1 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (Get (X, 5) = 5 and Get (X, 105) = 5, "Get works modulo equivalence on keys");
   end Test_Get;

   procedure Test_Choose is
      X : Map;
   begin
      for I in 1 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (Has_Key (X, Choose (X)), "Choose returns a key in the map");
   end Test_Choose;

   procedure Test_Length is
      use SPARK.Big_Integers;
      X : Map;
   begin
      Assert (Length (X) = 0, "Length of empty map");
      for I in 1 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (Length (X) = 7, "Length of non-empty map");
   end Test_Length;

   procedure Test_Le is
      X, Y, Z : Map;
   begin
      Assert (Y <= X, """<="" on empty maps");
      for I in 5 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (Y <= X and not (X <= Y), """<="" on maps with different lengths");
      Y := X;
      Assert (Y <= X and X <= Y, """<="" on copied maps");
      X := Add (X, 1, 1);
      Y := Add (Y, 101, 1);
      Assert (Y <= X and X <= Y, """<="" on maps uses equivalence on keys");
      X := Add (X, 2, 2);
      Y := Add (Y, 2, 1002);
      Assert (Y <= X and X <= Y, """<="" on maps uses equality on elements");
      X := Add (X, 3, 3);
      Assert (Y <= X and not (X <= Y), """<="" on smaller maps");
      Z := Y;
      Y := Add (Y, 104, 3);
      Assert (not (Y <= X) and not (X <= Y), """<="" on maps with different keys");
      Z := Add (Z, 103, 103);
      Assert (not (Z <= X) and not (X <= Z), """<="" on maps with different elements");
   end Test_Le;

   procedure Test_Eq is
      X, Y, Z : Map;
   begin
      Assert (X = Y, """="" on empty maps");
      for I in 5 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (X /= Y, """="" on maps with different lengths");
      Y := X;
      Assert (X = Y, """="" on copied maps");
      X := Add (X, 1, 1);
      Y := Add (Y, 101, 1);
      Assert (X = Y, """="" on maps uses equivalence on keys");
      X := Add (X, 2, 2);
      Y := Add (Y, 2, 1002);
      Assert (X = Y, """="" on maps uses equality on elements");
      X := Add (X, 3, 3);
      Z := Y;
      Y := Add (Y, 104, 3);
      Assert (X /= Y, """="" on maps with different keys");
      Z := Add (Z, 103, 103);
      Assert (X /= Z, """="" on maps with different elements");
   end Test_Eq;

   procedure Test_Is_Empty is
      X : Map;
   begin
      Assert (Is_Empty (X), "Is_Empty on empty map");
      X := Add (X, 1, 1);
      Assert (not Is_Empty (X), "Is_Empty on non-empty map");
   end Test_Is_Empty;

   procedure Test_Keys_Included is
      X, Y : Map;
   begin
      Assert (Keys_Included (X, Y), "Keys_Included on empty maps");
      for I in 4 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Y := X;
      Assert (Keys_Included (X, Y) and Keys_Included (Y, X), "Keys_Included on maps with same keys");
      X := Add (X, 1, 1);
      Y := Add (Y, 101, 42);
      Assert (Keys_Included (X, Y) and Keys_Included (Y, X), "Keys_Included on maps with equivalent keys");
      X := Add (X, 102, 0);
      Assert (not Keys_Included (X, Y) and Keys_Included (Y, X), "Keys_Included on smaller map");
      Y := Add (Y, 103, 0);
      Assert (not Keys_Included (X, Y) and not Keys_Included (Y, X), "Keys_Included on distinct map");
   end Test_Keys_Included;

   procedure Test_Same_Keys is
      X, Y : Map;
   begin
      Assert (Same_Keys (X, Y), "Same_Keys on empty maps");
      for I in 4 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (not Same_Keys (X, Y), "Same_Keys on maps with different lengths");
      Y := X;
      Assert (Same_Keys (X, Y), "Same_Keys on copied maps");
      Y := Set (X, 4, 0);
      Assert (Same_Keys (X, Y), "Same_Keys on maps with different elements");
      X := Add (X, 1, 1);
      Y := Add (Y, 101, 1);
      Assert (Same_Keys (X, Y), "Same_Keys on maps uses equivalence on keys");
      X := Add (X, 2, 2);
      Y := Add (Y, 103, 2);
      Assert (not Same_Keys (X, Y), "Same_Keys on maps with different keys");
   end Test_Same_Keys;

   procedure Test_Keys_Included_Except is
      X, Y : Map;
   begin
      for I in 4 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Y := X;
      X := Add (X, 102, 0);
      Y := Add (Y, 103, 0);
      Assert (Keys_Included_Except (X, Y, 2), "Keys_Included_Except returns True");
      Assert (not Keys_Included_Except (X, Y, 5), "Keys_Included_Except returns False");
   end Test_Keys_Included_Except;

   procedure Test_Keys_Included_Except_2 is
      X, Y : Map;
   begin
      for I in 4 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Y := X;
      X := Add (X, 101, 0);
      X := Add (X, 102, 0);
      Y := Add (Y, 103, 0);
      Assert (Keys_Included_Except (X, Y, 1, 2), "Keys_Included_Except returns True");
      Assert (not Keys_Included_Except (X, Y, 1, 5), "Keys_Included_Except returns False");
   end Test_Keys_Included_Except_2;

   procedure Test_Equivalent_Maps is
      X, Y, Z : Map;
   begin
      Assert (Equivalent_Maps (X, Y), "Equivalent_Maps on empty maps");
      for I in 5 .. 7 loop
         X := Add (X, I, I);
      end loop;
      Assert (not Equivalent_Maps (X, Y), "Equivalent_Maps on maps with different lengths");
      Y := X;
      Assert (Equivalent_Maps (X, Y), "Equivalent_Maps on copied maps");
      X := Add (X, 1, 1);
      Y := Add (Y, 101, 1);
      Assert (Equivalent_Maps (X, Y), "Equivalent_Maps on maps uses equivalence on keys");
      X := Add (X, 2, 2);
      Y := Add (Y, 2, 102);
      Assert (Equivalent_Maps (X, Y), "Equivalent_Maps on maps uses equivalence on elements");
      X := Add (X, 3, 3);
      Z := Y;
      Y := Add (Y, 104, 3);
      Assert (not Equivalent_Maps (X, Y), "Equivalent_Maps on maps with different keys");
      Z := Add (Z, 103, 4);
      Assert (not Equivalent_Maps (X, Z), "Equivalent_Maps on maps with different elements");
   end Test_Equivalent_Maps;

   procedure Test_Empty_Map is
      use SPARK.Big_Integers;
      X : Map := Empty_Map;
   begin
      Assert (Length (X) = 0 and not Has_Key (X, 1), "Empty_Map is empty");
   end Test_Empty_Map;

   procedure Test_Add is
      use SPARK.Big_Integers;
      X : Map;

   begin
      X := Add (X, 1, 1);
      X := Add (X, 2, 2);
      Assert (Length (X) = 2, "Add increments length");
      Assert (Has_Key (X, 102), "Add new key is in the map");
      Assert (Get (X, 102) = 2, "Add new key is mapped to new element");
      Assert (Has_Key (X, 101) and Get (X, 101) = 1, "Add, previous mappings are preserved");
      Assert (not Has_Key (X, 103), "Add, other keys are not introduced");
   end Test_Add;

   procedure Test_Remove is
      use SPARK.Big_Integers;
      X : Map;
   begin
      for I in 1 .. 7 loop
         X := Add (X, I, I);
      end loop;
      X := Remove (X, 105);
      Assert (Length (X) = 6, "Remove decrements length");
      Assert (not Has_Key (X, 5), "Remove removes the equivalence class");
      Assert (Has_Key (X, 103) and then Get (X, 103) = 3, "Remove, previous mappings are preserved");
      Assert (not Has_Key (X, 108), "Remove, other keys are not introduced");
   end Test_Remove;

   procedure Test_Set is
      use SPARK.Big_Integers;
      X : Map;
   begin
      for I in 1 .. 7 loop
         X := Add (X, I, I);
      end loop;
      X := Set (X, 105, 42);
      Assert (Length (X) = 7, "Set preserves length");
      Assert (Has_Key (X, 5) and then Get (X, 5) = 42, "Set maps the key to the new element");
      Assert (Has_Key (X, 103) and then Get (X, 103) = 3, "Set, previous mappings are preserved");
      Assert (not Has_Key (X, 108), "Set, other keys are not introduced");
   end Test_Set;

   procedure Test_Iteration is
      B : Boolean;
      X : Map;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I, 0);
      end loop;
      Assert (Get_Map (Iterate (X)) = X, "Get_Map on iterator");
      for K of Iterate (X) loop
         Assert (Has_Key (X, K), "iteration only covers keys of the map");
      end loop;
      B := False;
      for M in Iterate (X) loop
         pragma Loop_Invariant (B = not Has_Key (M, 5));
         if Inst.Equivalent (Choose (M), 5) then
            B := True;
         end if;
      end loop;
      Assert (B, "iteration covers all keys of the map");
   end Test_Iteration;

   procedure Test_Aggregate is
      use SPARK.Big_Integers;
      X : Map := [1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5];
   begin
      Assert (Length (X) = 5, "Aggregate has expected length");
      Assert (Has_Key (X, 1) and Has_Key (X, 105) and not Has_Key (X, 7), "Aggregate has expected keys");
      Assert (Get (X, 1) = 1 and Get (X, 105) = 5, "Aggregate has expected elements");
   end Test_Aggregate;

begin
   Test_Has_Key;
   Test_Get;
   Test_Choose;
   Test_Length;
   Test_Le;
   Test_Eq;
   Test_Is_Empty;
   Test_Keys_Included;
   Test_Same_Keys;
   Test_Keys_Included_Except;
   Test_Keys_Included_Except_2;
   Test_Equivalent_Maps;
   Test_Empty_Map;
   Test_Add;
   Test_Remove;
   Test_Set;
   Test_Iteration;
   Test_Aggregate;
end Test;
