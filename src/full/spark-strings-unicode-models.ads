--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Big_Integers; use SPARK.Big_Integers;
with SPARK.Containers.Functional.Infinite_Sequences;

package SPARK.Strings.Unicode.Models
  with SPARK_Mode, Always_Terminates
is

   package Scalar_Sequences is new
     SPARK.Containers.Functional.Infinite_Sequences
       (Element_Type         => Scalar_Value,
        Use_Logical_Equality => True);
   use type Scalar_Sequences.Sequence;

   subtype Text is Scalar_Sequences.Sequence;
   --  The unicode text model is a sequence of unicode scalar values

   function Is_Prefix (Prefix, Whole : Text) return Boolean
   is (Scalar_Sequences.Length (Prefix) <= Scalar_Sequences.Length (Whole)
       and then
         (for all I in Prefix =>
            Scalar_Sequences.Get (Prefix, I)
            = Scalar_Sequences.Get (Whole, I)))
   with Global => null, Ghost => Static;

   function Is_Suffix (Suffix, Whole : Text) return Boolean
   is (Scalar_Sequences.Length (Suffix) <= Scalar_Sequences.Length (Whole)
       and then
         (for all I in Suffix =>
            Scalar_Sequences.Get (Suffix, I)
            = Scalar_Sequences.Get
                (Whole,
                 Scalar_Sequences.Length (Whole)
                 - Scalar_Sequences.Length (Suffix)
                 + I)))
   with Global => null, Ghost => Static;

   function Is_Lexicographically_Less (Left, Right : Text) return Boolean
   is ((Scalar_Sequences.Length (Left) < Scalar_Sequences.Length (Right)
        and then Is_Prefix (Left, Right))
       or else
         (for some I in Left =>
            I <= Scalar_Sequences.Length (Right)
            and then
              (for all J in Left =>
                 (if J < I
                  then
                    Scalar_Sequences.Get (Left, J)
                    = Scalar_Sequences.Get (Right, J)))
            and then
              Scalar_Sequences.Get (Left, I)
              < Scalar_Sequences.Get (Right, I)))
   with Global => null, Ghost => Static;

   function Is_Concatenation (Left, Right, Result : Text) return Boolean
   is (Scalar_Sequences.Length (Result)
       = Scalar_Sequences.Length (Left) + Scalar_Sequences.Length (Right)
       and then
         (for all I in Left =>
            Scalar_Sequences.Get (Result, I) = Scalar_Sequences.Get (Left, I))
       and then
         (for all I in Right =>
            Scalar_Sequences.Get (Result, Scalar_Sequences.Length (Left) + I)
            = Scalar_Sequences.Get (Right, I)))
   with Global => null, Ghost => Static;

   function Is_Slice
     (Source : Text; First : Big_Positive; Count : Big_Natural; Result : Text)
      return Boolean
   is (First <= Scalar_Sequences.Length (Source) + 1
       and then Count <= Scalar_Sequences.Length (Source) - (First - 1)
       and then Scalar_Sequences.Length (Result) = Count
       and then
         (for all I in Result =>
            Scalar_Sequences.Get (Result, I)
            = Scalar_Sequences.Get (Source, First + I - 1)))
   with Global => null, Ghost => Static;

end SPARK.Strings.Unicode.Models;
