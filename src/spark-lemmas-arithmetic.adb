--
--  Copyright (C) 2016-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package body SPARK.Lemmas.Arithmetic
  with SPARK_Mode => Off --  #BODYMODE
is

   procedure Lemma_Div_Is_Monotonic (Val1 : Int; Val2 : Int; Denom : Pos)
   is null;

   procedure Lemma_Div_Right_Is_Monotonic
     (Num : Int; Denom1 : Pos; Denom2 : Pos)
   is null;

   procedure Lemma_Exp_Is_Monotonic (Val1 : Nat; Val2 : Nat; Exp : Natural)
   is null;

   procedure Lemma_Exp_Is_Monotonic_2
     (Val : Pos; Exp1 : Natural; Exp2 : Natural)
   is null;

   procedure Lemma_Mod_Range (Arg1 : Int; Arg2 : Pos) is null;

   procedure Lemma_Mod_Symmetry (Arg1 : Int; Arg2 : Int) is null;

   procedure Lemma_Mult_Is_Monotonic (Val1 : Int; Val2 : Int; Factor : Nat)
   is null;

   procedure Lemma_Mult_Is_Strictly_Monotonic
     (Val1 : Int; Val2 : Int; Factor : Pos)
   is null;

   procedure Lemma_Mult_Protect (Arg1 : Int; Arg2 : Nat; Upper_Bound : Nat)
   is null;

   procedure Lemma_Mult_Scale
     (Val : Int; Scale_Num : Nat; Scale_Denom : Pos; Res : Int)
   is
      pragma Unreferenced (Scale_Num, Scale_Denom);
   begin
      if Res >= 0 then
         pragma Assert (abs Big (Res) <= abs Big (Val));
      else
         pragma Assert (abs Big (Res) <= abs Big (Val));
      end if;
   end Lemma_Mult_Scale;

   procedure Lemma_Mult_Then_Div_Is_Ident (Val1 : Int; Val2 : Pos) is null;

   procedure Lemma_Mult_Then_Mod_Is_Zero (Arg1 : Int; Arg2 : Pos) is null;

end SPARK.Lemmas.Arithmetic;
