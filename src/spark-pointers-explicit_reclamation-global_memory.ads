--
--  Copyright (C) 2022-2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Pointers with aliasing over a single, global modelled memory.
--
--  Reclamation is explicit: a cell stays valid until Dealloc is called on it.
--  Reclamation is not enforced by proof when a pointer is no longer
--  accessible by the program, nor even when the pointer type itself goes out
--  of scope. To have reclamation checks, use
--  Explicit_Reclamation.Separate_Memory instead.

with SPARK.Pointers.Abstract_Maps;
with SPARK.Pointers.Abstract_Sets;
with SPARK.Pointers.Handles.Plain_Handles;
with SPARK.Pointers.Parameter_Checks;

generic
   type Object (<>) is private;
   with
     function Is_Reclaimed (X : Object) return Boolean
     with Ghost => Static;
package SPARK.Pointers.Explicit_Reclamation.Global_Memory with
    SPARK_Mode,
    Always_Terminates,
    --  The memory is initially empty
    Initial_Condition => (Static => Is_Empty (Model (Memory)))
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  The Is_Reclaimed function shall only return True on reclaimed values

   package Reclamation_Checks is new
     Parameter_Checks.Is_Reclaimed_Checks (Object, Is_Reclaimed);

   package Definitions is

      type Pointer is private
      with Default_Initial_Condition => (Static => Pointer = Null_Pointer);

      Null_Pointer : constant Pointer;

      function "=" (P1, P2 : Pointer) return Boolean
      with Global => null, Annotate => (GNATprove, Logical_Equal);

      --  Operations on the cell designated by a pointer. They are used by the
      --  rest of the library to reach the full view of Pointer. They are
      --  incompatible with the ownership policy of SPARK and should not be
      --  used directly.

      function To_Access (P : Pointer) return not null access Object
      with SPARK_Mode => Off, Inline;

      function Allocate (O : Object) return Pointer
      with SPARK_Mode => Off, Inline;

      procedure Deallocate (P : in out Pointer)
      with SPARK_Mode => Off, Inline;

   private
      pragma SPARK_Mode (Off);

      type Object_Access is access Object;
      for Object_Access'Size use Standard'Address_Size;
      --  A thin pointer, so that the conversions in the handle layer are
      --  correct for an indefinite Object, for which GNAT would otherwise use
      --  a fat pointer.

      type Pointer is record
         P : Object_Access;
      end record;

      Null_Pointer : constant Pointer := (P => null);

      function "=" (P1, P2 : Pointer) return Boolean
      is (P1.P = P2.P);

      function To_Access (P : Pointer) return not null access Object
      is (P.P);

      function Allocate (O : Object) return Pointer
      is (Pointer'(P => new Object'(O)));
   end Definitions;

   subtype Pointer is Definitions.Pointer;

   Null_Pointer : Pointer renames Definitions.Null_Pointer;

   function "=" (P1, P2 : Pointer) return Boolean renames Definitions."=";

   --  Model for the memory, this is not executable

   package Memory_Model is

      package Pointer_To_Object_Maps is new
        Abstract_Maps (Pointer, Null_Pointer, Object);
      --  Use an abstract map rather than a functional map to avoid taking up
      --  memory space as the memory model cannot be ghost.

      type Memory_Type is limited private
      with
        Default_Initial_Condition =>
          (Static => Is_Empty (Model (Memory_Type)));

      subtype Memory_Map is Pointer_To_Object_Maps.Map;

      function Model (M : Memory_Type) return Memory_Map
      with Global => null;
      --  Model of a memory

      --  Whether the memory holds a cell for this pointer
      function In_Memory (M : Memory_Map; P : Pointer) return Boolean
      renames Pointer_To_Object_Maps.Has_Key;

      function Get
        (M : Memory_Map; P : Pointer) return not null access constant Object
      renames Pointer_To_Object_Maps.Get;

      function Is_Empty (M : Memory_Map) return Boolean
      renames Pointer_To_Object_Maps.Is_Empty;

      function Object_Logic_Equal (Left, Right : Object) return Boolean
      with
        Ghost    => Static,
        Import,
        Global   => null,
        Annotate => (GNATprove, Logical_Equal);
      --  Logical equality on objects. It is marked as import as it cannot be
      --  safely executed on most object types.

      --  Functions to make it easier to specify the frame of subprograms
      --  modifying a memory.

      package Pointer_Sets is new
        SPARK.Pointers.Abstract_Sets (Pointer, Null_Pointer);
      --  Use an abstract set rather than a functional set to avoid taking up
      --  memory space as the footprints cannot be ghost.

      type Footprint is new Pointer_Sets.Set;

      function None return Footprint renames Empty_Set;
      function Only (P : Pointer) return Footprint renames Singleton;

      function Writes (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is (for all P in M1 =>
            (if not Contains (Target, P) and In_Memory (M2, P)
             then Object_Logic_Equal (Get (M1, P).all, Get (M2, P).all)))
      with Ghost => Static, Global => null;

      function Allocates
        (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is ((for all P in M2 => Contains (Target, P) or In_Memory (M1, P))
          and
            (for all P in Target =>
               not In_Memory (M1, P) and In_Memory (M2, P)))
      with Ghost => Static, Global => null;

      function Deallocates
        (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is ((for all P in M1 => Contains (Target, P) or In_Memory (M2, P))
          and
            (for all P in Target =>
               not In_Memory (M2, P) and In_Memory (M1, P)))
      with Ghost => Static, Global => null;

   private
      pragma SPARK_Mode (Off);
      type Memory_Type is record
         Content : Memory_Map;
      end record;

      function Model (M : Memory_Type) return Memory_Map
      is (M.Content);

   end Memory_Model;
   use Memory_Model;

   Memory : aliased Memory_Type;
   --  Memory is the only object of type Memory_Type that can be constructed
   --  in SPARK. It is not an abstract state as it occurs as a parameter of
   --  calls to Constant_Reference and Reference functions so they can be
   --  traversal functions. It cannot be ghost for the same reason.
   --  For uses in partially proved code, it is important that no other object
   --  of this type is ever created.

   generic
      with function Copy (O : Object) return Object;
      --  A copy of the designated value

   package Copy_Operations with Always_Terminates
   is

      procedure Create_Copy (O : Object; P : out Pointer)
      with
        Global =>
          (In_Out => Global_Memory.Memory,
           Input  => SPARK.Pointers.Memory_Addresses),
        Post   =>
          (Static =>
             (Allocates (Model (Memory)'Old, Model (Memory), Only (P))
              and Deallocates (Model (Memory)'Old, Model (Memory), None)
              and Writes (Model (Memory)'Old, Model (Memory), None))
             and then In_Memory (Model (Memory), P)
             and then
               Object_Logic_Equal (Get (Model (Memory), P).all, Copy (O)));

      --  Primitives for classical pointer functionalities. Deref will copy the
      --  designated value.

      function Deref (P : Pointer) return Object
      with
        Global   => Global_Memory.Memory,
        Pre      => (Static => In_Memory (Model (Memory), P)),
        Post     =>
          (Static =>
             Object_Logic_Equal
               (Deref'Result, Copy (Get (Model (Memory), P).all))),
        Annotate => (GNATprove, Inline_For_Proof);

      procedure Assign (P : Pointer; O : Object)
      with
        Global => (In_Out => Global_Memory.Memory),
        Pre    =>
          (Static =>
             In_Memory (Model (Memory), P)
             and then Is_Reclaimed (Get (Model (Memory), P).all)),
        Post   =>
          (Static =>
             (Allocates (Model (Memory)'Old, Model (Memory), None)
              and Deallocates (Model (Memory)'Old, Model (Memory), None)
              and Writes (Model (Memory)'Old, Model (Memory), Only (P)))
             and then
               Object_Logic_Equal (Get (Model (Memory), P).all, Copy (O)));

   end Copy_Operations;

   generic
      type Input (<>) is private;
      with function Create_Object (X : Input) return Object;
   procedure Create (X : Input; P : out Pointer)
   with
     Global =>
       (In_Out => Global_Memory.Memory,
        Input  => SPARK.Pointers.Memory_Addresses),
     Post   =>
       (Static =>
          (Allocates (Model (Memory)'Old, Model (Memory), Only (P))
           and Deallocates (Model (Memory)'Old, Model (Memory), None)
           and Writes (Model (Memory)'Old, Model (Memory), None))
          and then In_Memory (Model (Memory), P)
          and then
            Object_Logic_Equal
              (Get (Model (Memory), P).all, Create_Object (X)));

   procedure Dealloc (P : in out Pointer)
   with
     Global  => (In_Out => Global_Memory.Memory),
     Depends => (P => null, Global_Memory.Memory => (Global_Memory.Memory, P)),
     Pre     =>
       (Static =>
          P = Null_Pointer
          or else
            (In_Memory (Model (Memory), P)
             and then Is_Reclaimed (Get (Model (Memory), P).all))),
     Post    =>
       (Static =>
          P = Null_Pointer
          and then Allocates (Model (Memory)'Old, Model (Memory), None)
          and then
            (if P'Old = Null_Pointer
             then Deallocates (Model (Memory)'Old, Model (Memory), None)
             else
               Deallocates (Model (Memory)'Old, Model (Memory), Only (P'Old)))
          and then Writes (Model (Memory)'Old, Model (Memory), None));

   --  Primitives to access the content of a memory cell directly. Ownership is
   --  used to preserve the link between the dereferenced value and the
   --  memory model.

   function Constant_Reference
     (Memory : Memory_Type; P : Pointer) return not null access constant Object
   with
     Global => null,
     Pre    => (Static => In_Memory (Model (Memory), P)),
     Post   =>
       (Static =>
          Object_Logic_Equal
            (Constant_Reference'Result.all, Get (Model (Memory), P).all));

   function At_End (X : access constant Object) return access constant Object
   is (X)
   with Ghost, Global => null, Annotate => (GNATprove, At_End_Borrow);

   function At_End (X : Memory_Type) return Memory_Type
   with Ghost, Global => null, Annotate => (GNATprove, At_End_Borrow), Import;

   function Reference
     (Memory : Memory_Type; P : Pointer) return not null access Object
   with
     Global => null,
     Pre    => (Static => In_Memory (Model (Memory), P)),
     Post   =>
       (Static =>
          Object_Logic_Equal
            (At_End (Reference'Result).all,
             Get (Model (At_End (Memory)), P).all)
          and then Allocates (Model (Memory), Model (At_End (Memory)), None)
          and then Deallocates (Model (Memory), Model (At_End (Memory)), None)
          and then Writes (Model (Memory), Model (At_End (Memory)), Only (P)));

   --  Abstract handles can be used to create recursive data structure. As the
   --  Pointer type is not subject to ownership, simple handles should be used
   --  here.

   package Handle_Operations is

      use SPARK.Pointers.Handles.Plain_Handles;

      function Valid_Handle (H : Handle) return Boolean
      with Import, Ghost => Static, Global => null;
      --  Abstract predicate: H is a valid handle for Pointer

      --  Conversion functions

      function To_Handle (P : Pointer) return Handle
      with
        Global => null,
        Post   =>
          (Static =>
             Valid_Handle (To_Handle'Result)
             and then Of_Handle (To_Handle'Result) = P);

      function Of_Handle (H : Handle) return Pointer
      with Global => null, Pre => (Static => Valid_Handle (H));

      function "=" (X, Y : Handle) return Boolean
      with
        Global   => null,
        Pre      => (Static => Valid_Handle (X) and Valid_Handle (Y)),
        Post     => (Static => "="'Result = (Of_Handle (X) = Of_Handle (Y))),
        Annotate => (GNATprove, Inline_For_Proof);

   end Handle_Operations;

end SPARK.Pointers.Explicit_Reclamation.Global_Memory;
