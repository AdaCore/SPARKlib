--
--  Copyright (C) 2022-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

package SPARK.Pointers
  with
    SPARK_Mode,
    Pure,
    Abstract_State =>
      (Memory_Addresses with External => (Async_Writers, Async_Readers)),
    Initializes    => Memory_Addresses
is
   pragma Elaborate_Body;
end SPARK.Pointers;
