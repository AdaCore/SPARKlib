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
--  structures represented inside an array. The cells of the structures are
--  stored in an array of type Memory_Type. Each cell designates the next cell
--  of its structure through the Next function, which returns either a valid
--  index in the array or the special value No_Index to mark the end of the
--  structure.

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

   --  A memory array is valid if it is indexed from Index_Type'First and the
   --  Next value of each of its cells is either a valid index in the array or
   --  No_Index. Pinning the lower bound of valid memory arrays is what allows
   --  the lemmas below to relate two memory arrays of different lengths: the
   --  shorter one is then necessarily a prefix of the longer one.

   function Valid_Memory (M : Memory_Type) return Boolean
   is (M'First = Index_Type'First
       and then (for all C of M => Next (C) in M'Range | No_Index))
   with Annotate => (GNATprove, Inline_For_Proof);

   package Big_Conversions is
      package Memory_Index_To_Big is new Signed_Conversions (Extended_Index);
      use Memory_Index_To_Big;
      function To_Big (X : Extended_Index) return Big_Integer
      renames Memory_Index_To_Big.To_Big_Integer;
   end Big_Conversions;
   use Big_Conversions;

   use Memory_Index_Sets;
   subtype Memory_Index_Set is Memory_Index_Sets.Set;

   use Memory_Index_Sequences;

   --  True if the structure starting at X in M is acyclic, that is, if
   --  following Next repeatedly from X eventually reaches No_Index

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

   --  The sequence of the memory indexes reachable from X in M. Beware that
   --  the sequence is ordered from the end of the structure to X: its first
   --  element is the last index of the structure, the one whose Next is
   --  No_Index, and its last element is X itself. This reverse order is what
   --  makes the model of a cell reachable from X a prefix of the model of X,
   --  so that segments of a structure can be expressed using "<=" and
   --  Range_Shifted on sequences.

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
   --
   --  The machinery works as follows. The Automatic_Instantiation annotation
   --  attaches a lemma to the function declared just before it, so that the
   --  axiom it provides is only available when that function occurs in the
   --  proof context. Each definition lemma below is attached to a Disclose_*
   --  function, whose only purpose is to be such a trigger. There are then two
   --  ways to bring a call to a Disclose_* function into the proof context:
   --
   --    * If Automatically_Instantiate_Definitions is True, the
   --      Lemma_Automatically_Instantiate_*_Def procedures declared above are
   --      themselves automatically instantiated as soon as Is_Acyclic,
   --      Reachable_Set, or Model occurs in the proof context, and their
   --      postconditions call the Disclose_* functions. Their preconditions
   --      make them useless if the flag is False.
   --
   --    * Otherwise, calling a Disclose_* procedure inside an entity brings
   --      the corresponding definitions into the proof context of that entity
   --      only, again through the call in its postcondition.
   --
   --  The Disclose_* functions are markers only; they always return True and
   --  are never meant to be called at runtime.

   procedure Disclose_Recursive_Definitions
   with
     Ghost => Static,
     Post  => Disclose_Is_Acyclic and Disclose_Reachable and Disclose_Model;
   --  Disclose the recursive definitions of Is_Acyclic, Reachable_Set, and
   --  Model for the verification of the enclosing entity. Prefer the
   --  individual Disclose_* procedures below when the proof context is already
   --  large: disclosing a definition which is not needed can be enough to make
   --  a difficult proof reach the prover time limit.

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
       and then Reachable_Set (Next (M (X)), M) <= Reachable_Set (X, M)
       and then
         Included_Except
           (Reachable_Set (X, M), Reachable_Set (Next (M (X)), M), X)
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
       and then Model (Next (M (X)), M) <= Model (X, M),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Model

   --  Useful lemmas about reachability

   procedure Lemma_Reachable_Is_Acyclic (X, Y : Index_Type; M : Memory_Type)
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
   --  All cells reachable from the head of an acyclic structure are heads of
   --  an acyclic structure.

   procedure Lemma_Reachable_Closed_By_Next
     (X : Extended_Index; M : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       X in M'Range | No_Index
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post               =>
       (for all Y of Reachable_Set (X, M) =>
          Next (M (Y)) = No_Index or else Reachable (X, M, Next (M (Y))));
   --  The set of cells reachable from X is closed under Next: the successor of
   --  a reachable cell is either No_Index or reachable from X too.

   procedure Lemma_Reachable_Antisymmetric (X, Z : Index_Type; M : Memory_Type)
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
   --  If X is the head of an acyclic structure, then X cannot be reachable
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
   --  If X is the head of an acyclic structure, Y is reachable from X, and Z
   --  is reachable from Y, then Z is reachable from X.

   procedure Lemma_Reachable_Ordered (X, Y, Z : Index_Type; M : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       X in M'Range
       and then Y in M'Range
       and then Z in M'Range
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Y)
       and then Reachable (X, M, Z),
     Post               => Reachable (Y, M, Z) or Reachable (Z, M, Y);
   --  If X is the head of an acyclic structure, and both Y and Z are reachable
   --  from X, then Y and Z occur one after the other in the structure: either
   --  Z is reachable from Y or Y is reachable from Z.

   procedure Lemma_Reachable_Included (X, Z : Index_Type; M : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
       X in M'Range
       and then Z in M'Range
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Z),
     Post  => Reachable_Set (Z, M) <= Reachable_Set (X, M);
   --  If Z is reachable from X, the cells reachable from Z are also reachable
   --  from X. Reformulation of the transitivity lemma.

   procedure Lemma_Model_Is_Prefix (X, Z : Index_Type; M : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
       X in M'Range
       and then Z in M'Range
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Z),
     Post  => Model (Z, M) <= Model (X, M);
   --  If Z is reachable from X, the model of X starts with the model of Z, as
   --  the cells reachable from Z are the last ones of the structure rooted at
   --  X.

   procedure Lemma_Model_Covers_Reachable (X : Extended_Index; M : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
       X in M'Range | No_Index
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post  =>
       (for all I of Reachable_Set (X, M) => Find (Model (X, M), I) > 0);
   --  The model of X contains all the cells reachable from X. The
   --  postcondition of Model only provides the other inclusion; as it also
   --  states that the model and the reachable set have the same length, this
   --  lemma additionally entails that the model contains each reachable cell
   --  exactly once.

   --  Lemmas used to compute the new values of Is_Acyclic, Reachable_Set, and
   --  Model after a change in the memory array. They come in three flavors:
   --  the preservation of a whole structure, the preservation of a segment of
   --  a structure (the _Until lemmas), and the update of the Next value of a
   --  single cell (the _After_Set lemmas). All the lemmas of a given flavor
   --  share the same hypotheses on the old and new memory arrays M1 and M2.
   --
   --  Only the three _Preserved_Until lemmas are primitive. Every other lemma
   --  about the effect of a memory change is a corollary of them: the
   --  _Preserved lemmas are the case Y = No_Index, and the _After_Set lemmas
   --  combine a _Preserved_Until on the segment going from X to Y with a
   --  _Preserved on the structure rooted at Z.
   --  The corollaries are provided because they are both easier to find and
   --  easier to use than the general versions.

   procedure Lemma_Is_Acyclic_Preserved
     (X : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
       X in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) =>
            I <= M2'Last and then Next (M1 (I)) = Next (M2 (I))),
     Post  => Is_Acyclic (X, M2);
   --  If M2 preserves the Next value of all the cells reachable from X in M1,
   --  then the structure rooted at X is still acyclic in M2.

   procedure Lemma_Is_Acyclic_After_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
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
     Post  => Is_Acyclic (X, M2);
   --  If the Next value of a cell Y reachable from X is set to the head Z of a
   --  disjoint acyclic structure, then the structure rooted at X is still
   --  acyclic in M2. It is then made of the cells going from X to Y in M1
   --  followed by the cells of the structure rooted at Z in M1.

   procedure Lemma_Is_Acyclic_Preserved_Until
     (X, Y : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => (Length (Reachable_Set (X, M1)))),
     Pre                =>
       X in M1'Range | No_Index
       and then Y in M1'Range | No_Index
       and then Y /= X
       and then Y in M2'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then (Y = No_Index or else Reachable (X, M1, Y))
       and then
         (for all I of Reachable_Set (X, M1) =>
            (if not Reachable (Y, M1, I)
             then I <= M2'Last and then Next (M1 (I)) = Next (M2 (I)))),
     Post               => (if Is_Acyclic (Y, M2) then Is_Acyclic (X, M2));
   --  General version of Lemma_Is_Acyclic_Preserved. It is enough for M2 to
   --  preserve the Next value of the cells going from X up to Y, provided the
   --  structure rooted at Y is acyclic in M2.

   procedure Lemma_Reachable_Preserved
     (X : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
       X in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) =>
            I <= M2'Last and then Next (M1 (I)) = Next (M2 (I))),
     Post  =>
       Reachable_Set (X, M1) = Reachable_Set (X, M2)
       and then
         Length (Reachable_Set (X, M1)) = Length (Reachable_Set (X, M2));
   --  If M2 preserves the Next value of all the cells reachable from X in M1,
   --  then the same cells are reachable from X in M1 and M2. The equality of
   --  the lengths is stated on purpose: it does not follow from the equality
   --  of the sets, which is extensional.

   procedure Lemma_Reachable_After_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
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
     Post  =>
       (for all I of Reachable_Set (X, M2) =>
          Reachable (Z, M1, I)
          or else
            (Reachable (X, M1, I)
             and then not Reachable (Next (M1 (Y)), M1, I)))
       and then (for all I of Reachable_Set (Z, M1) => Reachable (X, M2, I))
       and then
         (for all I of Reachable_Set (X, M1) =>
            Reachable (X, M2, I) or else Reachable (Next (M1 (Y)), M1, I))
       and then
         Length (Reachable_Set (X, M2))
         = Length (Reachable_Set (X, M1))
           - Length (Reachable_Set (Y, M1))
           + Length (Reachable_Set (Z, M1))
           + 1;
   --  If the Next value of a cell Y reachable from X is set to the head Z of a
   --  disjoint acyclic structure, then the cells reachable from X in M2 are
   --  those going from X to Y in M1, plus those reachable from Z in M1.

   procedure Lemma_Reachable_Preserved_Until
     (X, Y : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => (Length (Reachable_Set (X, M1)))),
     Pre                =>
       X in M1'Range | No_Index
       and then Y in M1'Range | No_Index
       and then Y /= X
       and then Y in M2'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then (Y = No_Index or else Reachable (X, M1, Y))
       and then
         (for all I of Reachable_Set (X, M1) =>
            (if not Reachable (Y, M1, I)
             then I <= M2'Last and then Next (M1 (I)) = Next (M2 (I)))),
     Post               =>
       (if Is_Acyclic (Y, M2)
        then
          Reachable_Set (Y, M2) <= Reachable_Set (X, M2)
          and then
            (for all I of Reachable_Set (X, M1) =>
               Reachable (Y, M1, I) or else Reachable (X, M2, I))
          and then
            (for all I of Reachable_Set (X, M2) =>
               Reachable (Y, M2, I)
               or else (Reachable (X, M1, I) and not Reachable (Y, M1, I)))
          and then
            Length (Reachable_Set (X, M2)) - Length (Reachable_Set (Y, M2))
            = Length (Reachable_Set (X, M1)) - Length (Reachable_Set (Y, M1)));
   --  General version of Lemma_Reachable_Preserved. If M2 preserves the Next
   --  value of the cells going from X up to Y and the structure rooted at Y is
   --  acyclic in M2, then the cells reachable from X in M2 are those reachable
   --  from Y in M2 plus the cells going from X to Y, which are unchanged.

   procedure Lemma_Model_Preserved (X : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
       X in M1'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) =>
            I <= M2'Last and then Next (M1 (I)) = Next (M2 (I))),
     Post  => Model (X, M1) = Model (X, M2);
   --  If M2 preserves the Next value of all the cells reachable from X in M1,
   --  then X has the same model in M1 and M2.

   procedure Lemma_Model_After_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost => Static,
     Pre   =>
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
     Post  =>
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
   --  If the Next value of a cell Y reachable from X is set to the head Z of a
   --  disjoint acyclic structure, then the model of X in M2 is the model of Z
   --  in M1, followed by Y, followed by the part of the model of X in M1 which
   --  comes after Y.

   procedure Lemma_Model_Preserved_Until
     (X, Y : Extended_Index; M1, M2 : Memory_Type)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => (Length (Reachable_Set (X, M1)))),
     Pre                =>
       X in M1'Range | No_Index
       and then Y in M1'Range | No_Index
       and then Y /= X
       and then Y in M2'Range | No_Index
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then (Y = No_Index or else Reachable (X, M1, Y))
       and then
         (for all I of Reachable_Set (X, M1) =>
            (if not Reachable (Y, M1, I)
             then I <= M2'Last and then Next (M1 (I)) = Next (M2 (I)))),
     Post               =>
       (if Is_Acyclic (Y, M2)
        then
          Model (Y, M2) <= Model (X, M2)
          and
            Length (Model (X, M2)) - Length (Model (Y, M2))
            = Length (Model (X, M1)) - Length (Model (Y, M1))
          and
            Range_Shifted
              (Model (X, M2),
               Model (X, M1),
               Last (Model (Y, M2)) + 1,
               Last (Model (X, M2)),
               Length (Model (Y, M1)) - Length (Model (Y, M2))));
   --  General version of Lemma_Model_Preserved. If M2 preserves the Next value
   --  of the cells going from X up to Y and the structure rooted at Y is
   --  acyclic in M2, then the model of X in M2 is the model of Y in M2
   --  followed by the part of the model of X in M1 which comes after Y.

end SPARK.Higher_Order.Reachability;
