--
--  Copyright (C) 2023-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;
with SPARK.Big_Intervals; use SPARK.Big_Intervals;

generic
package SPARK.Containers.Functional.Infinite_Sequences.Higher_Order with
    SPARK_Mode,
    Always_Terminates
is

   function Create
     (New_Length : Big_Natural;
      New_Item   :
        not null access function (I : Big_Positive) return Element_Type)
      return Sequence
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Post     =>
       (SPARKlib_Full =>
          Length (Create'Result) = New_Length
          and then
            (for all I in Interval'(1, New_Length) =>
               Element_Logic_Equal (Get (Create'Result, I), New_Item (I))));
   --  Return a new sequence with New_Length elements. Each element is created
   --  by calling New_Item.

   function Transform
     (S              : Sequence;
      Transform_Item :
        not null access function (E : Element_Type) return Element_Type)
      return Sequence
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Post     =>
       (SPARKlib_Full =>
          Length (Transform'Result) = Length (S)
          and then
            (for all I in Interval'(1, Length (S)) =>
               Element_Logic_Equal
                 (Get (Transform'Result, I), Transform_Item (Get (S, I)))));
   --  Return a new sequence with the same length as S. Its elements are
   --  obtained using Transform_Item on the elements of S.
   function Count
     (S    : Sequence;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Inline_For_Proof),
     Post     => (SPARKlib_Full => Count'Result = Count (S, Length (S), Test));
   --  Count the number of elements on which the input Test function returns
   --  True.

   function Count
     (S    : Sequence;
      Last : Big_Natural;
      Test : not null access function (E : Element_Type) return Boolean)
      return Big_Natural
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => (SPARKlib_Defensive => Last <= Length (S)),
     Post     => (SPARKlib_Full => Count'Result <= Last);
   --  Count the number of elements on which the input Test function returns
   --  True.

   procedure Lemma_Count_Eq
     (S1, S2 : Sequence;
      Last   : Big_Natural;
      Test   : not null access function (E : Element_Type) return Boolean)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      =>
       Last <= Length (S1)
       and then Last <= Length (S2)
       and then Range_Equal (S1, S2, 1, Last),
     Post     => Count (S1, Last, Test) = Count (S2, Last, Test);
   --  Automatically instantiated lemma:
   --  Count returns the same value on sequences containing the same elements.

   procedure Lemma_Count_Last
     (S    : Sequence;
      Last : Big_Positive;
      Test : not null access function (E : Element_Type) return Boolean)
     --  Automatically instantiated lemma:
     --  Recursive definition of Count.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Length (S),
     Post     =>
       Count (S, Last, Test)
       = Count (S, Last - 1, Test)
         + (if Test (Get (S, Last)) then Big_Natural'(1) else 0);

   procedure Lemma_Count_All
     (S    : Sequence;
      Last : Big_Natural;
      Test : not null access function (E : Element_Type) return Boolean)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      =>
       Last <= Length (S)
       and then (for all I in Interval'(1, Last) => Test (Get (S, I))),
     Post     => Count (S, Last, Test) = Last;
   --  Additional lemma:
   --  Count returns Last if Test returns True on all elements of S up to Last.

   procedure Lemma_Count_None
     (S    : Sequence;
      Last : Big_Natural;
      Test : not null access function (E : Element_Type) return Boolean)
     --  Additional lemma:
     --  Count returns 0 if Test returns False on all elements of S up to Last.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      =>
       Last <= Length (S)
       and then (for all I in Interval'(1, Last) => not Test (Get (S, I))),
     Post     => Count (S, Last, Test) = 0;

   function Filter
     (S    : Sequence;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Inline_For_Proof),
     Post     =>
       (SPARKlib_Full => Filter'Result = Filter (S, Length (S), Test));
   --  Return a new sequence with all elements of S on which the input Test
   --  function returns True.

   function Filter
     (S    : Sequence;
      Last : Big_Natural;
      Test : not null access function (E : Element_Type) return Boolean)
      return Sequence
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => (SPARKlib_Defensive => Last <= Length (S)),
     Post     =>
       (SPARKlib_Full =>
          Length (Filter'Result) = Count (S, Last, Test)
          and then (for all E of Filter'Result => Test (E)));
   --  Return a new sequence with all elements of S on which the input Test
   --  function returns True.

   procedure Lemma_Filter_Eq
     (S1, S2 : Sequence;
      Last   : Big_Natural;
      Test   : not null access function (E : Element_Type) return Boolean)
   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      =>
       Last <= Length (S1)
       and then Last <= Length (S2)
       and then
         (for all I in Interval'(1, Last) =>
            Element_Logic_Equal (Get (S1, I), Get (S2, I))),
     Post     =>
       Length (Filter (S1, Last, Test)) = Length (Filter (S2, Last, Test))
       and then
         Equal_Prefix (Filter (S1, Last, Test), Filter (S2, Last, Test));
   --  Automatically instantiated lemma:
   --  Filter returns the same value on sequences containing the same elements.

   procedure Lemma_Filter_Last
     (S    : Sequence;
      Last : Big_Positive;
      Test : not null access function (E : Element_Type) return Boolean)
     --  Automatically instantiated lemma:
     --  Recursive definition of Filter.

   with
     Ghost          => SPARKlib_Full,
     Global         => null,
     Annotate       => (GNATprove, Higher_Order_Specialization),
     Annotate       => (GNATprove, Automatic_Instantiation),
     Pre            => Last <= Length (S),
     Post           =>
       Equal_Prefix (Filter (S, Last - 1, Test), Filter (S, Last, Test)),
     Contract_Cases =>
       (Test (Get (S, Last)) =>
          Length (Filter (S, Last, Test))
          = Length (Filter (S, Last - 1, Test)) + 1
          and then
            Element_Logic_Equal
              (Get (S, Last),
               Get (Filter (S, Last, Test), Length (Filter (S, Last, Test)))),
        others               =>
          Length (Filter (S, Last, Test))
          = Length (Filter (S, Last - 1, Test)));

   procedure Lemma_Filter_All
     (S    : Sequence;
      Last : Big_Natural;
      Test : not null access function (E : Element_Type) return Boolean)
     --  Additional lemma:
     --  Filter returns the prefix of S up to Last if Test returns True on all
     --  of its elements.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      =>
       Last <= Length (S)
       and then (for all I in Interval'(1, Last) => Test (Get (S, I))),
     Post     =>
       Length (Filter (S, Last, Test)) = Last
       and then Equal_Prefix (Filter (S, Last, Test), S);

   function Sum
     (S     : Sequence;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   with
     Global   => null,
     Annotate => (GNATprove, Inline_For_Proof),
     Annotate => (GNATprove, Higher_Order_Specialization),
     Post     => (SPARKlib_Full => Sum'Result = Sum (S, Length (S), Value));
   --  Sum the result of the Value function on all elements of S

   function Sum
     (S     : Sequence;
      Last  : Big_Natural;
      Value : not null access function (E : Element_Type) return Big_Integer)
      return Big_Integer
   with
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Pre      => (SPARKlib_Defensive => Last <= Length (S)),
     Post     => (SPARKlib_Full => (if Last = 0 then Sum'Result = 0));
   --  Sum the result of the Value function on all elements of S up to Last

   procedure Lemma_Sum_Eq
     (S1, S2 : Sequence;
      Last   : Big_Natural;
      Value  : not null access function (E : Element_Type) return Big_Integer)
     --  Automatically instantiated lemma:
     --  Sum returns the same value on sequences containing the same elements.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      =>
       Last <= Length (S1)
       and then Last <= Length (S2)
       and then Range_Equal (S1, S2, 1, Last),
     Post     => Sum (S1, Last, Value) = Sum (S2, Last, Value);

   procedure Lemma_Sum_Last
     (S     : Sequence;
      Last  : Big_Positive;
      Value : not null access function (E : Element_Type) return Big_Integer)
     --  Automatically instantiated lemma:
     --  Recursive definition of Sum.

   with
     Ghost    => SPARKlib_Full,
     Global   => null,
     Annotate => (GNATprove, Higher_Order_Specialization),
     Annotate => (GNATprove, Automatic_Instantiation),
     Pre      => Last <= Length (S),
     Post     =>
       Sum (S, Last, Value) = Sum (S, Last - 1, Value) + Value (Get (S, Last));

end SPARK.Containers.Functional.Infinite_Sequences.Higher_Order;
