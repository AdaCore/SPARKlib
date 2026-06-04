--
--  Copyright (C) 2023-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

package body SPARK.Containers.Functional.Vectors.Higher_Order
  with SPARK_Mode => Off --  #BODYMODE
is

   function Count_Rec
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   with
     Ghost              => SPARKlib_Full,
     Subprogram_Variant => (Decreases => Last),
     Pre                => Last <= Vectors.Last (S),
     Post               =>
       Count_Rec'Result <= Big (Last) - Big (Extended_Index'First);
   --  Recursive version of Count

   function Filter_Rec
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   with
     Ghost              => SPARKlib_Full,
     Subprogram_Variant => (Decreases => Last),
     Pre                => Last <= Vectors.Last (S),
     Post               =>
       Length (Filter_Rec'Result) = Count_Rec (S, Last, Test)
       and then (for all E of Filter_Rec'Result => Test (E));
   --  Recursive version of Filter

   function Sum_Rec
     (S     : Sequence;
      Last  : Extended_Index;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   with
     Ghost              => SPARKlib_Full,
     Subprogram_Variant => (Decreases => Last),
     Pre                => Last <= Vectors.Last (S);
   --  Recursive version of Sum

   -----------
   -- Count --
   -----------

   function Count
     (S    : Sequence;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   is (Count (S, Last (S), Test));

   function Count
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   with
     Refined_Post =>
       (SPARKlib_Full => Count'Result = Count_Rec (S, Last, Test))
   is
   begin
      return Res : Big_Natural := 0 do
         for I in Index_Type'First .. Last loop
            if Test (Get (S, I)) then
               Res := Res + 1;
            end if;
            pragma Loop_Invariant (Static => I <= Last);
            pragma Loop_Invariant (Static => Res = Count_Rec (S, I, Test));
         end loop;
      end return;
   end Count;

   ---------------
   -- Count_Rec --
   ---------------

   function Count_Rec
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   is (if Last = Extended_Index'First
       then 0
       else
         Count_Rec (S, Extended_Index'Pred (Last), Test)
         + (if Test (Get (S, Last))
            then Big_Integer'(1)
            else Big_Integer'(0)));

   ------------
   -- Create --
   ------------

   function Create
     (New_Last : Extended_Index;
      New_Item : not null access function (I : Index_Type) return Element_Type)
      return Sequence is
   begin
      return Res : Sequence do
         for I in Index_Type'First .. New_Last loop
            Res := Add (Res, New_Item (I));

            pragma Loop_Invariant (Static => Last (Res) = I);
            pragma
              Loop_Invariant
                (Static =>
                   (for all J in Index_Type'First .. I =>
                      Element_Logic_Equal (Get (Res, J), New_Item (J))));
         end loop;
      end return;
   end Create;

   ------------
   -- Filter --
   ------------

   function Filter
     (S    : Sequence;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   is (Filter (S, Last (S), Test));

   function Filter
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   with
     Refined_Post =>
       (SPARKlib_Full =>
          Length (Filter'Result) = Length (Filter_Rec (S, Last, Test))
          and then Equal_Prefix (Filter'Result, Filter_Rec (S, Last, Test)))
   is
   begin
      return Res : Sequence do
         for I in Index_Type'First .. Last loop
            if Test (Get (S, I)) then
               Res := Add (Res, Get (S, I));
            end if;
            pragma
              Loop_Invariant
                (Static => Length (Res) = Length (Filter_Rec (S, I, Test)));
            pragma
              Loop_Invariant
                (Static => Equal_Prefix (Res, Filter_Rec (S, I, Test)));
         end loop;
      end return;
   end Filter;

   ----------------
   -- Filter_Rec --
   ----------------

   function Filter_Rec
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   is (if Last = Extended_Index'First
       then Empty_Sequence
       elsif Test (Get (S, Last))
       then
         Add (Filter_Rec (S, Extended_Index'Pred (Last), Test), Get (S, Last))
       else Filter_Rec (S, Extended_Index'Pred (Last), Test));

   ---------------------
   -- Lemma_Count_All --
   ---------------------

   procedure Lemma_Count_All
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
   is

      procedure Do_Proof
      with Ghost => Static;
      --  Prove the lemma

      --------------
      -- Do_Proof --
      --------------

      procedure Do_Proof is
      begin
         for I in Index_Type'First .. Last loop
            pragma
              Loop_Invariant
                (Count_Rec (S, I, Test)
                 = Big (I) - Big (Extended_Index'First));
         end loop;
      end Do_Proof;

   begin
      Do_Proof;
   end Lemma_Count_All;

   --------------------
   -- Lemma_Count_Eq --
   --------------------

   procedure Lemma_Count_Eq
     (S1, S2 : Sequence;
      Last   : Extended_Index;
      Test   : not null access function (E : Element_Type) return Boolean)
   is

      procedure Do_Proof
      with Ghost => Static;
      --  Prove the lemma

      --------------
      -- Do_Proof --
      --------------

      procedure Do_Proof is
      begin
         for I in Index_Type'First .. Last loop
            pragma
              Loop_Invariant
                (Count_Rec (S1, I, Test) = Count_Rec (S2, I, Test));
         end loop;
      end Do_Proof;

   begin
      Do_Proof;
   end Lemma_Count_Eq;

   ----------------------
   -- Lemma_Count_Last --
   ----------------------

   procedure Lemma_Count_Last
     (S    : Sequence;
      Last : Index_Type;
      Test : not null access function (E : Element_Type) return Boolean)
   is null;

   ----------------------
   -- Lemma_Count_None --
   ----------------------

   procedure Lemma_Count_None
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
   is

      procedure Do_Proof
      with Ghost => Static;
      --  Prove the lemma

      --------------
      -- Do_Proof --
      --------------

      procedure Do_Proof is
      begin
         for I in Index_Type'First .. Last loop
            pragma Loop_Invariant (Count_Rec (S, I, Test) = 0);
         end loop;
      end Do_Proof;

   begin
      Do_Proof;
   end Lemma_Count_None;

   ----------------------
   -- Lemma_Filter_All --
   ----------------------

   procedure Lemma_Filter_All
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
   is

      procedure Do_Proof
      with Ghost => Static;
      --  Prove the lemma

      --------------
      -- Do_Proof --
      --------------

      procedure Do_Proof is
      begin
         for I in Index_Type'First .. Last loop
            pragma Loop_Invariant (Vectors.Last (Filter_Rec (S, I, Test)) = I);
            pragma Loop_Invariant (Equal_Prefix (Filter_Rec (S, I, Test), S));
         end loop;
      end Do_Proof;

   begin
      Do_Proof;
   end Lemma_Filter_All;

   ---------------------
   -- Lemma_Filter_Eq --
   ---------------------

   procedure Lemma_Filter_Eq
     (S1, S2 : Sequence;
      Last   : Extended_Index;
      Test   : not null access function (E : Element_Type) return Boolean)
   is

      procedure Do_Proof
      with Ghost => Static;
      --  Prove the lemma

      --------------
      -- Do_Proof --
      --------------

      procedure Do_Proof is
      begin
         for I in Index_Type'First .. Last loop
            pragma
              Loop_Invariant
                (Length (Filter_Rec (S1, I, Test))
                 = Length (Filter_Rec (S2, I, Test)));
            pragma
              Loop_Invariant
                (Equal_Prefix
                   (Filter_Rec (S1, I, Test), Filter_Rec (S2, I, Test)));
         end loop;
      end Do_Proof;

   begin
      Do_Proof;
   end Lemma_Filter_Eq;

   -----------------------
   -- Lemma_Filter_Last --
   -----------------------

   procedure Lemma_Filter_Last
     (S    : Sequence;
      Last : Index_Type;
      Test : not null access function (E : Element_Type) return Boolean)
   is null;

   ------------------
   -- Lemma_Sum_Eq --
   ------------------

   procedure Lemma_Sum_Eq
     (S1, S2 : Sequence;
      Last   : Extended_Index;
      Value  : not null access function (E : Element_Type) return Big_Integer)
   is

      procedure Do_Proof
      with Ghost => Static;
      --  Prove the lemma

      --------------
      -- Do_Proof --
      --------------

      procedure Do_Proof is
      begin
         for I in Index_Type'First .. Last loop
            pragma
              Loop_Invariant (Sum_Rec (S1, I, Value) = Sum_Rec (S2, I, Value));
         end loop;
      end Do_Proof;

   begin
      Do_Proof;
   end Lemma_Sum_Eq;

   --------------------
   -- Lemma_Sum_Last --
   --------------------

   procedure Lemma_Sum_Last
     (S     : Sequence;
      Last  : Index_Type;
      Value : not null access function (E : Element_Type) return Big_Integer)
   is null;

   ---------
   -- Sum --
   ---------

   function Sum
     (S     : Sequence;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   is (Sum (S, Last (S), Value));

   function Sum
     (S     : Sequence;
      Last  : Extended_Index;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   with
     Refined_Post => (SPARKlib_Full => Sum'Result = Sum_Rec (S, Last, Value))
   is
   begin
      return Res : Big_Integer := 0 do
         for I in Index_Type'First .. Last loop
            Res := Res + Value (Get (S, I));
            pragma Loop_Invariant (Static => Res = Sum_Rec (S, I, Value));
         end loop;
      end return;
   end Sum;

   -------------
   -- Sum_Rec --
   -------------

   function Sum_Rec
     (S     : Sequence;
      Last  : Extended_Index;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   is (if Last = Extended_Index'First
       then Big_Integer'(0)
       else
         Sum_Rec (S, Extended_Index'Pred (Last), Value)
         + Value (Get (S, Last)));

   ---------------
   -- Transform --
   ---------------

   function Transform
     (S              : Sequence;
      Transform_Item :
        not null access function (E : Element_Type) return Element_Type)
      return Sequence is
   begin
      return Res : Sequence do
         for I in Index_Type'First .. Last (S) loop
            Res := Add (Res, Transform_Item (Get (S, I)));
            pragma Loop_Invariant (Static => Last (Res) = I);
            pragma
              Loop_Invariant
                (Static =>
                   (for all J in Index_Type'First .. I =>
                      Element_Logic_Equal
                        (Get (Res, J), Transform_Item (Get (S, J)))));
         end loop;
      end return;
   end Transform;

end SPARK.Containers.Functional.Vectors.Higher_Order;
