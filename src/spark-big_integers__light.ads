--
--  Copyright (C) 2022-2023, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit is provided as a replacement for the standard unit
--  Ada.Numerics.Big_Numbers.Big_Integers when only proof with SPARK is
--  intended. It cannot be used for execution, as all subprograms are marked
--  imported with no definition.

--  Contrary to Ada.Numerics.Big_Numbers.Big_Integers, this unit does not
--  depend on System or Ada.Finalization, which makes it more convenient for
--  use in run-time units.

with Ada.Numerics.Big_Numbers.Big_Integers_Ghost;

package SPARK.Big_Integers renames Ada.Numerics.Big_Numbers.Big_Integers_Ghost;
