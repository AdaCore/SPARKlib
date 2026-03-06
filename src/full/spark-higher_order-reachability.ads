--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;

--  This package provides functions and lemmas to reason about linked
--  structures represented inside an array.

generic
   type Index_Type is range <>;
   No_Index : Index_Type'Base;
   type Cell_Type is private;
   type Memory_Type is array (Index_Type range <>) of Cell_Type;
   with function Next (C : Cell_Type) return Index_Type'Base;

   with package Memory_Index_Sets is new
     SPARK.Containers.Functional.Sets (Index_Type);

   with package Memory_Index_Sequences is new
     SPARK.Containers.Functional.Infinite_Sequences
       (Index_Type,
        Use_Logical_Equality => True);

   Automatically_Instantiate_Definitions : Boolean := True;
   --  Set to True to instantiate lemmas giving the recursive definitions of
   --  Is_Acyclic, Reachable_Set, and Model automatically. While useful in
   --  general, these lemmas might lead to instantiation loops, causing the
   --  context to grow too much for complex proofs. If automatic instantiation
   --  is disabled, the definition lemmas can either be instantiated manually
   --  or pulled into the proof context for the verification of specific
   --  subprograms by calling the Disclose_* functions or procedures.

package SPARK.Higher_Order.Reachability with SPARK_Mode, Always_Terminates
is

   pragma Assert (No_Index not in Index_Type);
   --  No_Index should not be a valid index

   subtype Extended_Index is Index_Type'Base;

   function Valid_Memory (M : Memory_Type) return Boolean
   is (M'First = Index_Type'First
       and then (for all C of M => Next (C) in M'Range | No_Index))
   with Annotate => (GNATprove, Inline_For_Proof);

   package Big_Conversions is
      package Memory_Index_To_Big is new Signed_Conversions (Extended_Index);
      use Memory_Index_To_Big;
      function To_Big (X : Extended_Index'Base) return Big_Integer
      renames Memory_Index_To_Big.To_Big_Integer;
   end Big_Conversions;
   use Big_Conversions;

   use Memory_Index_Sets;
   subtype Memory_Index_Set is Memory_Index_Sets.Set;

   use Memory_Index_Sequences;

   --  The list starting at X in M represents an acyclic list

   function Is_Acyclic (X : Extended_Index; M : Memory_Type) return Boolean
   with
     Pre  => X in M'Range | No_Index and then Valid_Memory (M),
     Post => (Static => (if X = No_Index then Is_Acyclic'Result));

   procedure Lemma_Automatically_Instantiate_Is_Acyclic_Def
   with
     Ghost    => Static,
     Pre      => Automatically_Instantiate_Definitions,
     Post     => Disclose_Is_Acyclic,
     Annotate => (GNATprove, Automatic_Instantiation);

   --  The set of reachable memory indexes from X in M

   function Reachable_Set
     (X : Extended_Index; M : Memory_Type) return Memory_Index_Set
   with
     Pre  => X in M'Range | No_Index and then Valid_Memory (M),
     Post =>
       (Static =>
          (if X = No_Index
           then
             Is_Empty (Reachable_Set'Result)
             and then Length (Reachable_Set'Result) = 0
           else
             Contains (Reachable_Set'Result, X)
             and then
               Length (Reachable_Set'Result)
               <= To_Big (M'Last) - To_Big (M'First) + 1)
          and then (for all I of Reachable_Set'Result => I in M'Range));

   procedure Lemma_Automatically_Instantiate_Reachable_Def
   with
     Ghost    => Static,
     Pre      => Automatically_Instantiate_Definitions,
     Post     => Disclose_Reachable,
     Annotate => (GNATprove, Automatic_Instantiation);

   function Reachable
     (X : Extended_Index; M : Memory_Type; Y : Index_Type) return Boolean
   is (Contains (Reachable_Set (X, M), Y))
   with
     Pre      =>
       X in M'Range | No_Index and then Y in M'Range and then Valid_Memory (M),
     Annotate => (GNATprove, Inline_For_Proof);

   --  The sequence of memory indexes starting from X in M in the order in
   --  which they occur.

   function Model (X : Extended_Index; M : Memory_Type) return Sequence
   with
     Pre  =>
       X in M'Range | No_Index
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post =>
       (Static =>
          Length (Model'Result) = Length (Reachable_Set (X, M))
          and then
            (for all I of Model'Result => Contains (Reachable_Set (X, M), I))
          and then
            (if X = No_Index
             then Length (Model'Result) = 0
             else
               In_Range
                 (Length (Model'Result),
                  To_Big (1),
                  To_Big (M'Last) - To_Big (M'First) + 1)
               and then Get (Model'Result, Last (Model'Result)) = X));

   procedure Lemma_Automatically_Instantiate_Model_Def
   with
     Ghost    => Static,
     Pre      => Automatically_Instantiate_Definitions,
     Post     => Disclose_Model,
     Annotate => (GNATprove, Automatic_Instantiation);

   --  Lemmas giving the recursive definitions of Is_Acyclic, Reachable_Set,
   --  and Model if they are not automatically instantiated by default. They
   --  can either be instantiated manually or get pulled into the proof context
   --  for the verification of a specific entity by calling the Disclose_*
   --  subprograms.

   procedure Disclose_Recursive_Definitions
   with
     Ghost => Static,
     Post  => Disclose_Is_Acyclic and Disclose_Reachable and Disclose_Model;
   --  Disclose the recursive definitions of Is_Acyclic, Reachable_Set, and
   --  Model for the verification of the enclosing entity.

   procedure Disclose_Is_Acyclic
   with Ghost => Static, Post => Disclose_Is_Acyclic;
   --  Disclose the recursive definitions of Is_Acyclic for the verification of
   --  the enclosing entity.

   function Disclose_Is_Acyclic return Boolean
   is (True)
   with Ghost => Static, Post => True;

   procedure Lemma_Is_Acyclic_Def (X : Index_Type; M : Memory_Type)
   with
     Ghost    => Static,
     Pre      => X in M'Range and then Valid_Memory (M),
     Post     => Is_Acyclic (X, M) = Is_Acyclic (Next (M (X)), M),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Is_Acyclic

   procedure Disclose_Reachable
   with Ghost => Static, Post => Disclose_Reachable;
   --  Disclose the recursive definitions of Reachable_Set for the verification
   --  of the enclosing entity.

   function Disclose_Reachable return Boolean
   is (True)
   with Ghost => Static, Post => True;

   procedure Lemma_Reachable_Def (X : Index_Type; M : Memory_Type)
   with
     Ghost    => Static,
     Pre      =>
       X in M'Range and then Valid_Memory (M) and then Is_Acyclic (X, M),
     Post     =>
       not Contains (Reachable_Set (Next (M (X)), M), X)
       and then Reachable_Set (X, M) = Add (Reachable_Set (Next (M (X)), M), X)
       and then
         Length (Reachable_Set (X, M))
         = 1 + Length (Reachable_Set (Next (M (X)), M)),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Reachable_Set

   procedure Disclose_Model
   with Ghost => Static, Post => Disclose_Model;
   --  Disclose the recursive definitions of Model for the verification of the
   --  enclosing entity.

   function Disclose_Model return Boolean
   is (True)
   with Ghost => Static, Post => True;

   procedure Lemma_Model_Def (X : Index_Type; M : Memory_Type)
   with
     Ghost    => Static,
     Pre      =>
       X in M'Range and then Valid_Memory (M) and then Is_Acyclic (X, M),
     Post     =>
       Length (Model (X, M)) - 1 = Length (Model (Next (M (X)), M))
       and then Get (Model (X, M), Last (Model (X, M))) = X
       and then Model (Next (M (X)), M) <= Model (X, M),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Model

   --  Useful lemmas about reachability

   procedure Lemma_Reachable_Acyclic (X, Y : Index_Type; M : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       X in M'Range
       and then Y in M'Range
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Y),
     Post               => Is_Acyclic (Y, M);
   --  All cells reachable from the head of an acyclic list are heads of an
   --  acyclic list.

   procedure Lemma_Reachable_Antisym (X, Z : Index_Type; M : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       X in M'Range
       and then Z in M'Range
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post               =>
       (if Reachable (X, M, Z) and Reachable (Z, M, X) then X = Z);
   --  If X is the head of an acyclic list, then X cannot be reachable from an
   --  from a cell Z reachable from X unless Z is X itself.

   procedure Lemma_Reachable_Transitive (X, Y, Z : Index_Type; M : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       X in M'Range
       and then Y in M'Range
       and then Z in M'Range
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post               =>
       (if Reachable (X, M, Y) and Reachable (Y, M, Z)
        then Reachable (X, M, Z));
   --  If X is the head of an acyclic list, Y is reachable from X, and Z is
   --  reachable from Y, then Z is reachable from X.

   --  Lemmas used to compute the new values of Is_Acyclic, Reachable_Set, and
   --  Model after a change in the memory array.

   procedure Lemma_Is_Acyclic_Preserved
     (X : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => (Length (Reachable_Set (X, M1)))),
     Pre                =>
       X in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then M1'Last = M2'Last
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) => Next (M1 (I)) = Next (M2 (I))),
     Post               => Is_Acyclic (X, M2);
   --  Lemma for the preservation of the property if the Next elements of all
   --  cells reachable from X are preserved.

   procedure Lemma_Is_Acyclic_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       M1'Last = M2'Last
       and then X in M1'Range
       and then Y in M1'Range
       and then Z in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Next (M2 (Y)) = Z
       and then
         (for all K in M1'Range =>
            (if K /= Y then Next (M2 (K)) = Next (M1 (K))))
       and then Is_Acyclic (X, M1)
       and then Is_Acyclic (Z, M1)
       and then Reachable (X, M1, Y)
       and then not Reachable (Z, M1, Y),
     Post               => Is_Acyclic (X, M2);
   --  Lemma for the preservation of the property if the Next element of a cell
   --  Y reachable from X is set to a disjoint acyclic list Z.

   procedure Lemma_Reachable_Preserved
     (X : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => (Length (Reachable_Set (X, M1)))),
     Pre                =>
       M1'Last = M2'Last
       and then X in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) => Next (M1 (I)) = Next (M2 (I))),
     Post               =>
       Reachable_Set (X, M1) = Reachable_Set (X, M2)
       and then
         Length (Reachable_Set (X, M1)) = Length (Reachable_Set (X, M2));
   --  Lemma for the preservation of the property if the Next elements of all
   --  cells reachable from X are preserved.

   procedure Lemma_Reachable_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       M1'Last = M2'Last
       and then X in M1'Range
       and then Y in M1'Range
       and then Z in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Next (M2 (Y)) = Z
       and then
         (for all K in M1'Range =>
            (if K /= Y then Next (M2 (K)) = Next (M1 (K))))
       and then Is_Acyclic (X, M1)
       and then Is_Acyclic (Z, M1)
       and then Reachable (X, M1, Y)
       and then not Reachable (Z, M1, Y),
     Post               =>
       (for all I of Reachable_Set (X, M2) =>
          Reachable (Z, M1, I)
          or else
            (Reachable (X, M1, I)
             and then not Reachable (Next (M1 (Y)), M1, I)))
       and then (for all I of Reachable_Set (Z, M1) => Reachable (X, M2, I))
       and then
         (for all I of Reachable_Set (X, M1) =>
            Reachable (X, M2, I) or else Reachable (Next (M1 (Y)), M1, I));
   --  Lemma for the preservation of the property if the Next element of a cell
   --  Y reachable from X is set to a disjoint acyclic list Z.

   procedure Lemma_Model_Preserved (X : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       M1'Last = M2'Last
       and then X in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) => Next (M1 (I)) = Next (M2 (I))),
     Post               => Model (X, M1) = Model (X, M2);
   --  Lemma for the preservation of the property if the Next elements of all
   --  cells reachable from X are preserved.

   procedure Lemma_Model_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       M1'Last = M2'Last
       and then X in M1'Range
       and then Y in M1'Range
       and then Z in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Next (M2 (Y)) = Z
       and then
         (for all K in M1'Range =>
            (if K /= Y then Next (M2 (K)) = Next (M1 (K))))
       and then Is_Acyclic (X, M1)
       and then Is_Acyclic (Z, M1)
       and then Reachable (X, M1, Y)
       and then not Reachable (Z, M1, Y),
     Post               =>
       Model (Z, M1) <= Model (X, M2)
       and
         Length (Model (X, M2))
         = Length (Model (X, M1))
           - Length (Model (Y, M1))
           + Length (Model (Z, M1))
           + 1
       and
         Range_Shifted
           (Model (X, M2),
            Model (X, M1),
            Last (Model (Z, M1)) + 1,
            Last (Model (X, M2)),
            Length (Model (Y, M1)) - Length (Model (Z, M1)) - 1);
   --  Lemma for the preservation of the property if the Next element of a cell
   --  Y reachable from X is set to a disjoint acyclic list Z.

end SPARK.Higher_Order.Reachability;
