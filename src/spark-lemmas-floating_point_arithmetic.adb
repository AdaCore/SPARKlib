--
--  Copyright (C) 2017-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

package body SPARK.Lemmas.Floating_Point_Arithmetic
  with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
  On
#else
  Off
#end if;
is
   procedure Lemma_Add_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

   procedure Lemma_Div_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

   procedure Lemma_Div_Left_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

   procedure Lemma_Div_Right_Negative_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

   procedure Lemma_Integer_Add_Exact
     (Val1 : Fl;
      Val2 : Fl;
      Int1 : Int;
      Int2 : Int)
   is null;

   procedure Lemma_Integer_Mul_Exact
     (Val1 : Fl;
      Val2 : Fl;
      Int1 : Int;
      Int2 : Int)
   is null;

   procedure Lemma_Integer_Sub_Exact
     (Val1 : Fl;
      Val2 : Fl;
      Int1 : Int;
      Int2 : Int)
   is null;

   procedure Lemma_Mult_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

   procedure Lemma_Mult_By_Less_Than_One
     (Val1 : Fl;
      Val2 : Fl)
   is null;

   procedure Lemma_Mult_Right_Negative_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

   procedure Lemma_Rounding_Error_Add
     (Val1 : Fl;
      Val2 : Fl)
   is null;

   procedure Lemma_Rounding_Error_Div
     (Val1 : Fl;
      Val2 : Fl)
   is null;

   procedure Lemma_Rounding_Error_Mul
     (Val1 : Fl;
      Val2 : Fl)
   is null;

   procedure Lemma_Rounding_Error_Sub
     (Val1 : Fl;
      Val2 : Fl)
   is null;

   procedure Lemma_Sub_Is_Monotonic
     (Val1 : Fl;
      Val2 : Fl;
      Val3 : Fl)
   is null;

end SPARK.Lemmas.Floating_Point_Arithmetic;
