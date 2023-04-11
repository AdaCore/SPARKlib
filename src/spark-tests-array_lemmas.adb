--
--  Copyright (C) 2016-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with SPARK.Lemmas.Unconstrained_Array;
with SPARK.Lemmas.Constrained_Array;

package body SPARK.Tests.Array_Lemmas
  with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
  On
#else
  Off
#end if;
is
   pragma Warnings
     (Off, "postcondition does not check the outcome of calling");

   package Test_Uint is new SPARK.Lemmas.Unconstrained_Array
     (Index_Type => Integer,
      Element_T  => Integer,
      A          => Arr_Int_Unconstrained,
      Less       => "<");

   package Test_Ufloat is new SPARK.Lemmas.Unconstrained_Array
     (Index_Type => Integer,
      Element_T  => Float,
      A          => Arr_Float_Unconstrained,
      Less       => "<");

   --  For now, constrained array need a type conversion. In the future,
   --  there will be a constrained array library.

   procedure Test_Transitive_Order_Float (Arr : Arr_Float_Constrained) is
   begin
      Test_Ufloat.Lemma_Transitive_Order
        (Arr_Float_Unconstrained (Arr));
   end Test_Transitive_Order_Float;

   procedure Test_Transitive_Order_Float
     (Arr : Arr_Float_Unconstrained) is
   begin
      Test_Ufloat.Lemma_Transitive_Order (Arr);
   end Test_Transitive_Order_Float;

   procedure Test_Transitive_Order_Int (Arr : Arr_Int_Constrained) is
   begin
      Test_Uint.Lemma_Transitive_Order
        (Arr_Int_Unconstrained (Arr));
   end Test_Transitive_Order_Int;

   procedure Test_Transitive_Order_Int (Arr : Arr_Int_Unconstrained) is
   begin
      Test_Uint.Lemma_Transitive_Order (Arr);
   end Test_Transitive_Order_Int;

end SPARK.Tests.Array_Lemmas;
