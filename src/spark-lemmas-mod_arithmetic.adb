--
--  Copyright (C) 2016-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Lemmas.Mod_Arithmetic
  with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
  On
#else
  Off
#end if;
is

   procedure Lemma_Div_Is_Monotonic
     (Val1  : Uint;
      Val2  : Uint;
      Denom : Pos)
   is null;

   procedure Lemma_Div_Then_Mult_Bounds
     (Arg1 : Uint;
      Arg2 : Pos;
      Res  : Uint)
   is
   begin
      pragma Assert (Res <= Arg1);
      pragma Assert (Arg1 - Res < Arg2);
   end Lemma_Div_Then_Mult_Bounds;

   procedure Lemma_Mult_Is_Monotonic
     (Val1   : Uint;
      Val2   : Uint;
      Factor : Uint)
   is null;

   procedure Lemma_Mult_Is_Strictly_Monotonic
     (Val1   : Uint;
      Val2   : Uint;
      Factor : Pos)
   is null;

   procedure Lemma_Mult_Protect
     (Arg1        : Uint;
      Arg2        : Uint;
      Upper_Bound : Uint)
   is null;

   procedure Lemma_Mult_Scale
     (Val         : Uint;
      Scale_Num   : Uint;
      Scale_Denom : Pos;
      Res         : Uint)
   is null;

   procedure Lemma_Mult_Then_Div_Is_Ident
     (Arg1 : Uint;
      Arg2 : Pos)
   is null;

   procedure Lemma_Mult_Then_Mod_Is_Zero
     (Arg1 : Uint;
      Arg2 : Pos)
   is null;

end SPARK.Lemmas.Mod_Arithmetic;
