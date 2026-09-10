--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Pointers.Explicit_Reclamation
  with SPARK_Mode
is

   --  Pointers with aliasing over an explicitly modelled memory. A cell stays
   --  valid until Dealloc is called on it; nothing is reclaimed automatically.

end SPARK.Pointers.Explicit_Reclamation;
