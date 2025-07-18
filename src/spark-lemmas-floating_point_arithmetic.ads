--
--  Copyright (C) 2017-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit defines floating-point lemmas in a generic way, subject to the
--  definition of the following generic parameters:
--    Fl is a floating-point type
--    Fl_Last_Sqrt is a value whose square does not overflow the base type
--      of Fl, which is used to bound inputs in precondition of some lemmas
--
--  The SPARK lemma library comes with two instances of this generic unit, for
--  32bits and 64bits floating-point types. Both instances have been completely
--  proved, using manual proof in Coq where needed. It is recommended to use
--  these instances instead of instantiating your own version of the generic,
--  in order to benefit from the proofs already done on the existing instances.

with SPARK.Big_Integers;
use  SPARK.Big_Integers;
with SPARK.Big_Reals;
use  SPARK.Big_Reals;

generic
   type Fl is digits <>;
   --  Floating point type for the lemmas
   type Int is range <>;
   --  Integer type big enough to fit the range where all integers are
   --  representable.
   Fl_Last_Sqrt : Fl;
   --  Safe bound for the multiplication of two floating point numbers
   Max_Int      : Big_Integer;
   --  Maximal integer value such that all integer values up to Max_Int are
   --  representiable in Fl.
   Epsilon      : Big_Real;
   --  Machile epsilon for Fl
   Eta          : Big_Real;
   --  Smallest positive floating-point number
   with function Real (V : Fl) return Big_Real is <>;
   --  Conversion to Big_Real

package SPARK.Lemmas.Floating_Point_Arithmetic
  with SPARK_Mode,
       Ghost,
       Always_Terminates
