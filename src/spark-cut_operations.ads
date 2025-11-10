--
--  Copyright (C) 2022-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  By and So are connectors used to manually help the proof of assertions by
--  introducing intermediate steps. They can only be used inside pragmas
--  Assert or Assert_And_Cut. They are handled in the following way:
--
--  *  If A and B are two boolean expressions, proving By (A, B) requires
--     proving B, the premise, and then A assuming B, the side-condition. When
--     By (A, B) is assumed on the other hand, we only assume A. B is used
--     for the proof, but is not visible afterward.
--
--  *  If A and B are two boolean expressions, proving So (A, B) requires
--     proving A, the premise, and then B assuming A, the side-condition. When
--     So (A, B) is assumed both A and B are assumed to be true.
--

package SPARK.Cut_Operations
  with SPARK_Mode, Always_Terminates
is

   function By (Consequence, Premise : Boolean) return Boolean
   with Ghost, Global => null;

   function So (Premise, Consequence : Boolean) return Boolean
   with Ghost, Global => null;

end SPARK.Cut_Operations;
