--
--  Copyright (C) 2024-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
with Ada.Strings.Hash;
with SPARK.Containers.Types; use SPARK.Containers.Types;

package SPARK.Containers.Hash
  with SPARK_Mode, Pure
is

   function String_Hash (S : String) return Hash_Type renames Ada.Strings.Hash;

   procedure String_Hash_Equivalent (X, Y : String)
   with
     Always_Terminates,
     Ghost  => Static,
     Global => null,
     Pre    => X = Y,
     Post   => String_Hash (X) = String_Hash (Y);
   --  If A and B are strings such that A equals B, String_Hash (A) equals
   --  String_Hash (B), as per the Ada reference manual A.4.9.

end SPARK.Containers.Hash;
