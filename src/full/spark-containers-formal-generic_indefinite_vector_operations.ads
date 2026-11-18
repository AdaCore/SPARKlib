--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Operations for vectors of potentially indefinite elements held by
--  poisoned pointers. The caller supplies the pointer package and vector
--  storage; capacity management remains with the container.

pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Generic_Vector_Operations;
with SPARK.Containers.Formal.Generic_Vector_Storage;
with SPARK.Pointers.Poisoned.Pointers;
with SPARK.Pointers.Poisoned.Pointers.Array_Operations;

private generic
   Last_Count : Count_Type;

   type Index_Type is range <>;
   No_Index : Index_Type'Base;

   type Element_Type (<>) is private;

   with function "=" (Left, Right : Element_Type) return Boolean is <>;

   with package Cells is new
     SPARK.Pointers.Poisoned.Pointers (Object => Element_Type, others => <>);

   with package Storage is new
     SPARK.Containers.Formal.Generic_Vector_Storage
       (Last_Count  => Last_Count,
        Index_Type  => Index_Type,
        No_Index    => No_Index,
        Holder_Type => Cells.Pointer);

package SPARK.Containers.Formal.Generic_Indefinite_Vector_Operations with
    SPARK_Mode,
    Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);
   use Storage;
   use type Cells.Pointer;

   type Elements_Array_Access is access Elements_Array;

   package Arrays is new Cells.Array_Operations (Array_Index, Elements_Array);

   function Is_Initialized (P : Cells.Pointer) return Boolean
   is (not Cells.Is_Poisoned (P) and then P /= Cells.Null_Pointer)
   with Ghost => Static, Global => null;

   function Is_Reclaimed (P : Cells.Pointer) return Boolean
   renames Cells.Is_Reclaimed;

   function Constant_Access
     (H : aliased Cells.Pointer) return not null access constant Element_Type
   with Global => null, Pre => (Static => Is_Initialized (H)), Inline;

   procedure Exchange (E : in out Elements_Array; I, J : Count_Type'Base)
   with
     Global => null,
     Pre    =>
       (Static =>
          I in E'Range
          and then J in E'Range
          and then Is_Initialized (E (I))
          and then Is_Initialized (E (J))),
     Post   =>
       (Static =>
          (for all K in E'Range =>
             Is_Initialized (E (K)) = Is_Initialized (Arrays.Copy (E)'Old (K))
             and then
               Is_Reclaimed (E (K)) = Is_Reclaimed (Arrays.Copy (E)'Old (K)))),
     Inline;
   --  Exchange two readable cells without allocating or copying their elements

   procedure Fill (H : out Cells.Pointer; Item : Element_Type)
   with Global => null, Post => (Static => Is_Initialized (H)), Inline;
   --  Fill a reclaimed cell with an independent copy of Item

   procedure Fill (E : in out Elements_Array; Item : Element_Type)
   with
     Global => null,
     Pre    => (Static => (for all P of E => Is_Reclaimed (P))),
     Post   => (Static => (for all P of E => Is_Initialized (P)));

   procedure Reclaim (E : in out Elements_Array; First, Last : Count_Type'Base)
   with
     Global => null,
     Pre    =>
       (Static =>
          (if First <= Last then First in E'Range and Last in E'Range)
          and then (for all I in First .. Last => Is_Initialized (E (I)))),
     Post   =>
       (Static =>
          (for all I in E'Range =>
             (if I in First .. Last
              then Is_Reclaimed (E (I))
              else
                Is_Initialized (E (I))
                = Is_Initialized (Arrays.Copy (E)'Old (I))
                and then
                  Is_Reclaimed (E (I))
                  = Is_Reclaimed (Arrays.Copy (E)'Old (I)))));

   procedure Copy (Target : in out Elements_Array; Source : Elements_Array)
   with
     Global => null,
     Pre    =>
       (Static =>
          Target'Length = Source'Length
          and then (for all P of Source => Is_Initialized (P))
          and then (for all P of Target => Is_Reclaimed (P))),
     Post   => (Static => (for all P of Target => Is_Initialized (P)));

   function New_Capacity
     (Capacity, Size : Capacity_Range) return Capacity_Range
   with
     Global => null,
     Post   =>
       (Static =>
          New_Capacity'Result >= Capacity
          and then New_Capacity'Result >= Size),
     Inline;
   --  Choose the backing-array capacity, with a minimum of 100 cells or the
   --  maximum vector length. Double the current capacity below half that
   --  maximum; otherwise use the maximum. Always accommodate Size.

   package Ops is new
     SPARK.Containers.Formal.Generic_Vector_Operations
       (Last_Count      => Last_Count,
        Index_Type      => Index_Type,
        No_Index        => No_Index,
        Element_Type    => Element_Type,
        "="             => "=",
        Holder_Type     => Cells.Pointer,
        Storage         => Storage,
        Is_Initialized  => Is_Initialized,
        Is_Reclaimed    => Is_Reclaimed,
        Constant_Access => Constant_Access,
        Fill            => Fill,
        Move            => Cells.Move,
        Copy            => Copy,
        Exchange        => Exchange,
        Fill_Range      => Fill,
        Move_Range      => Arrays.Move,
        Reclaim         => Reclaim,
        Relocate        => Arrays.Relocate);

   procedure Resize
     (E    : in out Elements_Array_Access;
      Last : Extended_Index;
      Size : Capacity_Range := 0)
   with
     Global => null,
     Pre    =>
       (Static =>
          (if E = null
           then Last = No_Index
           else
             E'Last in Capacity_Range
             and then Ops.Valid_Elements (E.all, Last))),
     Post   =>
       (Static =>
          E /= null
          and then E'First = 1
          and then E'Last in Capacity_Range
          and then E'Last >= Size
          and then Ops.Valid_Elements (E.all, Last));
   --  Allocate a larger backing array and move the used prefix into it,
   --  preserving the elements and last index. The old array owns no cells
   --  after the transfer, so it can be deallocated.

private
   package Values is new Cells.Copy_Operations;
end SPARK.Containers.Formal.Generic_Indefinite_Vector_Operations;
