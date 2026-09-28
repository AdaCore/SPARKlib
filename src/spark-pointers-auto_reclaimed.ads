--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Pointers.Auto_Reclaimed
  with SPARK_Mode
is

   --  Pointers whose designated data is reference counted and reclaimed
   --  automatically: a cell is freed when the last pointer designating it
   --  disappears. Reclamation is invisible in the model.

end SPARK.Pointers.Auto_Reclaimed;
