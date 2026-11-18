--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Array types and structural predicates for index-based doubly linked
--  lists. Links and element holders occupy separate arrays with matching
--  indices; zero denotes the end of a chain. Keeping elements out of link
--  cells lets proofs snapshot the structure without copying owning holders
--  or depending on element values.
--
--  Free nodes form a chain through Next, with Prev set to -1. A negative
--  free head instead marks the start of a never-used tail whose links need
--  not be initialized. The structural model restricts its memory to the
--  initialized prefix and describes the active and free chains, their
--  disjointness and their sizes. Element initialization and reclamation
--  are handled separately by Generic_List_Operations.

pragma Ada_2022;

with SPARK.Big_Integers;     use SPARK.Big_Integers;
with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;
with SPARK.Containers.Types; use SPARK.Containers.Types;
with SPARK.Higher_Order.Reachability;

private generic
   type Holder_Type is private;
package SPARK.Containers.Formal.Generic_List_Storage with
    SPARK_Mode,
    Always_Terminates
is

   subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

   type Node_Type is record
      Prev : Count_Type'Base;
      Next : Count_Type;
   end record
   with Relaxed_Initialization;

   function "=" (Left, Right : Node_Type) return Boolean is abstract;

   type Node_Array is array (Count_Type range <>) of Node_Type;
   function "=" (Left, Right : Node_Array) return Boolean is abstract;

   type Elements_Array is array (Count_Type range <>) of aliased Holder_Type;
   --  Aliased components can be passed to Constant_Access
   function "=" (Left, Right : Elements_Array) return Boolean is abstract;

   function Valid_Links
     (Nodes : Node_Array; Free : Count_Type'Base) return Boolean
   is (Nodes'First = 1
       and then Nodes'Last in Count_Type
       and then Free in -Nodes'Last - 1 .. Nodes'Last
       and then
         (for all I in 1 .. Nodes'Last =>
            (if Free >= 0 or else I <= -(Free + 1)
             then
               Nodes (I).Prev'Initialized
               and then Nodes (I).Next'Initialized
               and then
                 Nodes (I).Prev
                 in -1 .. (if Free >= 0 then Nodes'Last else -(Free + 1))
               and then
                 Nodes (I).Next
                 <= (if Free >= 0 then Nodes'Last else -(Free + 1)))))
   with Ghost => Static;
   --  Initialization and bounds of the touched link prefix

   package Structural_Model
     with Ghost => Static
   is
      package Memory_Index_Sets is new
        SPARK.Containers.Functional.Sets (Positive_Count_Type);

      package Memory_Index_Sequences is new
        SPARK.Containers.Functional.Infinite_Sequences
          (Positive_Count_Type,
           Use_Logical_Equality => True);

      type Nodes_Type_Base is array (Positive_Count_Type range <>) of Node_Type
      with Predicate => (for all N of Nodes_Type_Base => N.Next'Initialized);

      function Next_Link (N : Node_Type) return Count_Type
      is (N.Next)
      with
        Annotate => (GNATprove, Inline_For_Proof),
        Pre      => N.Next'Initialized;

      package Node_Reachability is new
        SPARK.Higher_Order.Reachability
          (Index_Type                            => Positive_Count_Type,
           No_Index                              => 0,
           Cell_Type                             => Node_Type,
           Memory_Type                           => Nodes_Type_Base,
           Next                                  => Next_Link,
           Memory_Index_Sets                     => Memory_Index_Sets,
           Memory_Index_Sequences                => Memory_Index_Sequences,
           Automatically_Instantiate_Definitions => False);

      use Node_Reachability;

      procedure Lemma_Free_List_Preserved
        (X : Count_Type'Base; M1, M2 : Nodes_Type_Base)
      with
        Ghost => Static,
        Pre   =>
          X < 0
          or else
            (X in M1'Range | 0
             and then Valid_Memory (M1)
             and then Valid_Memory (M2)
             and then Is_Acyclic (X, M1)
             and then
               (for all I of Reachable_Set (X, M1) =>
                  I <= M2'Last and then M1 (I).Next = M2 (I).Next)),
        Post  =>
          X < 0
          or else
            (Is_Acyclic (X, M2)
             and then
               Memory_Index_Sets."="
                 (Reachable_Set (X, M1), Reachable_Set (X, M2))
             and then
               Memory_Index_Sets.Length (Reachable_Set (X, M1))
               = Memory_Index_Sets.Length (Reachable_Set (X, M2)));
      --  Preserve an explicit free chain, or leave its negative encoding alone

   end Structural_Model;

   use Structural_Model;
   use Structural_Model.Node_Reachability;

   function Memory
     (Nodes : Node_Array; Free : Count_Type'Base) return Nodes_Type_Base
   is (if Free >= 0
       then Nodes_Type_Base (Nodes)
       else Nodes_Type_Base (Nodes (1 .. -(Free + 1))))
   with Ghost => Static, Pre => Valid_Links (Nodes, Free);
   --  Link memory restricted to the touched prefix

   function Active_Set
     (Nodes : Node_Array; Free : Count_Type'Base; First : Count_Type)
      return Memory_Index_Set
   is (Reachable_Set (First, Memory (Nodes, Free)))
   with
     Ghost => Static,
     Pre   =>
       Valid_Links (Nodes, Free)
       and then Valid_Memory (Memory (Nodes, Free))
       and then First in Memory (Nodes, Free)'Range | 0;

   function Active_List_Valid
     (Nodes : Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Last  : Count_Type;
      Count : Count_Type) return Boolean
   is (Is_Acyclic (First, Memory (Nodes, Free))
       and then
         Memory_Index_Sets.Length (Active_Set (Nodes, Free, First))
         = Big_Conversions.To_Big (Count)
       and then
         (for all I of Active_Set (Nodes, Free, First) => Nodes (I).Prev /= -1)
       and then
         (for all I of Active_Set (Nodes, Free, First) =>
            (if Nodes (I).Next = 0 then I = Last))
       and then
         (for all I of Active_Set (Nodes, Free, First) =>
            (if Nodes (I).Prev = 0
             then I = First
             else
               Memory_Index_Sets.Contains
                 (Active_Set (Nodes, Free, First), Nodes (I).Prev)
               and then Nodes (Nodes (I).Prev).Next = I))
       and then
         (if First = 0
          then Last = 0 and Count = 0
          else
            Nodes (First).Prev = 0
            and then Last in Memory (Nodes, Free)'Range
            and then Reachable (First, Memory (Nodes, Free), Last)
            and then Nodes (Last).Next = 0))
   with
     Ghost => Static,
     Pre   =>
       Valid_Links (Nodes, Free)
       and then Valid_Memory (Memory (Nodes, Free))
       and then First in Memory (Nodes, Free)'Range | 0;

   function Free_Chain_Valid
     (Nodes : Node_Array; Free : Count_Type'Base; Excluded : Memory_Index_Set)
      return Boolean
   is (Free < 0
       or else
         (Is_Acyclic (Free, Memory (Nodes, Free))
          and then
            (for all I of Reachable_Set (Free, Memory (Nodes, Free)) =>
               not Memory_Index_Sets.Contains (Excluded, I)
               and then Nodes (I).Prev = -1)))
   with
     Ghost => Static,
     Pre   =>
       Valid_Links (Nodes, Free) and then Valid_Memory (Memory (Nodes, Free));

   function Free_Count_Correct
     (Nodes : Node_Array; Free : Count_Type'Base; Used : Count_Type)
      return Boolean
   is (if Free < 0
       then Free = -Used - 1
       else
         Memory_Index_Sets.Length (Reachable_Set (Free, Memory (Nodes, Free)))
         = Big_Conversions.To_Big (Nodes'Last - Used))
   with
     Ghost => Static,
     Pre   =>
       Valid_Links (Nodes, Free) and then Valid_Memory (Memory (Nodes, Free));

   function Covered
     (Nodes : Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Extra : Extended_Index) return Boolean
   is (if Free >= 0
       then
         (for all I in Nodes'Range =>
            I = Extra
            or else
              (if Nodes (I).Prev = -1
               then Reachable (Free, Memory (Nodes, Free), I)
               else
                 Memory_Index_Sets.Contains
                   (Active_Set (Nodes, Free, First), I)))
       else
         (for all I in Memory (Nodes, Free)'Range =>
            I = Extra
            or else
              Memory_Index_Sets.Contains (Active_Set (Nodes, Free, First), I)))
   with
     Ghost => Static,
     Pre   =>
       Valid_Links (Nodes, Free)
       and then Valid_Memory (Memory (Nodes, Free))
       and then First in Memory (Nodes, Free)'Range | 0;

   function Structural_Invariant
     (Nodes : Node_Array;
      Free  : Count_Type'Base;
      First : Count_Type;
      Last  : Count_Type;
      Count : Count_Type) return Boolean
   is (Valid_Links (Nodes, Free)
       and then Valid_Memory (Memory (Nodes, Free))
       and then First in Memory (Nodes, Free)'Range | 0
       and then Active_List_Valid (Nodes, Free, First, Last, Count)
       and then Free_Chain_Valid (Nodes, Free, Active_Set (Nodes, Free, First))
       and then Free_Count_Correct (Nodes, Free, Count)
       and then Covered (Nodes, Free, First, 0))
   with Ghost => Static;

   function Is_Add
     (S1, S2 : Memory_Index_Set; E : Positive_Count_Type) return Boolean
   is (not Memory_Index_Sets.Contains (S1, E)
       and then Memory_Index_Sets.Contains (S2, E)
       and then Memory_Index_Sets."<=" (S1, S2)
       and then Memory_Index_Sets.Included_Except (S2, S1, E))
   with Ghost => Static;

end SPARK.Containers.Formal.Generic_List_Storage;
