--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Pointers.Poisoned
  with SPARK_Mode
is

   --  Pointers with a poisoned value, representing a value that has been
   --  moved out of and cannot be read. They relax the ownership policy of
   --  SPARK, making it possible to reason about partially moved structures.
   --  They are useful in particular for arrays, which are handled imprecisely
   --  by the borrow checker.

end SPARK.Pointers.Poisoned;
