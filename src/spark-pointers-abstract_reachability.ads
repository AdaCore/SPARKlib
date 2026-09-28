--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;
with SPARK.Pointers.Abstract_Maps;

--  This package provides functions and lemmas to reason about linked
--  structures represented inside an abstract map. The cells of the structures
--  are stored in a map of type Memory_Maps.Map. Each cell designates the next
--  cell of its structure through the Next function, which returns either a
--  valid key in the map or the special value No_Key to mark the end of the
--  structure.
--
--  It is the counterpart, for the memory models of the pointer library, of
--  SPARK.Higher_Order.Reachability, which provides the same theory over an
--  array. The two specifications are deliberately kept as close to each other
--  as possible.

generic
   with package Memory_Maps is new SPARK.Pointers.Abstract_Maps (<>);

   with function "=" (Left, Right : Memory_Maps.Key_Type) return Boolean is <>;
   --  Equality on keys

   with
     function Next (O : Memory_Maps.Object_Type) return Memory_Maps.Key_Type
     with Ghost => Static;

   with package Key_Sets is new
     SPARK.Containers.Functional.Sets
       (Memory_Maps.Key_Type,
        --!format off
        "=") with Ghost => Static;
        --!format on

   with package Key_Sequences is new
     SPARK.Containers.Functional.Infinite_Sequences
       (Memory_Maps.Key_Type,
        "=",
        --!format off
        Use_Logical_Equality => True) with Ghost => Static;
        --!format on

   Automatically_Instantiate_Definitions : Boolean := True;
   --  Set to True to instantiate lemmas giving the recursive definitions of
   --  Is_Acyclic, Reachable_Set, and Model automatically. While useful in
   --  general, these lemmas might lead to instantiation loops, causing the
   --  context to grow too much for complex proofs. If automatic instantiation
   --  is disabled, the definition lemmas can either be instantiated manually
   --  or pulled into the proof context for the verification of specific
   --  subprograms by calling the Disclose_* functions or procedures.

