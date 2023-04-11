--
--  Copyright (C) 2016-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0
--

with SPARK.Lemmas.Unconstrained_Array;

package body SPARK.Lemmas.Constrained_Array
  with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
  On
#else
  Off
#end if;
is

   type A_Unconstrained is array (Index_Type range <>) of Element_T;

   package Test is new SPARK.Lemmas.Unconstrained_Array
     (Index_Type => Index_Type,
      Element_T  => Element_T,
      A          => A_Unconstrained,
      Less       => Less);

   procedure Lemma_Transitive_Order (Arr : A) is
      Arr_T : constant A_Unconstrained := A_Unconstrained (Arr);
   begin
      Test.Lemma_Transitive_Order (Arr_T);
   end Lemma_Transitive_Order;

end SPARK.Lemmas.Constrained_Array;
