--
--  Copyright (C) 2022-2024, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Lemmas.Float_Base is
   --  Workaround for link issue, see V419-027
   X : Integer;
   pragma Export (C, X, "spark__lemmas__float_arithmetic_E");
   Y : Integer;
   pragma Export (C, Y, "spark__lemmas__long_float_arithmetic_E");
end SPARK.Lemmas.Float_Base;