package SPARK.Pointers.Abstract_Reachability with SPARK_Mode, Always_Terminates
is
   use Memory_Maps;
   use Key_Sets;
   use Key_Sequences;

   --  "=" should be the logical equality on keys. It is checked by the
   --  Key_Sequences formal package above, which is an instance over that same
   --  "=" with Use_Logical_Equality set, so nothing is needed here.

   function Domain (M : Memory_Maps.Map) return Key_Sets.Set
   with
     Ghost  => Static,
     Import,
     Global => null,
     Post   =>
       (for all K of Domain'Result => Has_Key (M, K))
       and then (for all K in M => Contains (Domain'Result, K));
   --  The set of keys of M. This function is deliberately left unproved: it is
   --  an assumption that any map has finitely many keys at any point, which
   --  cannot be established from Abstract_Maps, whose Map type is abstract and
   --  has no constructors. It holds for every memory model of the pointer
   --  library, where the domain of the map is the set of currently allocated
   --  cells.

   --  A memory map is valid if the Next value of each of its cells is either a
   --  valid key in the map or No_Key.

   function Valid_Memory (M : Memory_Maps.Map) return Boolean
   is (for all K in M =>
         Next (Get (M, K).all) = No_Key
         or else Has_Key (M, Next (Get (M, K).all)))
   with Ghost => Static, Annotate => (GNATprove, Inline_For_Proof);

   --  True if the structure starting at X in M is acyclic, that is, if
   --  following Next repeatedly from X eventually reaches No_Key

   function Is_Acyclic (X : Key_Type; M : Memory_Maps.Map) return Boolean
   with
     Ghost  => Static,
     Global => null,
     Pre    => (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M),
     Post   => (if X = No_Key then Is_Acyclic'Result);

   procedure Lemma_Automatically_Instantiate_Is_Acyclic_Def
   with
     Ghost    => Static,
     Global   => null,
     Pre      => Automatically_Instantiate_Definitions,
     Post     => Disclose_Is_Acyclic,
     Annotate => (GNATprove, Automatic_Instantiation);

   --  The set of reachable keys from X in M

   function Reachable_Set
     (X : Key_Type; M : Memory_Maps.Map) return Key_Sets.Set
   with
     Ghost  => Static,
     Global => null,
     Pre    => (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M),
     Post   =>
       (if X = No_Key
        then
          Is_Empty (Reachable_Set'Result)
          and then Length (Reachable_Set'Result) = 0
        else
          Contains (Reachable_Set'Result, X)
          and then Length (Reachable_Set'Result) <= Length (Domain (M)))
       and then (for all I of Reachable_Set'Result => Has_Key (M, I));

   procedure Lemma_Automatically_Instantiate_Reachable_Def
   with
     Ghost    => Static,
     Global   => null,
     Pre      => Automatically_Instantiate_Definitions,
     Post     => Disclose_Reachable,
     Annotate => (GNATprove, Automatic_Instantiation);

   function Reachable
     (X : Key_Type; M : Memory_Maps.Map; Y : Key_Type) return Boolean
   is (Contains (Reachable_Set (X, M), Y))
   with
     Ghost    => Static,
     Global   => null,
     Pre      =>
       (X = No_Key or else Has_Key (M, X))
       and then Has_Key (M, Y)
       and then Valid_Memory (M),
     Annotate => (GNATprove, Inline_For_Proof);

   --  The sequence of the keys reachable from X in M. Beware that the sequence
   --  is ordered from the end of the structure to X: its first element is the
   --  last key of the structure, the one whose Next is No_Key, and its last
   --  element is X itself. This reverse order is what makes the model of a
   --  cell reachable from X a prefix of the model of X, so that segments of a
   --  structure can be expressed using "<=" and Range_Shifted on sequences.

   function Model (X : Key_Type; M : Memory_Maps.Map) return Sequence
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       (X = No_Key or else Has_Key (M, X))
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post   =>
       Length (Model'Result) = Length (Reachable_Set (X, M))
       and then
         (for all I of Model'Result => Contains (Reachable_Set (X, M), I))
       and then
         (if X = No_Key
          then Length (Model'Result) = 0
          else
            In_Range (Length (Model'Result), 1, Length (Domain (M)))
            and then Get (Model'Result, Last (Model'Result)) = X);

   procedure Lemma_Automatically_Instantiate_Model_Def
   with
     Ghost    => Static,
     Global   => null,
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
     Ghost  => Static,
     Global => null,
     Post   => Disclose_Is_Acyclic and Disclose_Reachable and Disclose_Model;
   --  Disclose the recursive definitions of Is_Acyclic, Reachable_Set, and
   --  Model for the verification of the enclosing entity. Prefer the
   --  individual Disclose_* procedures below when the proof context is already
   --  large: disclosing a definition which is not needed can be enough to make
   --  a difficult proof reach the prover time limit.

   procedure Disclose_Is_Acyclic
   with Ghost => Static, Global => null, Post => Disclose_Is_Acyclic;
   --  Disclose the recursive definitions of Is_Acyclic for the verification of
   --  the enclosing entity.

   function Disclose_Is_Acyclic return Boolean
   is (True)
   with Ghost => Static, Global => null, Post => True;

   procedure Lemma_Is_Acyclic_Def (X : Key_Type; M : Memory_Maps.Map)
   with
     Ghost    => Static,
     Global   => null,
     Pre      => Has_Key (M, X) and then Valid_Memory (M),
     Post     => Is_Acyclic (X, M) = Is_Acyclic (Next (Get (M, X).all), M),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Is_Acyclic

   procedure Disclose_Reachable
   with Ghost => Static, Global => null, Post => Disclose_Reachable;
   --  Disclose the recursive definitions of Reachable_Set for the verification
   --  of the enclosing entity.

   function Disclose_Reachable return Boolean
   is (True)
   with Ghost => Static, Global => null, Post => True;

   procedure Lemma_Reachable_Def (X : Key_Type; M : Memory_Maps.Map)
   with
     Ghost    => Static,
     Global   => null,
     Pre      =>
       Has_Key (M, X) and then Valid_Memory (M) and then Is_Acyclic (X, M),
     Post     =>
       not Contains (Reachable_Set (Next (Get (M, X).all), M), X)
       and then
         Reachable_Set (Next (Get (M, X).all), M) <= Reachable_Set (X, M)
       and then
         Included_Except
           (Reachable_Set (X, M), Reachable_Set (Next (Get (M, X).all), M), X)
       and then
         Length (Reachable_Set (X, M))
         = 1 + Length (Reachable_Set (Next (Get (M, X).all), M)),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Reachable_Set

   procedure Disclose_Model
   with Ghost => Static, Global => null, Post => Disclose_Model;
   --  Disclose the recursive definitions of Model for the verification of the
   --  enclosing entity.

   function Disclose_Model return Boolean
   is (True)
   with Ghost => Static, Global => null, Post => True;

   procedure Lemma_Model_Def (X : Key_Type; M : Memory_Maps.Map)
   with
     Ghost    => Static,
     Global   => null,
     Pre      =>
       Has_Key (M, X) and then Valid_Memory (M) and then Is_Acyclic (X, M),
     Post     =>
       Length (Model (X, M)) - 1 = Length (Model (Next (Get (M, X).all), M))
       and then Model (Next (Get (M, X).all), M) <= Model (X, M),
     Annotate => (GNATprove, Automatic_Instantiation);
   --  Recursive definition of Model

   --  Useful lemmas about reachability

   procedure Lemma_Reachable_Is_Acyclic (X, Y : Key_Type; M : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       Has_Key (M, X)
       and then Has_Key (M, Y)
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Y),
     Post               => Is_Acyclic (Y, M);
   --  All cells reachable from the head of an acyclic structure are heads of
   --  an acyclic structure.

   procedure Lemma_Reachable_Closed_By_Next (X : Key_Type; M : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       (X = No_Key or else Has_Key (M, X))
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post               =>
       (for all Y of Reachable_Set (X, M) =>
          Next (Get (M, Y).all) = No_Key
          or else Reachable (X, M, Next (Get (M, Y).all)));
   --  The set of cells reachable from X is closed under Next: the successor of
   --  a reachable cell is either No_Key or reachable from X too.

   procedure Lemma_Reachable_Antisymmetric
     (X, Z : Key_Type; M : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       Has_Key (M, X)
       and then Has_Key (M, Z)
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post               =>
       (if Reachable (X, M, Z) and Reachable (Z, M, X) then X = Z);
   --  If X is the head of an acyclic structure, then X cannot be reachable
   --  from a cell Z reachable from X unless Z is X itself.

   procedure Lemma_Reachable_Transitive
     (X, Y, Z : Key_Type; M : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       Has_Key (M, X)
       and then Has_Key (M, Y)
       and then Has_Key (M, Z)
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post               =>
       (if Reachable (X, M, Y) and Reachable (Y, M, Z)
        then Reachable (X, M, Z));
   --  If X is the head of an acyclic structure, Y is reachable from X, and Z
   --  is reachable from Y, then Z is reachable from X.

   procedure Lemma_Reachable_Ordered (X, Y, Z : Key_Type; M : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M))),
     Pre                =>
       Has_Key (M, X)
       and then Has_Key (M, Y)
       and then Has_Key (M, Z)
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Y)
       and then Reachable (X, M, Z),
     Post               => Reachable (Y, M, Z) or Reachable (Z, M, Y);
   --  If X is the head of an acyclic structure, and both Y and Z are reachable
   --  from X, then Y and Z occur one after the other in the structure: either
   --  Z is reachable from Y or Y is reachable from Z.

   procedure Lemma_Reachable_Included (X, Z : Key_Type; M : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       Has_Key (M, X)
       and then Has_Key (M, Z)
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Z),
     Post   => Reachable_Set (Z, M) <= Reachable_Set (X, M);
   --  If Z is reachable from X, the cells reachable from Z are also reachable
   --  from X. Reformulation of the transitivity lemma.

   procedure Lemma_Model_Is_Prefix (X, Z : Key_Type; M : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       Has_Key (M, X)
       and then Has_Key (M, Z)
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M)
       and then Reachable (X, M, Z),
     Post   => Model (Z, M) <= Model (X, M);
   --  If Z is reachable from X, the model of X starts with the model of Z, as
   --  the cells reachable from Z are the last ones of the structure rooted at
   --  X.

   procedure Lemma_Model_Covers_Reachable (X : Key_Type; M : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       (X = No_Key or else Has_Key (M, X))
       and then Valid_Memory (M)
       and then Is_Acyclic (X, M),
     Post   =>
       (for all I of Reachable_Set (X, M) => Find (Model (X, M), I) > 0);
   --  The model of X contains all the cells reachable from X. The
   --  postcondition of Model only provides the other inclusion; as it also
   --  states that the model and the reachable set have the same length, this
   --  lemma additionally entails that the model contains each reachable cell
   --  exactly once.

   --  Lemmas used to compute the new values of Is_Acyclic, Reachable_Set, and
   --  Model after a change in the memory map. They come in three flavors:
   --  the preservation of a whole structure, the preservation of a segment of
   --  a structure (the _Until lemmas), and the update of the Next value of a
   --  single cell (the _After_Set lemmas). All the lemmas of a given flavor
   --  share the same hypotheses on the old and new memory maps M1 and M2.
   --
   --  Only the three _Preserved_Until lemmas are primitive. Every other lemma
   --  about the effect of a memory change is a corollary of them: the
   --  _Preserved lemmas are the case Y = No_Key, and the _After_Set lemmas
   --  combine a _Preserved_Until on the segment going from X to Y with a
   --  _Preserved on the structure rooted at Z.
   --  The corollaries are provided because they are both easier to find and
   --  easier to use than the general versions.

   function Same_Domain (M1, M2 : Memory_Maps.Map) return Boolean
   is ((for all K in M1 => Has_Key (M2, K))
       and then (for all K in M2 => Has_Key (M1, K)))
   with Ghost => Static, Annotate => (GNATprove, Inline_For_Proof);

   procedure Lemma_Is_Acyclic_Preserved
     (X : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       (X = No_Key or else Has_Key (M1, X))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) =>
            Has_Key (M2, I)
            and then Next (Get (M1, I).all) = Next (Get (M2, I).all)),
     Post   => Is_Acyclic (X, M2);
   --  If M2 preserves the Next value of all the cells reachable from X in M1,
   --  then the structure rooted at X is still acyclic in M2.

   procedure Lemma_Is_Acyclic_After_Set
     (X, Y, Z : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       Same_Domain (M1, M2)
       and then Has_Key (M1, X)
       and then Has_Key (M1, Y)
       and then (Z = No_Key or else Has_Key (M1, Z))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Next (Get (M2, Y).all) = Z
       and then
         (for all K in M1 =>
            (if K /= Y then Next (Get (M2, K).all) = Next (Get (M1, K).all)))
       and then Is_Acyclic (X, M1)
       and then Is_Acyclic (Z, M1)
       and then Reachable (X, M1, Y)
       and then not Reachable (Z, M1, Y),
     Post   => Is_Acyclic (X, M2);
   --  If the Next value of a cell Y reachable from X is set to the head Z of a
   --  disjoint acyclic structure, then the structure rooted at X is still
   --  acyclic in M2. It is then made of the cells going from X to Y in M1
   --  followed by the cells of the structure rooted at Z in M1.

   procedure Lemma_Is_Acyclic_Preserved_Until
     (X, Y : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       (X = No_Key or else Has_Key (M1, X))
       and then (Y = No_Key or else Has_Key (M1, Y))
       and then Y /= X
       and then (Y = No_Key or else Has_Key (M2, Y))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then (Y = No_Key or else Reachable (X, M1, Y))
       and then
         (for all I of Reachable_Set (X, M1) =>
            (if not Reachable (Y, M1, I)
             then
               Has_Key (M2, I)
               and then Next (Get (M1, I).all) = Next (Get (M2, I).all))),
     Post               => (if Is_Acyclic (Y, M2) then Is_Acyclic (X, M2));
   --  General version of Lemma_Is_Acyclic_Preserved. It is enough for M2 to
   --  preserve the Next value of the cells going from X up to Y, provided the
   --  structure rooted at Y is acyclic in M2.

   procedure Lemma_Reachable_Preserved (X : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       (X = No_Key or else Has_Key (M1, X))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) =>
            Has_Key (M2, I)
            and then Next (Get (M1, I).all) = Next (Get (M2, I).all)),
     Post   =>
       Reachable_Set (X, M1) = Reachable_Set (X, M2)
       and then
         Length (Reachable_Set (X, M1)) = Length (Reachable_Set (X, M2));
   --  If M2 preserves the Next value of all the cells reachable from X in M1,
   --  then the same cells are reachable from X in M1 and M2. The equality of
   --  the lengths is stated on purpose: it does not follow from the equality
   --  of the sets, which is extensional.

   procedure Lemma_Reachable_After_Set
     (X, Y, Z : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       Same_Domain (M1, M2)
       and then Has_Key (M1, X)
       and then Has_Key (M1, Y)
       and then (Z = No_Key or else Has_Key (M1, Z))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Next (Get (M2, Y).all) = Z
       and then
         (for all K in M1 =>
            (if K /= Y then Next (Get (M2, K).all) = Next (Get (M1, K).all)))
       and then Is_Acyclic (X, M1)
       and then Is_Acyclic (Z, M1)
       and then Reachable (X, M1, Y)
       and then not Reachable (Z, M1, Y),
     Post   =>
       (for all I of Reachable_Set (X, M2) =>
          Reachable (Z, M1, I)
          or else
            (Reachable (X, M1, I)
             and then not Reachable (Next (Get (M1, Y).all), M1, I)))
       and then (for all I of Reachable_Set (Z, M1) => Reachable (X, M2, I))
       and then
         (for all I of Reachable_Set (X, M1) =>
            Reachable (X, M2, I)
            or else Reachable (Next (Get (M1, Y).all), M1, I))
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
     (X, Y : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       (X = No_Key or else Has_Key (M1, X))
       and then (Y = No_Key or else Has_Key (M1, Y))
       and then Y /= X
       and then (Y = No_Key or else Has_Key (M2, Y))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then (Y = No_Key or else Reachable (X, M1, Y))
       and then
         (for all I of Reachable_Set (X, M1) =>
            (if not Reachable (Y, M1, I)
             then
               Has_Key (M2, I)
               and then Next (Get (M1, I).all) = Next (Get (M2, I).all))),
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

   procedure Lemma_Model_Preserved (X : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       (X = No_Key or else Has_Key (M1, X))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then
         (for all I of Reachable_Set (X, M1) =>
            Has_Key (M2, I)
            and then Next (Get (M1, I).all) = Next (Get (M2, I).all)),
     Post   => Model (X, M1) = Model (X, M2);
   --  If M2 preserves the Next value of all the cells reachable from X in M1,
   --  then X has the same model in M1 and M2.

   procedure Lemma_Model_After_Set
     (X, Y, Z : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost  => Static,
     Global => null,
     Pre    =>
       Same_Domain (M1, M2)
       and then Has_Key (M1, X)
       and then Has_Key (M1, Y)
       and then (Z = No_Key or else Has_Key (M1, Z))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Next (Get (M2, Y).all) = Z
       and then
         (for all K in M1 =>
            (if K /= Y then Next (Get (M2, K).all) = Next (Get (M1, K).all)))
       and then Is_Acyclic (X, M1)
       and then Is_Acyclic (Z, M1)
       and then Reachable (X, M1, Y)
       and then not Reachable (Z, M1, Y),
     Post   =>
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
     (X, Y : Key_Type; M1, M2 : Memory_Maps.Map)
   with
     Ghost              => Static,
     Global             => null,
     Subprogram_Variant => (Decreases => Length (Reachable_Set (X, M1))),
     Pre                =>
       (X = No_Key or else Has_Key (M1, X))
       and then (Y = No_Key or else Has_Key (M1, Y))
       and then Y /= X
       and then (Y = No_Key or else Has_Key (M2, Y))
       and then Valid_Memory (M1)
       and then Valid_Memory (M2)
       and then Is_Acyclic (X, M1)
       and then (Y = No_Key or else Reachable (X, M1, Y))
       and then
         (for all I of Reachable_Set (X, M1) =>
            (if not Reachable (Y, M1, I)
             then
               Has_Key (M2, I)
               and then Next (Get (M1, I).all) = Next (Get (M2, I).all))),
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

end SPARK.Pointers.Abstract_Reachability;
