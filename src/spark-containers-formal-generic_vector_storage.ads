--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Array types and index conversions for vectors. Element holders occupy a
--  one-based array, independently of the vector's public index range. Holders
--  can contain inline elements or own separately allocated elements.
--
--  No_Index represents the empty vector and maps to array index zero.
--  Last_Count bounds the capacity; index conversions choose an arithmetic
--  type wide enough to avoid intermediate overflow. Element initialization
--  and reclamation are handled separately by Generic_Vector_Operations.

pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;

private generic
   Last_Count : Count_Type;

   type Index_Type is range <>;
   No_Index : Index_Type'Base;

   type Holder_Type is private;
   --  Storage for one element

package SPARK.Containers.Formal.Generic_Vector_Storage with
    SPARK_Mode,
    Always_Terminates
is

   subtype Extended_Index is Index_Type'Base range No_Index .. Index_Type'Last;

   subtype Capacity_Range is Count_Type range 0 .. Last_Count;

   subtype Array_Index is Count_Type range 1 .. Last_Count;

   type Elements_Array is array (Array_Index range <>) of aliased Holder_Type;
   --  Aliased components can be passed to Constant_Access

   function "=" (L, R : Elements_Array) return Boolean is abstract;

   function To_Array_Index (Index : Index_Type'Base) return Count_Type'Base
   is
      --  We know that
      --    Index >= Index_Type'First
      --  hence we also know that
      --    Index - Index_Type'First >= 0

      --  The issue is that even though 0 is guaranteed to be a value in
      --  the type Index_Type'Base, there's no guarantee that the difference
      --  is a value in that type. To prevent overflow we use the wider
      --  of Count_Type'Base and Index_Type'Base to perform intermediate
      --  calculations.

      --  The array index subtype for all container element arrays always
      --  starts with 1.

      (if Index_Type'Base'Last >= Count_Type'Pos (Count_Type'Last)
       then Count_Type'Base (Index - No_Index)
       else Count_Type'Base (Index) - Count_Type'Base (No_Index))
   with
     Pre =>
       Index >= No_Index
       and then Index <= No_Index + Count_Type'Pos (Last_Count);

end SPARK.Containers.Formal.Generic_Vector_Storage;
