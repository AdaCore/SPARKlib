--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with SPARK.Body_Mode;

package body SPARK.Pointers.Abstract_Reachability
  with SPARK_Mode => SPARK.Body_Mode.Enabled
is

   --  Local functions
   --
   --  They mirror the local functions of SPARK.Higher_Order.Reachability one
   --  for one.

   function Reachable_Set_Internal
     (X : Key_Type; M : Memory_Maps.Map; S : Key_Sets.Set) return Key_Sets.Set
   is (if X = No_Key or else not Contains (S, X)
       then Empty_Set
       else
         Add
           (Reachable_Set_Internal (Next (Get (M, X).all), M, Remove (S, X)),
            X))
   with
     Ghost              => Static,
     Pre                =>
       (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M),
     Subprogram_Variant => (Decreases => Length (S)),
     Post               =>
       Reachable_Set_Internal'Result <= S
       and then (for all Y of Reachable_Set_Internal'Result => Has_Key (M, Y));

   function Model_Internal
     (X : Key_Type; M : Memory_Maps.Map; S : Key_Sets.Set) return Sequence
   is (if X = No_Key or else not Contains (S, X)
       then Empty_Sequence
       else Add (Model_Internal (Next (Get (M, X).all), M, Remove (S, X)), X))
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (S)),
     Pre                =>
       (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M),
     Post               =>
       Length (Reachable_Set_Internal (X, M, S))
       = Length (Model_Internal'Result)
       and then
         (for all Y of Reachable_Set_Internal (X, M, S) =>
            Find (Model_Internal'Result, Y) > 0)
       and then
         (for all I in Model_Internal'Result =>
            Contains
              (Reachable_Set_Internal (X, M, S),
               Get (Model_Internal'Result, I)));

   function Is_Acyclic_Internal
     (X : Key_Type; M : Memory_Maps.Map; S : Key_Sets.Set) return Boolean
   is (X = No_Key
       or else
         (Length (Model_Internal (X, M, S)) > 0
          and then
            Next (Get (M, Get (Model_Internal (X, M, S), 1)).all) = No_Key))
   with
     Ghost => Static,
     Pre   => (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M);

   function Model_Internal (X : Key_Type; M : Memory_Maps.Map) return Sequence
   is (Model_Internal (X, M, Domain (M)))
   with
     Ghost => Static,
     Pre   => (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M);

   function Is_Acyclic_Internal
     (X : Key_Type; M : Memory_Maps.Map) return Boolean
   is (Is_Acyclic_Internal (X, M, Domain (M)))
   with
     Ghost => Static,
     Pre   => (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M);

   function Reachable_Set_Internal
     (X : Key_Type; M : Memory_Maps.Map) return Key_Sets.Set
   is (Reachable_Set_Internal (X, M, Domain (M)))
   with
     Ghost => Static,
     Pre   => (X = No_Key or else Has_Key (M, X)) and then Valid_Memory (M);

   --  Local Lemmas

   procedure Lemma_Length_Included (A, B : Key_Sets.Set)
   with Ghost => Static, Pre => A <= B, Post => Length (A) <= Length (B);
   --  Set inclusion entails an ordering on lengths

   procedure Lemma_Model_Internal_Inc
     (X : Key_Type; M : Memory_Maps.Map; S1, S2 : Key_Sets.Set)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (S1)),
     Pre                =>
       (X = No_Key or else Has_Key (M, X))
       and then Valid_Memory (M)
       and then S1 <= S2,
     Post               =>
       (if Is_Acyclic_Internal (X, M, S1)
        then Model_Internal (X, M, S1) = Model_Internal (X, M, S2));

   procedure Lemma_Model_Internal_Cut
     (X, Y : Key_Type; M : Memory_Maps.Map; S : Key_Sets.Set)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (S)),
     Pre                =>
       Has_Key (M, X)
       and then Has_Key (M, Y)
       and then Valid_Memory (M)
       and then Contains (S, Y),
     Post               =>
       (if Is_Acyclic_Internal (X, M, S)
        then
          Model_Internal (X, M, S) = Model_Internal (X, M, Remove (S, Y))
          or Model_Internal (Y, M, S) <= Model_Internal (X, M, S));

   -------------------------
   -- Disclose_Is_Acyclic --
   -------------------------

   procedure Disclose_Is_Acyclic is null;

   --------------------
   -- Disclose_Model --
   --------------------

   procedure Disclose_Model is null;

   ------------------------
   -- Disclose_Reachable --
   ------------------------

   procedure Disclose_Reachable is null;

   ------------------------------------
   -- Disclose_Recursive_Definitions --
   ------------------------------------

   procedure Disclose_Recursive_Definitions is null;

   ----------------
   -- Is_Acyclic --
   ----------------

   function Is_Acyclic (X : Key_Type; M : Memory_Maps.Map) return Boolean
   with Refined_Post => Is_Acyclic'Result = Is_Acyclic_Internal (X, M)
   is
   begin
      return Is_Acyclic_Internal (X, M);
   end Is_Acyclic;

   ----------------------------------------------------
   -- Lemma_Automatically_Instantiate_Is_Acyclic_Def --
   ----------------------------------------------------

   procedure Lemma_Automatically_Instantiate_Is_Acyclic_Def is null;

   -----------------------------------------------
   -- Lemma_Automatically_Instantiate_Model_Def --
   -----------------------------------------------

   procedure Lemma_Automatically_Instantiate_Model_Def is null;

   ---------------------------------------------------
   -- Lemma_Automatically_Instantiate_Reachable_Def --
   ---------------------------------------------------

   procedure Lemma_Automatically_Instantiate_Reachable_Def is null;

   --------------------------------
   -- Lemma_Is_Acyclic_After_Set --
   --------------------------------

   procedure Lemma_Is_Acyclic_After_Set
     (X, Y, Z : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      if X /= Y then
         Lemma_Is_Acyclic_Preserved_Until (X, Y, M1, M2);
      end if;
      Lemma_Is_Acyclic_Preserved (Z, M1, M2);
   end Lemma_Is_Acyclic_After_Set;

   --------------------------
   -- Lemma_Is_Acyclic_Def --
   --------------------------

   procedure Lemma_Is_Acyclic_Def (X : Key_Type; M : Memory_Maps.Map) is
   begin
      if Next (Get (M, X).all) /= No_Key then
         Lemma_Model_Internal_Inc
           (Next (Get (M, X).all), M, Remove (Domain (M), X), Domain (M));
         Lemma_Model_Internal_Cut (Next (Get (M, X).all), X, M, Domain (M));
      end if;
   end Lemma_Is_Acyclic_Def;

   --------------------------------
   -- Lemma_Is_Acyclic_Preserved --
   --------------------------------

   procedure Lemma_Is_Acyclic_Preserved
     (X : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      if X /= No_Key then
         Lemma_Is_Acyclic_Preserved_Until (X, No_Key, M1, M2);
      end if;
   end Lemma_Is_Acyclic_Preserved;

   --------------------------------------
   -- Lemma_Is_Acyclic_Preserved_Until --
   --------------------------------------

   procedure Lemma_Is_Acyclic_Preserved_Until
     (X, Y : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      if Y /= No_Key then
         Lemma_Reachable_Antisymmetric (X, Y, M1);
      end if;
      if Next (Get (M1, X).all) /= Y then
         Lemma_Is_Acyclic_Preserved_Until (Next (Get (M1, X).all), Y, M1, M2);
      end if;
   end Lemma_Is_Acyclic_Preserved_Until;

   ---------------------------
   -- Lemma_Length_Included --
   ---------------------------

   procedure Lemma_Length_Included (A, B : Key_Sets.Set) is
   begin
      pragma Assert (Num_Overlaps (A, B) = Length (A));
   end Lemma_Length_Included;

   ---------------------------
   -- Lemma_Model_After_Set --
   ---------------------------

   procedure Lemma_Model_After_Set
     (X, Y, Z : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Reachable_Is_Acyclic (X, Y, M1);
      Lemma_Is_Acyclic_After_Set (X, Y, Z, M1, M2);
      Lemma_Model_Is_Prefix (X, Y, M1);
      if X /= Y then
         Lemma_Model_Preserved_Until (X, Y, M1, M2);
      end if;
      Lemma_Is_Acyclic_Preserved (Z, M1, M2);
      Lemma_Model_Preserved (Z, M1, M2);
   end Lemma_Model_After_Set;

   ----------------------------------
   -- Lemma_Model_Covers_Reachable --
   ----------------------------------

   procedure Lemma_Model_Covers_Reachable (X : Key_Type; M : Memory_Maps.Map)
   is null;

   ---------------------
   -- Lemma_Model_Def --
   ---------------------

   procedure Lemma_Model_Def (X : Key_Type; M : Memory_Maps.Map) is
   begin
      Lemma_Model_Internal_Inc
        (Next (Get (M, X).all), M, Remove (Domain (M), X), Domain (M));
   end Lemma_Model_Def;

   ------------------------------
   -- Lemma_Model_Internal_Cut --
   ------------------------------

   procedure Lemma_Model_Internal_Cut
     (X, Y : Key_Type; M : Memory_Maps.Map; S : Key_Sets.Set) is
   begin
      if Next (Get (M, X).all) /= No_Key and X /= Y and Contains (S, X) then
         Lemma_Model_Internal_Cut (Next (Get (M, X).all), Y, M, Remove (S, X));

         --  The two calls below are used to show that removing X and Y from S
         --  in either order gives the same model, as Remove does not commute
         --  syntactically.

         Lemma_Model_Internal_Inc
           (Next (Get (M, X).all),
            M,
            Remove (Remove (S, X), Y),
            Remove (Remove (S, Y), X));
         Lemma_Model_Internal_Inc
           (Next (Get (M, X).all),
            M,
            Remove (Remove (S, Y), X),
            Remove (Remove (S, X), Y));
         Lemma_Model_Internal_Inc (Y, M, Remove (S, X), S);
      end if;
   end Lemma_Model_Internal_Cut;

   ------------------------------
   -- Lemma_Model_Internal_Inc --
   ------------------------------

   procedure Lemma_Model_Internal_Inc
     (X : Key_Type; M : Memory_Maps.Map; S1, S2 : Key_Sets.Set) is
   begin
      if X /= No_Key and then Contains (S1, X) then
         Lemma_Model_Internal_Inc
           (Next (Get (M, X).all), M, Remove (S1, X), Remove (S2, X));
      end if;
   end Lemma_Model_Internal_Inc;

   ---------------------------
   -- Lemma_Model_Is_Prefix --
   ---------------------------

   procedure Lemma_Model_Is_Prefix (X, Z : Key_Type; M : Memory_Maps.Map) is
   begin
      Lemma_Reachable_Is_Acyclic (X, Z, M);
      if Z /= X then
         Lemma_Model_Preserved_Until (X, Z, M, M);
      end if;
   end Lemma_Model_Is_Prefix;

   ---------------------------
   -- Lemma_Model_Preserved --
   ---------------------------

   procedure Lemma_Model_Preserved (X : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Lemma_Is_Acyclic_Preserved (X, M1, M2);
      if X /= No_Key then
         Lemma_Model_Preserved_Until (X, No_Key, M1, M2);
      end if;
   end Lemma_Model_Preserved;

   ---------------------------------
   -- Lemma_Model_Preserved_Until --
   ---------------------------------

   procedure Lemma_Model_Preserved_Until
     (X, Y : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Is_Acyclic_Preserved_Until (X, Y, M1, M2);
      if Y /= No_Key then
         Lemma_Reachable_Antisymmetric (X, Y, M1);
      end if;
      if Y /= No_Key then
         Lemma_Reachable_Is_Acyclic (X, Y, M1);
      end if;
      if Y /= Next (Get (M1, X).all) then
         Lemma_Model_Preserved_Until (Next (Get (M1, X).all), Y, M1, M2);
         pragma
           Assert
             (if Is_Acyclic (Y, M2)
              then
                (for all I in Model (X, M1) =>
                   (if I > Last (Model (Y, M1))
                    then
                      Get (Model (X, M1), I)
                      = Get
                          (Model (X, M2),
                           I - Last (Model (Y, M1)) + Last (Model (Y, M2))))));
      end if;
   end Lemma_Model_Preserved_Until;

   -------------------------------
   -- Lemma_Reachable_After_Set --
   -------------------------------

   procedure Lemma_Reachable_After_Set
     (X, Y, Z : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Reachable_Is_Acyclic (X, Y, M1);
      Lemma_Is_Acyclic_After_Set (X, Y, Z, M1, M2);
      if X /= Y then
         Lemma_Reachable_Preserved_Until (X, Y, M1, M2);
      end if;
      Lemma_Is_Acyclic_Preserved (Z, M1, M2);
      Lemma_Reachable_Preserved (Z, M1, M2);
   end Lemma_Reachable_After_Set;

   -----------------------------------
   -- Lemma_Reachable_Antisymmetric --
   -----------------------------------

   procedure Lemma_Reachable_Antisymmetric
     (X, Z : Key_Type; M : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      if X /= Z and Reachable (X, M, Z) and Reachable (Z, M, X) then
         Lemma_Reachable_Is_Acyclic (X, Z, M);
         Lemma_Reachable_Antisymmetric (Next (Get (M, X).all), Z, M);
         Lemma_Reachable_Transitive (Z, X, Next (Get (M, X).all), M);
      end if;
   end Lemma_Reachable_Antisymmetric;

   ------------------------------------
   -- Lemma_Reachable_Closed_By_Next --
   ------------------------------------

   procedure Lemma_Reachable_Closed_By_Next (X : Key_Type; M : Memory_Maps.Map)
   is
   begin
      Disclose_Recursive_Definitions;
      if X /= No_Key then
         Lemma_Reachable_Closed_By_Next (Next (Get (M, X).all), M);
      end if;
   end Lemma_Reachable_Closed_By_Next;

   -------------------------
   -- Lemma_Reachable_Def --
   -------------------------

   procedure Lemma_Reachable_Def (X : Key_Type; M : Memory_Maps.Map) is
   begin
      if Next (Get (M, X).all) /= No_Key then
         Lemma_Is_Acyclic_Def (X, M);
         Lemma_Model_Internal_Inc
           (Next (Get (M, X).all), M, Remove (Domain (M), X), Domain (M));
         pragma
           Assert
             (Reachable_Set (Next (Get (M, X).all), M)
              = Reachable_Set_Internal
                  (Next (Get (M, X).all), M, Remove (Domain (M), X)));
      end if;
   end Lemma_Reachable_Def;

   ------------------------------
   -- Lemma_Reachable_Included --
   ------------------------------

   procedure Lemma_Reachable_Included (X, Z : Key_Type; M : Memory_Maps.Map) is
   begin
      Lemma_Reachable_Is_Acyclic (X, Z, M);
      if Z /= X then
         Lemma_Reachable_Preserved_Until (X, Z, M, M);
      end if;
   end Lemma_Reachable_Included;

   --------------------------------
   -- Lemma_Reachable_Is_Acyclic --
   --------------------------------

   procedure Lemma_Reachable_Is_Acyclic (X, Y : Key_Type; M : Memory_Maps.Map)
   is
   begin
      Disclose_Recursive_Definitions;
      if X /= Y then
         Lemma_Reachable_Is_Acyclic (Next (Get (M, X).all), Y, M);
      end if;
   end Lemma_Reachable_Is_Acyclic;

   -----------------------------
   -- Lemma_Reachable_Ordered --
   -----------------------------

   procedure Lemma_Reachable_Ordered (X, Y, Z : Key_Type; M : Memory_Maps.Map)
   is
   begin
      Disclose_Recursive_Definitions;
      if X /= Y and X /= Z then
         Lemma_Reachable_Ordered (Next (Get (M, X).all), Y, Z, M);
      end if;
   end Lemma_Reachable_Ordered;

   -------------------------------
   -- Lemma_Reachable_Preserved --
   -------------------------------

   procedure Lemma_Reachable_Preserved (X : Key_Type; M1, M2 : Memory_Maps.Map)
   is
   begin
      Lemma_Is_Acyclic_Preserved (X, M1, M2);
      if X /= No_Key then
         Lemma_Reachable_Preserved_Until (X, No_Key, M1, M2);
      end if;
   end Lemma_Reachable_Preserved;

   -------------------------------------
   -- Lemma_Reachable_Preserved_Until --
   -------------------------------------

   procedure Lemma_Reachable_Preserved_Until
     (X, Y : Key_Type; M1, M2 : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Is_Acyclic_Preserved_Until (X, Y, M1, M2);
      if Y /= No_Key then
         Lemma_Reachable_Antisymmetric (X, Y, M1);
      end if;
      if Y /= Next (Get (M1, X).all) then
         Lemma_Reachable_Preserved_Until (Next (Get (M1, X).all), Y, M1, M2);
      end if;
   end Lemma_Reachable_Preserved_Until;

   --------------------------------
   -- Lemma_Reachable_Transitive --
   --------------------------------

   procedure Lemma_Reachable_Transitive
     (X, Y, Z : Key_Type; M : Memory_Maps.Map) is
   begin
      Disclose_Recursive_Definitions;
      if X /= Y and Reachable (X, M, Y) then
         Lemma_Reachable_Transitive (Next (Get (M, X).all), Y, Z, M);
      end if;
   end Lemma_Reachable_Transitive;

   -----------
   -- Model --
   -----------

   function Model (X : Key_Type; M : Memory_Maps.Map) return Sequence
   with
     Refined_Post =>
       Model'Result = Model_Internal (X, M)
       and then
         (if X /= No_Key
          then In_Range (Length (Model'Result), 0, Length (Domain (M))))
   is
   begin
      Lemma_Length_Included (Reachable_Set_Internal (X, M), Domain (M));
      return Model_Internal (X, M);
   end Model;

   -------------------
   -- Reachable_Set --
   -------------------

   function Reachable_Set
     (X : Key_Type; M : Memory_Maps.Map) return Key_Sets.Set
   with
     Refined_Post =>
       Reachable_Set'Result = Reachable_Set_Internal (X, M)
       and then
         Length (Reachable_Set'Result) = Length (Reachable_Set_Internal (X, M))
       and then Length (Reachable_Set'Result) <= Length (Domain (M))
   is
   begin
      Lemma_Length_Included (Reachable_Set_Internal (X, M), Domain (M));
      return Reachable_Set_Internal (X, M);
   end Reachable_Set;

end SPARK.Pointers.Abstract_Reachability;
