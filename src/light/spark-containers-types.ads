--
--  Copyright (C) 2022-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit is provided as a replacement for the unit Ada.Containers for
--  light runtimes when it is not included.

package SPARK.Containers.Types is
   pragma Pure;

   type Hash_Type is mod 2 ** 32;
   --  Represents the range of the result of a hash function

   type Count_Type is range 0 .. 2 ** 31 - 1;
   --  Represents the (potential or actual) number of elements of a container

   Capacity_Error : exception;
   --  Raised when the capacity of a container is exceeded

end SPARK.Containers.Types;
