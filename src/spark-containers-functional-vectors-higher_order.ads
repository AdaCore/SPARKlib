--
--  Copyright (C) 2023-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;
with SPARK.Big_Integers; use SPARK.Big_Integers;

generic
package SPARK.Containers.Functional.Vectors.Higher_Order with
  SPARK_Mode,
  Always_Terminates
is

   function Create
     (New_Last : Extended_Index;
      New_Item : not null access
        function (I : Index_Type) return Element_Type)
      return Sequence
   --  Return a new sequence with New_Length elements. Each element is created
   --  by calling New_Item.

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Post     =>
       (SPARKlib_Full =>
          Last (Create'Result) = New_Last
          and then
             (for all I in Index_Type'First .. New_Last =>
                Element_Logic_Equal (Get (Create'Result, I), New_Item (I))));

   function Transform
     (S              : Sequence;
      Transform_Item : not null access
        function (E : Element_Type) return Element_Type)
      return Sequence
   --  Return a new sequence with the same length as S. Its elements are
   --  obtained using Transform_Item on the elements of S.

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Post     =>
       (SPARKlib_Full =>
          Length (Transform'Result) = Length (S)
          and then
             (for all I in Index_Type'First .. Last (S) =>
                Element_Logic_Equal
                  (Get (Transform'Result, I), Transform_Item (Get (S, I)))));

   function Count
     (S    : Sequence;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   --  Count the number of elements on which the input Test function returns
   --  True.

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Inline_For_Proof),
     Post     => (SPARKlib_Full => Count'Result = Count (S, Last (S), Test));

   function Count
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   --  Count the number of elements on which the input Test function returns
   --  True.

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => (SPARKlib_Defensive => Last <= Vectors.Last (S)),
     Post     =>
       (SPARKlib_Full =>
          Count'Result <= Big (Last) - Big (Extended_Index'First));

   procedure Lemma_Count_Eq
     (S1, S2 : Sequence;
      Last   : Extended_Index;
      Test   : not null access function (E : Element_Type) return Boolean)
   --  Automatically instantiated lemma:
   --  Count returns the same value on sequences containing the same elements.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Vectors.Last (S1) and then Last <= Vectors.Last (S2)
       and then Range_Equal (S1, S2, Index_Type'First, Last),
     Post     => Count (S1, Last, Test) = Count (S2, Last, Test);

   procedure Lemma_Count_Last
     (S    : Sequence;
      Last : Index_Type;
      Test : not null access function (E : Element_Type) return Boolean)
   --  Automatically instantiated lemma:
   --  Recursive definition of Count.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Vectors.Last (S),
     Post     =>
       Count (S, Last, Test) = Count (S, Extended_Index'Pred (Last), Test) +
          (if Test (Get (S, Last)) then Big_Integer'(1) else Big_Integer'(0));

   procedure Lemma_Count_All
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
   --  Additional lemma:
   --  Count returns Last if Test returns True on all elements of S up to Last.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => Last <= Vectors.Last (S)
       and then (for all I in Index_Type'First .. Last => Test (Get (S, I))),
     Post     => Count (S, Last, Test) =
       Big (Last) - Big (Extended_Index'First);

   procedure Lemma_Count_None
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
   --  Additional lemma:
   --  Count returns 0 if Test returns False on all elements of S up to Last.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => Last <= Vectors.Last (S)
       and then
         (for all I in Index_Type'First .. Last => not Test (Get (S, I))),
     Post     => Count (S, Last, Test) = 0;

   function Filter
     (S    : Sequence;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   --  Return a new sequence with all elements of S on which the input Test
   --  function returns True.

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Inline_For_Proof),
     Post     => (SPARKlib_Full => Filter'Result = Filter (S, Last (S), Test));

   function Filter
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   --  Return a new sequence with all elements of S on which the input Test
   --  function returns True.

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => (SPARKlib_Defensive => Last <= Vectors.Last (S)),
     Post     =>
       (SPARKlib_Full =>
          Length (Filter'Result) = Count (S, Last, Test)
          and then (for all E of Filter'Result => Test (E)));

   procedure Lemma_Filter_Eq
     (S1, S2 : Sequence;
      Last   : Extended_Index;
      Test   : not null access function (E : Element_Type) return Boolean)
   --  Automatically instantiated lemma:
   --  Filter returns the same value on sequences containing the same elements.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Vectors.Last (S1) and then Last <= Vectors.Last (S2)
       and then (for all I in Index_Type'First .. Last =>
                   Element_Logic_Equal (Get (S1, I), Get (S2, I))),
     Post     =>
       Length (Filter (S1, Last, Test)) = Length (Filter (S2, Last, Test))
       and then
         Equal_Prefix (Filter (S1, Last, Test), Filter (S2, Last, Test));

   procedure Lemma_Filter_Last
     (S    : Sequence;
      Last : Index_Type;
      Test : not null access function (E : Element_Type) return Boolean)
   --  Automatically instantiated lemma:
   --  Recursive definition of Filter.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Vectors.Last (S),
     Post     =>
       Equal_Prefix
         (Filter (S, Extended_Index'Pred (Last), Test),
          Filter (S, Last, Test)),
     Contract_Cases =>
       (Test (Get (S, Last)) =>
          Length (Filter (S, Last, Test)) - 1 =
            Length (Filter (S, Extended_Index'Pred (Last), Test))
          and then Element_Logic_Equal
            (Get (S, Last),
             Get (Filter (S, Last, Test),
                  Vectors.Last (Filter (S, Last, Test)))),
        others               =>
          Length (Filter (S, Last, Test)) =
            Length (Filter (S, Extended_Index'Pred (Last), Test)));

   procedure Lemma_Filter_All
     (S    : Sequence;
      Last : Extended_Index;
      Test : not null access function (E : Element_Type) return Boolean)
   --  Additional lemma:
   --  Filter returns the prefix of S up to Last if Test returns True on all
   --  of its elements.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => Last <= Vectors.Last (S)
       and then (for all I in Index_Type'First .. Last => Test (Get (S, I))),
     Post     => Vectors.Last (Filter (S, Last, Test)) = Last
       and then Equal_Prefix (Filter (S, Last, Test), S);

   function Sum
     (S     : Sequence;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   --  Sum the result of the Value function on all elements of S

   with
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Higher_Order_Specialization),
     Post     => (SPARKlib_Full => Sum'Result = Sum (S, Last (S), Value));

   function Sum
     (S     : Sequence;
      Last  : Extended_Index;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   --  Sum the result of the Value function on all elements of S up to Last

   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => (SPARKlib_Defensive => Last <= Vectors.Last (S)),
     Post     =>
       (SPARKlib_Full => (if Last = Extended_Index'First then Sum'Result = 0));

   procedure Lemma_Sum_Eq
     (S1, S2 : Sequence;
      Last   : Extended_Index;
      Value  : not null access function (E : Element_Type) return Big_Integer)
   --  Automatically instantiated lemma:
   --  Sum returns the same value on sequences containing the same elements.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Vectors.Last (S1) and then Last <= Vectors.Last (S2)
       and then Range_Equal (S1, S2, Index_Type'First, Last),
     Post     => Sum (S1, Last, Value) = Sum (S2, Last, Value);

   procedure Lemma_Sum_Last
     (S     : Sequence;
      Last  : Index_Type;
      Value : not null access function (E : Element_Type) return Big_Integer)
   --  Automatically instantiated lemma:
   --  Recursive definition of Sum.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Vectors.Last (S),
     Post     => Sum (S, Last, Value) =
       Sum (S, Extended_Index'Pred (Last), Value) + Value (Get (S, Last));

end SPARK.Containers.Functional.Vectors.Higher_Order;
