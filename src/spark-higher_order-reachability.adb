--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with SPARK.Big_Intervals; use SPARK.Big_Intervals;

package body SPARK.Higher_Order.Reachability
  with SPARK_Mode => Off --  #BODYMODE
is

   --  Local functions

   function All_Set (First, Last : Index_Type'Base) return Memory_Index_Set
   with
     Ghost => Static,
     Pre   =>
       Last < First or else (First in Index_Type and then Last in Index_Type),
     Post  =>
       Length (All_Set'Result)
       = (if Last < First then 0 else To_Big (Last) - To_Big (First) + 1)
       and then (for all I in First .. Last => Contains (All_Set'Result, I))
       and then (for all E of All_Set'Result => E in First .. Last);

   function Reachable_Set_Internal
     (X : Extended_Index; M : Memory_Type; S : Memory_Index_Set)
      return Memory_Index_Set
   is (if X = No_Index or else not Contains (S, X)
       then Empty_Set
       else Add (Reachable_Set_Internal (Next (M (X)), M, Remove (S, X)), X))
   with
     Ghost              => Static,
     Pre                => X in M'Range | No_Index and then Valid_Memory (M),
     Subprogram_Variant => (Decreases => Length (S)),
     Post               =>
       Reachable_Set_Internal'Result <= S
       and then (for all Y of Reachable_Set_Internal'Result => Y in M'Range);

   function Model_Internal
     (X : Extended_Index; M : Memory_Type; S : Memory_Index_Set)
      return Sequence
   is (if X = No_Index or else not Contains (S, X)
       then Empty_Sequence
       else Add (Model_Internal (Next (M (X)), M, Remove (S, X)), X))
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (S)),
     Pre                => X in M'Range | No_Index and then Valid_Memory (M),
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
     (X : Extended_Index; M : Memory_Type; S : Memory_Index_Set) return Boolean
   is (X = No_Index
       or else
         (Length (Model_Internal (X, M, S)) > 0
          and then Next (M (Get (Model_Internal (X, M, S), 1))) = No_Index))
   with
     Ghost => Static,
     Pre   => X in M'Range | No_Index and then Valid_Memory (M);

   function Model_Internal
     (X : Extended_Index; M : Memory_Type) return Sequence
   is (Model_Internal (X, M, All_Set (M'First, M'Last)))
   with
     Ghost => Static,
     Pre   => X in M'Range | No_Index and then Valid_Memory (M);

   function Is_Acyclic_Internal
     (X : Extended_Index; M : Memory_Type) return Boolean
   is (Is_Acyclic_Internal (X, M, All_Set (M'First, M'Last)))
   with
     Ghost => Static,
     Pre   => X in M'Range | No_Index and then Valid_Memory (M);

   function Reachable_Set_Internal
     (X : Extended_Index; M : Memory_Type) return Memory_Index_Set
   is (Reachable_Set_Internal (X, M, All_Set (M'First, M'Last)))
   with
     Ghost => Static,
     Pre   => X in M'Range | No_Index and then Valid_Memory (M);

   --  Local Lemmas

   procedure Lemma_Model_Internal_Inc
     (X : Extended_Index; M : Memory_Type; S1, S2 : Memory_Index_Set)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (S1)),
     Pre                =>
       X in M'Range | No_Index and then Valid_Memory (M) and then S1 <= S2,
     Post               =>
       (if Is_Acyclic_Internal (X, M, S1)
        then Model_Internal (X, M, S1) = Model_Internal (X, M, S2));

   procedure Lemma_Model_Internal_Cut
     (X, Y : Index_Type; M : Memory_Type; S : Memory_Index_Set)
   with
     Ghost              => Static,
     Subprogram_Variant => (Decreases => Length (S)),
     Pre                =>
       X in M'Range
       and then Y in M'Range
       and then Valid_Memory (M)
       and then Contains (S, Y),
     Post               =>
       (if Is_Acyclic_Internal (X, M, S)
        then
          Model_Internal (X, M, S) = Model_Internal (X, M, Remove (S, Y))
          or Model_Internal (Y, M, S) <= Model_Internal (X, M, S));

   -------------
   -- All_Set --
   -------------

   function All_Set (First, Last : Index_Type'Base) return Memory_Index_Set is
   begin
      return S : Memory_Index_Set do
         for I in First .. Last loop
            S := Add (S, I);
            pragma
              Loop_Invariant (Length (S) = To_Big (I) - To_Big (First) + 1);
            pragma Loop_Invariant (for all K in First .. I => Contains (S, K));
            pragma Loop_Invariant (for all K of S => K in First .. I);
         end loop;
      end return;
   end All_Set;

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

   function Is_Acyclic (X : Extended_Index; M : Memory_Type) return Boolean
   with
     Refined_Post => (Static => Is_Acyclic'Result = Is_Acyclic_Internal (X, M))
   is
      Seen     : Memory_Index_Set;
      Not_Seen : Memory_Index_Set := All_Set (M'First, M'Last)
      with Ghost => Static;
      C        : Extended_Index := X;
   begin
      while C /= No_Index loop
         pragma Loop_Variant (Decreases => Length (Not_Seen));
         pragma Loop_Invariant (Static => C in M'Range);
         pragma
           Loop_Invariant
             (Static =>
                (for all I in M'Range =>
                   Contains (Seen, I) /= Contains (Not_Seen, I)));
         pragma
           Loop_Invariant
             (Static =>
                Is_Acyclic_Internal (C, M, Not_Seen)
                = Is_Acyclic_Internal (X, M));
         if Contains (Seen, C) then
            return False;
         end if;
         Seen := Add (Seen, C);
         Not_Seen := Remove (Not_Seen, C);
         C := Next (M (C));
      end loop;
      return True;
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

   --------------------------
   -- Lemma_Is_Acyclic_Def --
   --------------------------

   procedure Lemma_Is_Acyclic_Def (X : Index_Type; M : Memory_Type) is
   begin
      if Next (M (X)) /= No_Index then
         Lemma_Model_Internal_Inc
           (Next (M (X)),
            M,
            Remove (All_Set (M'First, M'Last), X),
            All_Set (M'First, M'Last));
         Lemma_Model_Internal_Cut
           (Next (M (X)), X, M, All_Set (M'First, M'Last));
      end if;
   end Lemma_Is_Acyclic_Def;

   --------------------------------
   -- Lemma_Is_Acyclic_Preserved --
   --------------------------------

   procedure Lemma_Is_Acyclic_Preserved
     (X : Extended_Index; M1, M2 : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      if X /= No_Index then
         Lemma_Is_Acyclic_Preserved (Next (M1 (X)), M1, M2);
      end if;
   end Lemma_Is_Acyclic_Preserved;

   --------------------------
   -- Lemma_Is_Acyclic_Set --
   --------------------------

   procedure Lemma_Is_Acyclic_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      if X = Y then
         Lemma_Is_Acyclic_Preserved (Z, M1, M2);
      else
         Lemma_Is_Acyclic_Set (Next (M1 (X)), Y, Z, M1, M2);
      end if;
   end Lemma_Is_Acyclic_Set;

   ---------------------
   -- Lemma_Model_Def --
   ---------------------

   procedure Lemma_Model_Def (X : Index_Type; M : Memory_Type) is
   begin
      Lemma_Model_Internal_Inc
        (Next (M (X)),
         M,
         Remove (All_Set (M'First, M'Last), X),
         All_Set (M'First, M'Last));
   end Lemma_Model_Def;

   ------------------------------
   -- Lemma_Model_Internal_Cut --
   ------------------------------

   procedure Lemma_Model_Internal_Cut
     (X, Y : Index_Type; M : Memory_Type; S : Memory_Index_Set) is
   begin
      if Next (M (X)) /= No_Index and X /= Y and Contains (S, X) then
         Lemma_Model_Internal_Cut (Next (M (X)), Y, M, Remove (S, X));
         Lemma_Model_Internal_Inc
           (Next (M (X)),
            M,
            Remove (Remove (S, X), Y),
            Remove (Remove (S, Y), X));
         Lemma_Model_Internal_Inc
           (Next (M (X)),
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
     (X : Extended_Index; M : Memory_Type; S1, S2 : Memory_Index_Set) is
   begin
      if X /= No_Index and then Contains (S1, X) then
         Lemma_Model_Internal_Inc
           (Next (M (X)), M, Remove (S1, X), Remove (S2, X));
      end if;
   end Lemma_Model_Internal_Inc;

   ---------------------------
   -- Lemma_Model_Preserved --
   ---------------------------

   procedure Lemma_Model_Preserved (X : Extended_Index; M1, M2 : Memory_Type)
   is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Is_Acyclic_Preserved (X, M1, M2);
      if X /= No_Index then
         Lemma_Model_Preserved (Next (M1 (X)), M1, M2);
      end if;
   end Lemma_Model_Preserved;

   ---------------------
   -- Lemma_Model_Set --
   ---------------------

   procedure Lemma_Model_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Is_Acyclic_Set (X, Y, Z, M1, M2);
      Lemma_Reachable_Acyclic (X, Y, M1);
      Lemma_Is_Acyclic_Set (X, Y, Z, M1, M2);
      if X = Y then
         Lemma_Model_Preserved (Z, M1, M2);
      else
         Lemma_Model_Set (Next (M1 (X)), Y, Z, M1, M2);
         pragma
           Assert
             (for all I in Model (X, M1) =>
                (if I > Last (Model (Y, M1))
                 then
                   Get (Model (X, M1), I)
                   = Get
                       (Model (X, M2),
                        I - Last (Model (Y, M1)) + Last (Model (Z, M1)) + 1)));
         pragma
           Assert
             (for all I in Model (X, M2) =>
                (if I > Last (Model (Z, M1))
                 then
                   Get (Model (X, M2), I)
                   = Get
                       (Model (X, M1),
                        I - Last (Model (Z, M1)) + Last (Model (Y, M1)) - 1)));
      end if;
   end Lemma_Model_Set;

   -----------------------------
   -- Lemma_Reachable_Acyclic --
   -----------------------------

   procedure Lemma_Reachable_Acyclic (X, Y : Index_Type; M : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      if X /= Y then
         Lemma_Reachable_Acyclic (Next (M (X)), Y, M);
      end if;
   end Lemma_Reachable_Acyclic;

   -----------------------------
   -- Lemma_Reachable_Antisym --
   -----------------------------

   procedure Lemma_Reachable_Antisym (X, Z : Index_Type; M : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      if X /= Z and Reachable (X, M, Z) and Reachable (Z, M, X) then
         Lemma_Reachable_Acyclic (X, Z, M);
         Lemma_Reachable_Antisym (Next (M (X)), Z, M);
         Lemma_Reachable_Transitive (Z, X, Next (M (X)), M);
      end if;
   end Lemma_Reachable_Antisym;

   -------------------------
   -- Lemma_Reachable_Def --
   -------------------------

   procedure Lemma_Reachable_Def (X : Index_Type; M : Memory_Type) is
   begin
      if Next (M (X)) /= No_Index then
         Lemma_Is_Acyclic_Def (X, M);
         Lemma_Model_Internal_Inc
           (Next (M (X)),
            M,
            Remove (All_Set (M'First, M'Last), X),
            All_Set (M'First, M'Last));
         pragma
           Assert
             (Reachable_Set (Next (M (X)), M)
              = Reachable_Set_Internal
                  (Next (M (X)), M, Remove (All_Set (M'First, M'Last), X)));
      end if;
   end Lemma_Reachable_Def;

   -------------------------------
   -- Lemma_Reachable_Preserved --
   -------------------------------

   procedure Lemma_Reachable_Preserved
     (X : Extended_Index; M1, M2 : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Is_Acyclic_Preserved (X, M1, M2);
      if X /= No_Index then
         Lemma_Reachable_Preserved (Next (M1 (X)), M1, M2);
      end if;
   end Lemma_Reachable_Preserved;

   -------------------------
   -- Lemma_Reachable_Set --
   -------------------------

   procedure Lemma_Reachable_Set
     (X, Y : Index_Type; Z : Extended_Index; M1, M2 : Memory_Type) is
   begin
      Disclose_Recursive_Definitions;
      Lemma_Is_Acyclic_Set (X, Y, Z, M1, M2);
      Lemma_Reachable_Acyclic (X, Y, M1);
      if X = Y then
         Lemma_Reachable_Preserved (Z, M1, M2);
      else
         Lemma_Reachable_Set (Next (M1 (X)), Y, Z, M1, M2);
         Lemma_Reachable_Antisym (Y, X, M1);
         pragma Assert (not Reachable (Next (M1 (Y)), M1, X));
      end if;
   end Lemma_Reachable_Set;

   --------------------------------
   -- Lemma_Reachable_Transitive --
   --------------------------------

   procedure Lemma_Reachable_Transitive (X, Y, Z : Index_Type; M : Memory_Type)
   is
   begin
      Disclose_Recursive_Definitions;
      if X /= Y and Reachable (X, M, Y) then
         Lemma_Reachable_Transitive (Next (M (X)), Y, Z, M);
      end if;
   end Lemma_Reachable_Transitive;

   -----------
   -- Model --
   -----------

   function Model (X : Extended_Index; M : Memory_Type) return Sequence
   with
     Refined_Post =>
       (Static =>
          Model'Result = Model_Internal (X, M)
          and then
            (if X /= No_Index
             then
               In_Range
                 (Length (Model'Result),
                  0,
                  To_Big (M'Last) - To_Big (M'First) + 1)))
   is
      Seen     : Memory_Index_Set;
      Not_Seen : Memory_Index_Set := All_Set (M'First, M'Last)
      with Ghost => Static;
      C        : Extended_Index := X;
      R_Seq    : Sequence;
   begin
      while C /= No_Index loop
         pragma Loop_Variant (Static => (Decreases => Length (Not_Seen)));
         pragma Loop_Invariant (Static => C in M'Range);
         pragma
           Loop_Invariant
             (Static =>
                (for all I in M'Range =>
                   Contains (Seen, I) /= Contains (Not_Seen, I)));
         pragma
           Loop_Invariant
             (Static =>
                (for all I in R_Seq =>
                   Get (R_Seq, I)
                   = Get
                       (Model_Internal (X, M),
                        Last (Model_Internal (X, M)) - I + 1)));
         pragma
           Loop_Invariant
             (Static =>
                Length (R_Seq)
                <= To_Big (M'Last) - To_Big (M'First) + 1 - Length (Not_Seen));
         pragma
           Loop_Invariant
             (Static =>
                Length (Model_Internal (X, M))
                = Length (R_Seq) + Length (Model_Internal (C, M, Not_Seen)));
         pragma
           Loop_Invariant
             (Static =>
                (for all I in Interval'(1, Last (Model_Internal (X, M))) =>
                   Get (Model_Internal (X, M), I)
                   = (if I <= Last (Model_Internal (X, M)) - Last (R_Seq)
                      then Get (Model_Internal (C, M, Not_Seen), I)
                      else
                        Get (R_Seq, Last (Model_Internal (X, M)) - I + 1))));
         if Contains (Seen, C) then
            exit;
         end if;
         R_Seq := Add (R_Seq, C);
         Seen := Add (Seen, C);
         Not_Seen := Remove (Not_Seen, C);
         C := Next (M (C));
      end loop;

      --  Reverse the sequence

      return Seq : Sequence do
         declare
            I : Big_Integer := Last (R_Seq);
         begin
            while I > 0 loop
               pragma Loop_Variant (Static => (Decreases => I));
               pragma
                 Loop_Invariant
                   (Static =>
                      Length (Seq) = Length (Model_Internal (X, M)) - I);
               pragma
                 Loop_Invariant
                   (Static =>
                      (for all I in Seq =>
                         Get (Seq, I) = Get (Model_Internal (X, M), I)));
               Seq := Add (Seq, Get (R_Seq, I));
               I := I - 1;
            end loop;
         end;
      end return;
   end Model;

   -------------------
   -- Reachable_Set --
   -------------------

   function Reachable_Set
     (X : Extended_Index; M : Memory_Type) return Memory_Index_Set
   with
     Refined_Post =>
       (Static =>
          Reachable_Set'Result = Reachable_Set_Internal (X, M)
          and then
            Length (Reachable_Set'Result)
            = Length (Reachable_Set_Internal (X, M))
          and then
            Length (Reachable_Set'Result)
            <= (if M'Last < M'First
                then 0
                else To_Big (M'Last) - To_Big (M'First) + 1))
   is
      Not_Seen : Memory_Index_Set := All_Set (M'First, M'Last)
      with Ghost => Static;
      C        : Extended_Index := X;
   begin
      return S : Memory_Index_Set do
         while C /= No_Index loop
            pragma Loop_Variant (Static => (Decreases => Length (Not_Seen)));
            pragma Loop_Invariant (Static => C in M'Range);
            pragma
              Loop_Invariant
                (Static =>
                   Length (S) + Length (Not_Seen)
                   = To_Big (M'Last) - To_Big (M'First) + 1);
            pragma
              Loop_Invariant
                (Static =>
                   (for all I in M'Range =>
                      Contains (S, I) /= Contains (Not_Seen, I)));
            pragma
              Loop_Invariant
                (Static =>
                   Length (Reachable_Set_Internal (X, M))
                   = Length (S)
                     + Length (Reachable_Set_Internal (C, M, Not_Seen)));
            pragma
              Loop_Invariant
                (Static =>
                   Reachable_Set_Internal (X, M)
                   = Union (S, Reachable_Set_Internal (C, M, Not_Seen)));
            if Contains (S, C) then
               return;
            end if;
            S := Add (S, C);
            Not_Seen := Remove (Not_Seen, C);
            C := Next (M (C));
         end loop;
      end return;
   end Reachable_Set;

end SPARK.Higher_Order.Reachability;
