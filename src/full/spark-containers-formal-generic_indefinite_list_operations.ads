--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Containers.Formal.Generic_List_Operations;
with SPARK.Containers.Formal.Generic_List_Storage;
with SPARK.Pointers.Poisoned.Pointers;
with SPARK.Pointers.Poisoned.Pointers.Array_Operations;

private generic
   type Element_Type (<>) is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;
   with package Cells is new
     SPARK.Pointers.Poisoned.Pointers (Object => Element_Type, others => <>);
   with package Storage is new Generic_List_Storage (Cells.Pointer);
package SPARK.Containers.Formal.Generic_Indefinite_List_Operations with
    SPARK_Mode,
    Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);
   use Storage;
   use type Cells.Pointer;

   type Node_Array_Access is access Node_Array;
   type Elements_Array_Access is access Elements_Array;

   package Arrays is new Cells.Array_Operations (Count_Type, Elements_Array);

   function Is_Initialized (H : Cells.Pointer) return Boolean
   is (not Cells.Is_Poisoned (H) and then H /= Cells.Null_Pointer)
   with Ghost => Static, Global => null;

   function Constant_Access
     (H : aliased Cells.Pointer) return not null access constant Element_Type
   is (Cells.Constant_Reference (H))
   with Global => null, Pre => (Static => Is_Initialized (H)), Inline;

   procedure Fill (H : out Cells.Pointer; Item : Element_Type)
   with Global => null, Post => (Static => Is_Initialized (H)), Inline;

   procedure Copy_Elements
     (Target : in out Elements_Array;
      Source : Elements_Array;
      Nodes  : Node_Array;
      Free   : Count_Type'Base)
   with
     Global => null,
     Pre    =>
       (Static =>
          Valid_Links (Nodes, Free)
          and then Target'First = Source'First
          and then Target'Last = Source'Last
          and then Source'First = Nodes'First
          and then Source'Last = Nodes'Last
          and then (for all H of Target => Cells.Is_Reclaimed (H))
          and then
            (for all I in Source'Range =>
               (if (Free >= 0 or else I <= -(Free + 1))
                  and then Nodes (I).Prev /= -1
                then Is_Initialized (Source (I))
                else Cells.Is_Reclaimed (Source (I))))),
     Post   =>
       (Static =>
          (for all I in Target'Range =>
             (if (Free >= 0 or else I <= -(Free + 1))
                and then Nodes (I).Prev /= -1
              then Is_Initialized (Target (I))
              else Cells.Is_Reclaimed (Target (I)))));

   procedure Exchange (Elements : in out Elements_Array; I, J : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          I in Elements'Range
          and then J in Elements'Range
          and then I /= J
          and then Is_Initialized (Elements (I))
          and then Is_Initialized (Elements (J))),
     Post   =>
       (Static =>
          (for all K in Elements'Range =>
             Is_Initialized (Elements (K))
             = Is_Initialized (Arrays.Copy (Elements)'Old (K))
             and then
               Cells.Is_Reclaimed (Elements (K))
               = Cells.Is_Reclaimed (Arrays.Copy (Elements)'Old (K)))),
     Inline;

   package Ops is new
     Generic_List_Operations
       (Element_Type    => Element_Type,
        "="             => "=",
        Holder_Type     => Cells.Pointer,
        Storage         => Storage,
        Is_Initialized  => Is_Initialized,
        Is_Reclaimed    => Cells.Is_Reclaimed,
        Constant_Access => Constant_Access,
        Fill            => Fill,
        Move_Element    => Cells.Move,
        Reclaim         => Cells.Reclaim,
        Copy_Elements   => Copy_Elements,
        Exchange        => Exchange);

   function New_Capacity (Capacity, Size : Count_Type) return Count_Type
   with
     Global => null,
     Post   =>
       (Static =>
          New_Capacity'Result >= Capacity
          and then New_Capacity'Result >= Size
          and then New_Capacity'Result >= 100);
   --  Grow by doubling, with a minimum of 100 cells and saturation at the
   --  maximum count, until the requested size fits.

   procedure Resize
     (Nodes    : in out Node_Array_Access;
      Elements : in out Elements_Array_Access;
      Free     : in out Count_Type'Base;
      Size     : Count_Type)
   with
     Global => null,
     Pre    =>
       (Static =>
          (Nodes = null) = (Elements = null)
          and then
            (if Nodes = null
             then Free = -1 and then Size > 0
             else
               Valid_Links (Nodes.all, Free)
               and then Ops.Valid_Elements (Nodes.all, Elements.all, Free)
               and then Size > Nodes'Last)),
     Post   =>
       (Static =>
          Nodes /= null
          and then Elements /= null
          and then Nodes'First = 1
          and then Nodes'Last >= Size
          and then Valid_Links (Nodes.all, Free)
          and then Ops.Valid_Elements (Nodes.all, Elements.all, Free));
   --  Preserve node indices and move the owning cells to larger arrays.
   --  Newly exposed cells join an explicit free chain when needed.

private
   package Copies is new Cells.Copy_Operations;
end SPARK.Containers.Formal.Generic_Indefinite_List_Operations;