is

   pragma Warnings
     (Off, "postcondition does not check the outcome of calling");

   procedure Lemma_Add_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   with
       Global => null,
       Pre =>
         Val1 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
         Val2 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
         Val3 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
          Val1 <= Val2,
       Post => Val1 + Val3 <= Val2 + Val3;

   procedure Lemma_Sub_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
     with
       Global => null,
       Pre =>
         Val1 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
         Val2 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
         Val3 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
         Val1 <= Val2,
       Post => Val1 - Val3 <= Val2 - Val3;

   procedure Lemma_Mult_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
     with
       Global => null,
       Pre =>
         Val1 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val2 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val3 in 0.0 .. Fl_Last_Sqrt and then
         Val1 <= Val2,
       Post => Val1 * Val3 <= Val2 * Val3;  --  COLIBRI

   procedure Lemma_Mult_Right_Negative_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
     with
       Global => null,
       Pre =>
         Val1 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val2 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val3 in -Fl_Last_Sqrt .. 0.0 and then
         Val1 <= Val2,
       Post => Val2 * Val3 <= Val1 * Val3;  --  COLIBRI

   procedure Lemma_Mult_By_Less_Than_One
     (Val1 : Fl;
      Val2 : Fl)
     with
       Global => null,
       Pre => Val1 in 0.0 .. 1.0 and Val2 >= 0.0,
       Post => Val1 * Val2 <= Val2;  --  MANUAL PROOF

   procedure Lemma_Div_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
     with
       Global => null,
       Pre =>
         Val1 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val2 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val3 in 1.0 / Fl_Last_Sqrt .. Fl'Last and then
         Val1 <= Val2,
       Post => Val1 / Val3 <= Val2 / Val3;  --  COLIBRI

   procedure Lemma_Div_Right_Negative_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
     with
       Global => null,
       Pre =>
         Val1 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val2 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
         Val3 in Fl'First .. -1.0 / Fl_Last_Sqrt and then
         Val1 <= Val2,
       Post => Val2 / Val3 <= Val1 / Val3;  --  COLIBRI

   procedure Lemma_Div_Left_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
     with
       Global => null,
       Pre =>
         Val1 in 0.0 .. Fl_Last_Sqrt and then
         ((Val2 in 1.0 / Fl_Last_Sqrt .. Fl'Last and then
                   Val3 in 1.0 / Fl_Last_Sqrt .. Fl'Last) or else
            (Val2 in Fl'First .. -1.0 / Fl_Last_Sqrt and then
                     Val3 in Fl'First .. -1.0 / Fl_Last_Sqrt)) and then
         Val2 <= Val3,
       Post => Val1 / Val3 <= Val1 / Val2; --  COLIBRI

   ---------------------------------------------
   -- Conversions between floats and integers --
   ---------------------------------------------

   type Integer_32 is range -2**31 .. 2**31 - 1;
   type Integer_64 is range -2**63 .. 2**63 - 1;

   Fl_32 : constant Boolean := Fl'Size = 32;
   Fl_64 : constant Boolean := Fl'Size = 64;

   pragma Compile_Time_Error
     (not (Fl_32 or Fl_64),
      "only 32-bits and 64-bits IEEE floats are supported in SPARK");

   --  Maximum value of a 32-bits or 64-bits float that can be represented as a
   --  32-bits or 64-bits integer. That takes into account the size of the
   --  mantissa for 32-bits floats (24) and 64-bits floats (53) as well as the
   --  fact signed integer range is asymmetric with one fewer positive value.

   --  The maximum value of a 32-bits float that can be represented as a
   --  32-bits integer consists of a mantissa of only 1s with an exponent of
   --  30, so that its value is equal to 2**31 - 2**X, where X corresponds to
   --  the value of exponent for the unit in the last place. Here, given that
   --  the mantissa is 24-bits long, if the unit past the mantissa corresponds
   --  to exponent 31, then the unit in the last place corresponds to exponent
   --  X = 31 - 24 = 7, hence the value 2.0**31 - 2.0**7 below. Other values
   --  are computed similarly.

   Max_Fl_32_As_Integer_32 : constant := 2.0**31 - 2.0**7;
   Max_Fl_64_As_Integer_32 : constant := 2.0**31 - 1.0;
   Max_Fl_32_As_Integer_64 : constant := 2.0**63 - 2.0**39;
   Max_Fl_64_As_Integer_64 : constant := 2.0**63 - 2.0**10;

   Max_Fl_As_Integer_32 : constant Fl :=
     (if Fl_32 then Max_Fl_32_As_Integer_32 else Max_Fl_64_As_Integer_32);
   Max_Fl_As_Integer_64 : constant Fl :=
     (if Fl_32 then Max_Fl_32_As_Integer_64 else Max_Fl_64_As_Integer_64);

   Max_Fl_32_As_Integer_32_Int : constant := 2**31 - 2**7;
   Max_Fl_64_As_Integer_32_Int : constant := 2**31 - 1;
   Max_Fl_32_As_Integer_64_Int : constant := 2**63 - 2**39;
   Max_Fl_64_As_Integer_64_Int : constant := 2**63 - 2**10;

   Max_Fl_As_Integer_32_Int : constant Integer_32 :=
     (if Fl_32 then Max_Fl_32_As_Integer_32_Int
      else Max_Fl_64_As_Integer_32_Int);
   Max_Fl_As_Integer_64_Int : constant Integer_64 :=
     (if Fl_32 then Max_Fl_32_As_Integer_64_Int
      else Max_Fl_64_As_Integer_64_Int);

   --  Determines if F is representable as a 64-bits integer
   function Is_Integer_64 (F : Fl) return Boolean is
      --  Protect against overflow in the conversion below
      ((abs F <= Max_Fl_As_Integer_64 or else F = Fl (Integer_64'First))
       --  F is an integer iff it can be converted to and back from integer
       and then Fl (Integer_64 (F)) = F)
   with Ghost;

   --  Determines if F is representable as a 32-bits integer
   function Is_Integer_32 (F : Fl) return Boolean is
      --  Protect against overflow in the conversion below
      ((abs F <= Max_Fl_As_Integer_32 or else F = Fl (Integer_32'First))
       --  F is an integer iff it can be converted to and back from integer
       and then Fl (Integer_32 (F)) = F)
   with Ghost;

   --  Determines if 64-bits integer I is representable as a (32-bits or
   --  64-bits, depending on the current instance of the generic) float
   function Is_Float (I : Integer_64) return Boolean is
      --  Protect against overflow in the conversion below
      ((I = Integer_64'First or else abs I <= Max_Fl_As_Integer_64_Int)
       --  F is a float iff it can be converted to and back from float
       and then Integer_64 (Fl (I)) = I)
   with Ghost;

   --  Determines if 32-bits integer I is representable as a (32-bits or
   --  64-bits, depending on the current instance of the generic) float
   function Is_Float (I : Integer_32) return Boolean is
      --  Protect against overflow in the conversion below
      ((I = Integer_32'First or else abs I <= Max_Fl_As_Integer_32_Int)
       --  F is a float iff it can be converted to and back from float
       and then Integer_32 (Fl (I)) = I)
   with Ghost;

   --  Determines if F represents an integer, i.e. its fractional part is zero
   function Is_Integer (F : Fl) return Boolean is
     --  Either the magnitude of F is such that there cannot be a fractional
     --  part that fits in the 24-bits or 53-bits significand/mantissa.
     (abs F >= 2.0**52
      --  Or rounding is the identity on F, obtained here by converting to a
      --  64-bits signed integer. Note the use of a lazy connective to avoid
      --  converting F to an integer if it is too large.
      or else Fl (Integer_64 (F)) = F)
   with Ghost;

   --------------------
   -- Rounding Error --
   --------------------

   --  Additions, substractions and multiplications are exact on floating point
   --  numbers which are integers if they are small enough to fit in the range
   --  where all integers are representable.

   package Integer_64_Conversions is new Signed_Conversions (Int);
   function Big (X : Int) return Big_Integer renames
     Integer_64_Conversions.To_Big_Integer;

   procedure Lemma_Integer_Add_Exact
     (Val1, Val2 : Fl; Int1, Int2 : Int)
   with
     Pre  =>
       Val1 = Fl (Int1) and then
       In_Range (Big (Int1), -Max_Int, Max_Int) and then
       Val2 = Fl (Int2) and then
       In_Range (Big (Int2), -Max_Int, Max_Int) and then
       In_Range (Big (Int1) + Big (Int2), -Max_Int, Max_Int),
     Post => Val1 + Val2 = Fl (Int1 + Int2);

   procedure Lemma_Integer_Sub_Exact
     (Val1, Val2 : Fl; Int1, Int2 : Int)
   with
     Pre  =>
       Val1 = Fl (Int1) and then
       In_Range (Big (Int1), -Max_Int, Max_Int) and then
       Val2 = Fl (Int2) and then
       In_Range (Big (Int2), -Max_Int, Max_Int) and then
       In_Range (Big (Int1) - Big (Int2), -Max_Int, Max_Int),
     Post => Val1 - Val2 = Fl (Int1 - Int2);

   procedure Lemma_Integer_Mul_Exact
     (Val1, Val2 : Fl; Int1, Int2 : Int)
   with
     Pre  =>
       Val1 = Fl (Int1) and then
       In_Range (Big (Int1), -Max_Int, Max_Int) and then
       Val2 = Fl (Int2) and then
       In_Range (Big (Int2), -Max_Int, Max_Int) and then
       In_Range (Big (Int1) * Big (Int2), -Max_Int, Max_Int),
     Post => Val1 * Val2 = Fl (Int1 * Int2);

   --  The IEEE standard mandates the result of additions, substractions,
   --  multiplications, and divisions to be the closest floating point number.
   --  This allows us to bound the result of these operation using the linear
   --  distance between two consecutive normalized floating-point numbers
   --  Epsilon and the absolute distance between two consecutive denormalized
   --  floating point numbers Eta.

   procedure Lemma_Rounding_Error_Add (Val1, Val2 : Fl) with
     Pre  =>
       Val1 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
       Val2 in Fl'First / 2.0 .. Fl'Last / 2.0,
     Post => abs (Real (Val1 + Val2) - (Real (Val1) + Real (Val2))) <=
         Epsilon * abs (Real (Val1) + Real (Val2)) + Eta;

   procedure Lemma_Rounding_Error_Sub (Val1, Val2 : Fl) with
     Pre  =>
       Val1 in Fl'First / 2.0 .. Fl'Last / 2.0 and then
       Val2 in Fl'First / 2.0 .. Fl'Last / 2.0,
     Post => abs (Real (Val1 - Val2) - (Real (Val1) - Real (Val2))) <=
         Epsilon * abs (Real (Val1) - Real (Val2)) + Eta;

   procedure Lemma_Rounding_Error_Mul (Val1, Val2 : Fl) with
     Pre  =>
       Val1 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
       Val2 in -Fl_Last_Sqrt .. Fl_Last_Sqrt,
     Post => abs (Real (Val1 * Val2) - (Real (Val1) * Real (Val2))) <=
         Epsilon * abs (Real (Val1) * Real (Val2)) + Eta;

   procedure Lemma_Rounding_Error_Div (Val1, Val2 : Fl) with
     Pre  =>
       Val1 in -Fl_Last_Sqrt .. Fl_Last_Sqrt and then
       Val2 in Fl'First .. -1.0 / Fl_Last_Sqrt
              | 1.0 / Fl_Last_Sqrt .. Fl'Last,
     Post => abs (Real (Val1 / Val2) - (Real (Val1) / Real (Val2))) <=
         Epsilon * abs (Real (Val1) / Real (Val2)) + Eta;

end SPARK.Lemmas.Floating_Point_Arithmetic;
