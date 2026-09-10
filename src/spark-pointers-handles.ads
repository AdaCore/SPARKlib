--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Pointers.Handles
  with SPARK_Mode
is

   --  Handles are views of objects that are potentially subject to ownership
   --  that are hidden from SPARK. They can be used to create recursive data
   --  structures based on generics from the Pointers library.

end SPARK.Pointers.Handles;
