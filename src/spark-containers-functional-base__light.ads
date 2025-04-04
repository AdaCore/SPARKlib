--
--  Copyright (C) 2016-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This unit is provided as a replacement for the unit
--  SPARK.Containers.Functional.Base when only proof with SPARK is intended.
--  Memory is never reclaimed which makes it unfit for execution.
--
--  Contrary to SPARK.Containers.Functional.Base, this unit does not depend
--  on System or Ada.Finalization, which makes it more convenient for use in
--  run-time units.

pragma Ada_2022;

--  To allow reference counting on the base container

with SPARK.Containers.Types; use SPARK.Containers.Types;

private generic
   type Index_Type is (<>);
   --  To avoid Constraint_Error being raised at run time, Index_Type'Base
   --  should have at least one more element at the low end than Index_Type.

   type Element_Type (<>) is private;
   with function "=" (Left, Right : Element_Type) return Boolean is <>;

package SPARK.Containers.Functional.Base with
  SPARK_Mode => Off,
  Ghost
is

   subtype Extended_Index is Index_Type'Base range
     Index_Type'Pred (Index_Type'First) .. Index_Type'Last;

   type Container is private;

   function Ptr_Eq (C1 : Container; C2 : Container) return Boolean;
   --  Return True if C1 and C2 have the same content pointer

   function "=" (C1 : Container; C2 : Container) return Boolean;
   --  Return True if C1 and C2 contain the same elements at the same position

   function Length (C : Container) return Count_Type;
   --  Number of elements stored in C

   function Get (C : Container; I : Index_Type) return Element_Type;
   --  Access to the element at index I in C

   function Set
     (C : Container;
      I : Index_Type;
      E : Element_Type) return Container;
   --  Return a new container which is equal to C except for the element at
   --  index I, which is set to E.

   function Add
     (C : Container;
      I : Index_Type;
      E : Element_Type) return Container;
   --  Return a new container that is C with E inserted at index I

   function Remove (C : Container; I : Index_Type) return Container;
   --  Return a new container that is C without the element at index I

   function Find (C : Container; E : Element_Type) return Extended_Index;
   --  Return the first index for which the element stored in C is I. If there
   --  are no such indexes, return Extended_Index'First.

   function Find_Rev (C : Container; E : Element_Type) return Extended_Index;
   --  Return the last index for which the element stored in C is I. If there
   --  are no such indexes, return Extended_Index'First.

   --------------------
   -- Set Operations --
   --------------------

   function "<=" (C1 : Container; C2 : Container) return Boolean;
   --  Return True if every element of C1 is in C2

   function Num_Overlaps (C1 : Container; C2 : Container) return Count_Type;
   --  Return the number of elements that are in both C1 and C2

   function Union (C1 : Container; C2 : Container) return Container;
   --  Return a container which is C1 plus all the elements of C2 that are not
   --  in C1.

   function Intersection (C1 : Container; C2 : Container) return Container;
   --  Return a container which is C1 minus all the elements that are also in
   --  C2.

private

   --  Theoretically, each operation on a functional container implies the
   --  creation of a new container i.e. the copy of the array itself and all
   --  the elements in it. In the implementation, most of these copies are
   --  avoided by sharing between the containers.
   --
   --  A container stores its last used index. So, when adding an
   --  element at the end of the container, the exact same array can be reused.
   --  As a functionnal container cannot be modifed once created, there is no
   --  risk of unwanted modifications.
   --
   --                 _1_2_3_
   --  S             :    end       => [1, 2, 3]
   --                      |
   --                 |1|2|3|4|.|.|
   --                        |
   --  Add (S, 4, 4) :      end     => [1, 2, 3, 4]
   --
   --  The elements are also shared between containers as much as possible. For
   --  example, when something is added in the middle, the array is changed but
   --  the elementes are reused.
   --
   --                  _1_2_3_4_
   --  S             : |1|2|3|4|    => [1, 2, 3, 4]
   --                   |  \ \ \
   --  Add (S, 2, 5) : |1|5|2|3|4|  => [1, 5, 2, 3, 4]
   --
   --  To make this sharing possible, both the elements and the arrays are
   --  stored inside dynamically allocated access types which shall be
   --  deallocated when they are no longer used. The memory is managed using
   --  reference counting both at the array and at the element level.

   subtype Positive_Count_Type is Count_Type range 1 .. Count_Type'Last;

   type Reference_Count_Type is new Natural;

   type Element_Access is access all Element_Type;

   type Refcounted_Element is record
      Reference_Count : Reference_Count_Type;
      E_Access        : Element_Access;
   end record;

   type Refcounted_Element_Access is access Refcounted_Element;

   type Controlled_Element_Access is record
      Ref : Refcounted_Element_Access := null;
   end record;

   function Create
     (R : Refcounted_Element_Access)
      return Controlled_Element_Access
   is
     (Ref => R);

   function Element_Init (E : Element_Type) return Controlled_Element_Access;
   --  Use to initialize a refcounted element

   type Element_Array is
     array (Positive_Count_Type range <>) of Controlled_Element_Access;

   type Element_Array_Access_Base is access Element_Array;

   subtype Element_Array_Access is Element_Array_Access_Base;

   type Array_Base is record
     Reference_Count : Reference_Count_Type;
     Max_Length      : Count_Type;
     Elements        : Element_Array_Access;
   end record;

   type Array_Base_Access is access Array_Base;

   type Array_Base_Controlled_Access is record
      Base : Array_Base_Access;
   end record;

   function Create (B :  Array_Base_Access) return Array_Base_Controlled_Access
   is
     (Base => B);

   procedure Adjust
     (Controlled_Base : in out Array_Base_Controlled_Access);

   procedure Finalize
     (Controlled_Base : in out Array_Base_Controlled_Access);

   procedure Adjust
     (Ctrl_E : in out Controlled_Element_Access);

   procedure Finalize
     (Ctrl_E : in out Controlled_Element_Access);

   function Content_Init (L : Count_Type := 0)
                          return Array_Base_Controlled_Access;
   --  Used to initialize the content of an array base with length L

   type Container is record
      Length          : Count_Type := 0;
      Controlled_Base : Array_Base_Controlled_Access := Content_Init;
   end record;

end SPARK.Containers.Functional.Base;
