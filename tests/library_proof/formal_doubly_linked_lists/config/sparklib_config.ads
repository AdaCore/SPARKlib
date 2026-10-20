--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Expose the list implementation while keeping reachability abstract.

package SPARKlib_Config
  with SPARK_Mode, Pure
is

   Body_Mode              : constant Boolean := True;
   Reachability_Body_Mode : constant Boolean := False;

end SPARKlib_Config;
