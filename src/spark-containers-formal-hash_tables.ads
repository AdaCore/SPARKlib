--  Copyright (C) 2004-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package declares the hash-table type used to implement hashed
--  containers.

with SPARK.Containers.Types; use SPARK.Containers.Types;

private package SPARK.Containers.Formal.Hash_Tables is
   pragma Pure;
   --  Declare Pure so this can be imported by Remote_Types packages

   generic
      type Node_Type is private;
   package Generic_Hash_Table_Types is

      type Nodes_Type is array (Count_Type range <>) of Node_Type;
      type Buckets_Type is array (Hash_Type range <>) of Count_Type;

      type Hash_Table_Type
        (Capacity : Count_Type;
         Modulus  : Hash_Type) is
      record
         Length  : Count_Type                  := 0;
         Free    : Count_Type'Base             := -1;
         Nodes   : Nodes_Type (1 .. Capacity);
         Buckets : Buckets_Type (1 .. Modulus) := [others => 0];
      end record;

   end Generic_Hash_Table_Types;

end SPARK.Containers.Formal.Hash_Tables;
