--
--  Copyright (C) 2016-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit defines modular integer lemmas in a generic way, subject to the
--  definition of the following generic parameter:
--    Uint is a modular type
--
--  The SPARK lemma library comes with two instances of this generic unit, for
--  32bits and 64bits modular integer types. Both instances have been
--  completely proved, using manual proof in Coq where needed. It is
--  recommended to use these instances instead of instantiating your own
--  version of the generic, in order to benefit from the proofs already done on
--  the existing instances.

generic
   type Uint is mod <>;
package SPARK.Lemmas.Mod_Arithmetic
  with SPARK_Mode,
       Pure,
       Ghost,
       Always_Terminates
is

   pragma Warnings
     (Off, "postcondition does not check the outcome of calling");

   subtype Pos is Uint range 1 .. Uint'Last;

   procedure Lemma_Div_Is_Monotonic
     (Val1  : Uint;
      Val2  : Uint;
      Denom : Pos)
   with
     Global => null,
     Pre  => Val1 <= Val2,
     Post => Val1 / Denom <= Val2 / Denom;  --  MANUAL PROOF

   procedure Lemma_Div_Then_Mult_Bounds
     (Arg1 : Uint;
      Arg2 : Pos;
      Res  : Uint)
   with
     Global => null,
     Pre  => Res = (Arg1 / Arg2) * Arg2,
     Post => Res <= Arg1 and then
             Arg1 - Res < Arg2;

   procedure Lemma_Mult_Is_Monotonic
     (Val1   : Uint;
      Val2   : Uint;
      Factor : Uint)
   with
     Global => null,
     Pre  => Val1 <= Val2 and then
             (Factor = 0 or else Val2 <= Uint'Last / Factor),
     Post => Val1 * Factor <= Val2 * Factor;  --  MANUAL PROOF

   procedure Lemma_Mult_Is_Strictly_Monotonic
     (Val1   : Uint;
      Val2   : Uint;
      Factor : Pos)
   with
     Global => null,
     Pre  => Val1 < Val2 and then
             Val2 <= Uint'Last / Factor,
     Post => Val1 * Factor < Val2 * Factor;  --  MANUAL PROOF

   procedure Lemma_Mult_Protect
     (Arg1        : Uint;
      Arg2        : Uint;
      Upper_Bound : Uint)
   with
     Global => null,
     Pre  => Arg2 = 0 or else Arg1 <= Upper_Bound / Arg2,
     Post => Arg1 * Arg2 <= Upper_Bound;  --  MANUAL PROOF

   procedure Lemma_Mult_Scale
     (Val         : Uint;
      Scale_Num   : Uint;
      Scale_Denom : Pos;
      Res         : Uint)
   with
     Global => null,
     Pre  => Scale_Num <= Scale_Denom and then
             (Scale_Num = 0 or else Val <= Uint'Last / Scale_Num) and then
             Res = (Val * Scale_Num) / Scale_Denom,
     Post => Res <= Val;  --  MANUAL PROOF

   procedure Lemma_Mult_Then_Div_Is_Ident
     (Arg1 : Uint;
      Arg2 : Pos)
   with
     Global => null,
     Pre  => Arg1 <= Uint'Last / Arg2,
     Post => (Arg1 * Arg2) / Arg2 = Arg1;  --  MANUAL PROOF

   procedure Lemma_Mult_Then_Mod_Is_Zero
     (Arg1 : Uint;
      Arg2 : Pos)
   with
     Global => null,
     Pre  => Arg1 <= Uint'Last / Arg2,
     Post => (Arg1 * Arg2) mod Arg2 = 0;  --  MANUAL PROOF

end SPARK.Lemmas.Mod_Arithmetic;
