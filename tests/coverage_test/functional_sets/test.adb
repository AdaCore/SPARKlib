with Ada.Text_IO;
with SPARK.Big_Integers;
with Inst; use Inst.Int_Sets;
with SPARK.Containers.Functional.Sets;

procedure Test with SPARK_Mode is

   procedure Assert (B : Boolean; S : String) with
     Pre => B;
   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Contains is
      X : Set;
   begin
      Assert (not Contains (X, 5), "Contains on empty sequence");
      for I in 1 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Contains (X, 5) and Contains (X, 105), "Contains on element of the set");
      Assert (not Contains (X, 9) and not Contains (X, 109), "Contains on element not in the set");
   end Test_Contains;

   procedure Test_Choose is
      X : Set;
   begin
      for I in 1 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Contains (X, Choose (X)), "Choose returns an element in the set");
   end Test_Choose;

   procedure Test_Length is
      use SPARK.Big_Integers;
      X : Set;
   begin
      Assert (Length (X) = 0, "Length of empty set");
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Length (X) = 10, "Length of non-empty set");
   end Test_Length;

   procedure Test_Le is
      X, Y : Set;
   begin
      Assert (Y <= X, """<="" on empty sets");
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Y <= X and not (X <= Y), """<="" on sets with different lengths");
      Y := X;
      Assert (Y <= X and X <= Y, """<="" on copied sets");
      X := Add (X, 1);
      Y := Add (Y, 101);
      Assert (Y <= X and X <= Y, """<="" on sets uses element equivalence");
      X := Add (X, 2);
      Assert (Y <= X and not (X <= Y), """<="" on smaller sets");
      Y := Add (Y, 103);
      Assert (not (Y <= X) and not (X <= Y), """<="" on different sets");
   end Test_Le;

   procedure Test_Eq is
      X, Y : Set;
   begin
      Assert (X = Y, """="" on empty sets");
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (X /= Y, """="" on sets with different lengths");
      Y := X;
      Assert (X = Y, """="" on copied sets");
      X := Add (X, 1);
      Y := Add (Y, 101);
      Assert (X = Y, """="" on sets uses element equivalence");
      X := Add (X, 2);
      Y := Add (Y, 103);
      Assert (X /= Y, """="" on different sets");
   end Test_Eq;

   procedure Test_Is_Empty is
      X : Set;
   begin
      Assert (Is_Empty (X), "Is_Empty on empty set");
      X := Add (X, 1);
      Assert (not Is_Empty (X), "Is_Empty on non-empty set");
   end Test_Is_Empty;

   procedure Test_Included_Except is
      X, Y : Set;
   begin
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Y := X;
      X := Add (X, 102);
      Y := Add (Y, 103);
      Assert (Included_Except (X, Y, 2), "Included_Except returns True");
      Assert (not Included_Except (X, Y, 5), "Included_Except returns False");
   end Test_Included_Except;

   procedure Test_Includes_Intersection is
      X, Y, Z : Set;
   begin
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Y := X;
      Z := X;
      X := Add (X, 102);
      Y := Add (Y, 103);
      Assert (Includes_Intersection (Z, X, Y), "Includes_Intersection returns True");
      Z := Remove (Z, 5);
      Assert (not Includes_Intersection (Z, X, Y), "Includes_Intersection returns False");
   end Test_Includes_Intersection;

   procedure Test_Included_In_Union is
      X, Y, Z : Set;
   begin
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      for I in 2 .. 5 loop
         Y := Add (Y, I);
      end loop;
      for I in 3 .. 6 loop
         Z := Add (Z, I);
      end loop;
      Assert (Included_In_Union (Z, X, Y), "Included_In_Union returns True");
      Z := Add (Z, 9);
      Assert (not Included_In_Union (Z, X, Y), "Included_In_Union returns False");
   end Test_Included_In_Union;

   procedure Test_Is_Singleton is
      X : Set;
   begin
      Assert (not Is_Singleton (X, 2), "Is_Singleton on empty set");
      X := Add (X, 102);
      Assert (Is_Singleton (X, 2), "Is_Singleton on singleton");
      X := Add (X, 103);
      Assert (not Is_Singleton (X, 3), "Is_Singleton on set with more than 1 element");
   end Test_Is_Singleton;

   procedure Test_Not_In_Both is
      X, Y, Z : Set;
   begin
      for I in 4 .. 6 loop
         X := Add (X, I);
      end loop;
      for I in 1 .. 3 loop
         Y := Add (Y, I);
      end loop;
      for I in 2 .. 5 loop
         Z := Add (Z, I);
      end loop;
      Assert (Not_In_Both (Z, X, Y), "Not_In_Both no overlap");
      X := Add (X, 101);
      Assert (Not_In_Both (Z, X, Y), "Not_In_Both no overlap in Container");
      X := Add (X, 102);
      Assert (not Not_In_Both (Z, X, Y), "Not_In_Both overlap");
   end Test_Not_In_Both;

   procedure Test_No_Overlap is
      X, Y : Set;
   begin
      for I in 4 .. 6 loop
         X := Add (X, I);
      end loop;
      for I in 1 .. 3 loop
         Y := Add (Y, I);
      end loop;
      Assert (No_Overlap (X, Y), "No_Overlap returns True");
      X := Add (X, 101);
      Assert (not No_Overlap (X, Y), "No_Overlap returns False");
   end Test_No_Overlap;

   procedure Test_Num_Overlaps is
      use SPARK.Big_Integers;
      X, Y : Set;
   begin
      Assert (Num_Overlaps (X, Y) = 0, "Num_Overlap on empty sets");
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Num_Overlaps (X, Y) = 0 and Num_Overlaps (Y, X) = 0, "Num_Overlap on empty and non-empty sets");
      for I in 4 .. 5 loop
         Y := Add (Y, I);
      end loop;
      Assert (Num_Overlaps (X, Y) = 2 and Num_Overlaps (Y, X) = 2, "Num_Overlap on included sets");
      for I in 2 .. 3 loop
         Y := Add (Y, I);
      end loop;
      Assert (Num_Overlaps (X, Y) = 2 and Num_Overlaps (Y, X) = 2, "Num_Overlap on non-included sets");
      for I in 4 .. 5 loop
         Y := Remove (Y, I);
      end loop;
      Assert (Num_Overlaps (X, Y) = 0 and Num_Overlaps (Y, X) = 0, "Num_Overlap on disjoint sets");
   end Test_Num_Overlaps;

   procedure Test_Empty_Set is
      use SPARK.Big_Integers;
      X : Set := Empty_Set;
   begin
      Assert (Length (X) = 0 and not Contains (X, 1), "Empty_Set is empty");
   end Test_Empty_Set;

   procedure Test_Add is
      use SPARK.Big_Integers;
      X, Y : Set;

   begin
      X := Add (X, 1);
      X := Add (X, 2);
      Assert (Length (X) = 2, "Add increments length");
      Assert (Contains (X, 102), "Add new element is in the set");
      Assert (Contains (X, 101), "Add previous elements are preserved");
   end Test_Add;

   procedure Test_Remove is
      use SPARK.Big_Integers;
      X : Set;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      X := Remove (X, 5);
      Assert (Length (X) = 9, "Remove decrements length");
      Assert (not Contains (X, 105), "Remove removes the equivalence class");
      Assert (Contains (X, 103) and not Contains (X, 111), "Remove reserves other values");
   end Test_Remove;

   procedure Test_Intersection is
      X, Y, Z : Set;
   begin
      Assert (Is_Empty (Intersection (X, Y)), "Intersection on empty sets");
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Is_Empty (Intersection (X, Y)) and Is_Empty (Intersection (Y, X)), "Intersection on empty and non-empty sets");
      for I in 4 .. 5 loop
         Y := Add (Y, I);
      end loop;
      Assert (Intersection (X, Y) = Y and Intersection (Y, X) = Y, "Intersection on included sets");
      Z := Y;
      for I in 2 .. 3 loop
         Y := Add (Y, I);
      end loop;
      Assert (Intersection (X, Y) = Z and Intersection (Y, X) = Z, "Intersection on non-included sets");
      for I in 4 .. 5 loop
         Y := Remove (Y, I);
      end loop;
      Assert (Is_Empty (Intersection (X, Y)) and Is_Empty (Intersection (Y, X)), "Intersection on disjoint sets");
   end Test_Intersection;

   procedure Test_Union is
      X, Y, Z : Set;
   begin
      Assert (Is_Empty (Union (X, Y)), "Union on empty sets");
      for I in 4 .. 7 loop
         X := Add (X, I);
      end loop;
      Assert (Union (X, Y) = X and Union (Y, X) = X, "Union on empty and non-empty sets");
      for I in 4 .. 5 loop
         Y := Add (Y, I);
      end loop;
      Assert (Union (X, Y) = X and Union (Y, X) = X, "Union on included sets");
      Z := X;
      for I in 2 .. 3 loop
         Y := Add (Y, I);
         Z := Add (Z, I);
      end loop;
      Assert (Union (X, Y) = Z and Union (Y, X) = Z, "Union on non-included sets");
      for I in 4 .. 5 loop
         Y := Remove (Y, I);
      end loop;
      Assert (Union (X, Y) = Z and Union (Y, X) = Z, "Union on disjoint sets");
   end Test_Union;

   procedure Test_Iteration is
      B : Boolean;
      X : Set;
   begin
      for I in 1 .. 10 loop
         X := Add (X, I);
      end loop;
      Assert (Get_Set (Iterate (X)) = X, "Get_Set on iterator");
      for E of Iterate (X) loop
         Assert (Contains (X, E), "iteration only covers elements of the set");
      end loop;
      B := False;
      for S in Iterate (X) loop
         pragma Loop_Invariant (B = not Contains (S, 5));
         if Inst.Equivalent (Choose (S), 5) then
            B := True;
         end if;
      end loop;
      Assert (B, "iteration covers all elements of the set");
   end Test_Iteration;

   procedure Test_Aggregate is
      use SPARK.Big_Integers;
      X : Set := [1, 2, 3, 4, 5];
   begin
      Assert (Length (X) = 5, "Aggregate has expected length");
      Assert (Contains (X, 1) and Contains (X, 105) and not Contains (X, 7), "Aggregate has expected elements");
   end Test_Aggregate;

begin
   Test_Contains;
   Test_Choose;
   Test_Length;
   Test_Le;
   Test_Eq;
   Test_Is_Empty;
   Test_Included_Except;
   Test_Includes_Intersection;
   Test_Included_In_Union;
   Test_Is_Singleton;
   Test_Not_In_Both;
   Test_No_Overlap;
   Test_Num_Overlaps;
   Test_Empty_Set;
   Test_Add;
   Test_Remove;
   Test_Intersection;
   Test_Union;
   Test_Iteration;
   Test_Aggregate;
end Test;
