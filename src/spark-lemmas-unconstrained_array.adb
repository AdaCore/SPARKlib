--
--  Copyright (C) 2016-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Style_Checks (Off);
package body SPARK.Lemmas.Unconstrained_Array
  with SPARK_Mode =>
#if SPARK_BODY_MODE="On"
  On
#else
  Off
#end if;
is
   pragma Style_Checks (On);

   procedure Lemma_Transitive_Order (Arr : A) is
   begin
      null;
   end Lemma_Transitive_Order;

end SPARK.Lemmas.Unconstrained_Array;
