--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Auto_Reclaimed pointers to mutable data, over separate memories.
--
--  As Auto_Reclaimed.Global_Memory, but the memory is an object passed to the
--  operations rather than a global state. Two memory objects are necessarily
--  disjoint, so a call which takes one says by its profile alone which cells
--  it might have touched, and no frame condition is needed for the others.
--
--  A cell stays alive for as long as a strong reference designates it. It is
--  necessary to give one edge of each cycle a weak handle for a circular
--  structure to be automatically reclaimed when it is no longer accessible
--  from the program. This is not enforced by proof.

pragma Extensions_Allowed (On);

with SPARK.Pointers.Abstract_Maps;
with SPARK.Pointers.Abstract_Sets;
with SPARK.Pointers.Parameter_Checks;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;
private with SPARK.Pointers.Ref_Counting;

generic
   type Object (<>) is private;
   with procedure Reclaim (X : in out Object) is null;

package SPARK.Pointers.Auto_Reclaimed.Separate_Memory with
    SPARK_Mode,
    Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  The Reclaim procedure shall reclaim a value of type Object

   package Reclamation_Checks is new
     Parameter_Checks.Reclamation_Checks (Object, Reclaim);

   package Definitions is

      type Object_Access is access Object;
      for Object_Access'Size use Standard'Address_Size;
      --  A thin pointer. The handle layer reinterprets a value of this
      --  type as a one-word Handle, which would be wrong for a fat
      --  pointer, as GNAT uses for an access to an indefinite type.

      type Pointer is private
      with Default_Initial_Condition => (Static => Pointer = Null_Pointer);

      Null_Pointer : constant Pointer;

      function "=" (P1, P2 : Pointer) return Boolean
      with Global => null, Annotate => (GNATprove, Logical_Equal);

      --  Operations on the cell designated by a pointer. They are used by the
      --  rest of the library to reach the full view of Pointer. They are
      --  incompatible with the ownership policy of SPARK and should not be
      --  used directly.

      function Get_Object (P : Pointer) return Object_Access
      with SPARK_Mode => Off, Inline;

      procedure Set_Object (P : Pointer; O : Object_Access)
      with SPARK_Mode => Off, Inline;

      procedure Create_Cell (P : out Pointer; O : Object_Access)
      with SPARK_Mode => Off, Inline;

      procedure Reclaim_Object (D : in out Object_Access)
      with SPARK_Mode => Off;

   private
      pragma SPARK_Mode (Off);

      type No_Extra_Data is null record;

      procedure Reclaim (D : in out Object_Access; P : No_Extra_Data);

      package Ref_Counted_Data is new
        SPARK.Pointers.Ref_Counting (Object_Access, No_Extra_Data, Reclaim);
      use Ref_Counted_Data;

      type Pointer is record
         Data : Ref_Counted_Data.Strong_Ref;
      end record;

      Null_Pointer : constant Pointer :=
        (Data =>
           (Counter => (Shared_Data => null, Extra_Data => (null record))));

      function "=" (P1, P2 : Pointer) return Boolean
      is (P1.Data.Counter.Shared_Data = P2.Data.Counter.Shared_Data);

      function Get_Object (P : Pointer) return Object_Access
      is (P.Data.Counter.Shared_Data.Data);

   end Definitions;

   subtype Pointer is Definitions.Pointer;

   Null_Pointer : Pointer renames Definitions.Null_Pointer;

   function "=" (P1, P2 : Pointer) return Boolean renames Definitions."=";

   --  Model for the memory, this is not executable

   package Memory_Model is

      package Pointer_To_Object_Maps is new
        SPARK.Pointers.Abstract_Maps (Pointer, Null_Pointer, Object);
      --  Use an abstract map rather than a functional map to avoid taking up
      --  memory space as the memory model cannot be ghost.

      subtype Memory_Map is Pointer_To_Object_Maps.Map;

      type Memory_Type is new Pointer_To_Object_Maps.Owning_Map;

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
      is (for all A in M1 =>
            (if not Contains (Target, A) and In_Memory (M2, A)
             then Object_Logic_Equal (Get (M1, A).all, Get (M2, A).all)))
      with Ghost => Static, Global => null;

      function Allocates
        (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is ((for all A in M1 => In_Memory (M2, A))
          and (for all A in M2 => Contains (Target, A) or In_Memory (M1, A))
          and
            (for all A in Target =>
               not In_Memory (M1, A) and In_Memory (M2, A)))
      with Ghost => Static, Global => null;

      function Monotonous_Memory (M1, M2 : Memory_Map) return Boolean
      is (for all A in M1 => In_Memory (M2, A))
      with Ghost => Static, Global => null;
      --  As deallocation is invisible, most operations only add cells to the
      --  memory. Existing cells remain valid after the operation.

      function Moves (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is ((for all A in M1 => Contains (Target, A) or In_Memory (M2, A))
          and
            (for all A in M2 =>
               In_Memory (M1, A) and not Contains (Target, A)))
      with Ghost => Static, Global => null;
      --  The cells in Target have left this memory for another one. Unlike
      --  reclamation, which is invisible here, a move is visible in the
      --  model: M2 holds exactly what M1 held, minus Target.

   end Memory_Model;
   use Memory_Model;

   generic
      with function Copy (O : Object) return Object;
      --  A copy of the designated value

   package Copy_Operations with Always_Terminates
   is

      procedure Create_Copy
        (Memory : in out Memory_Type; O : Object; P : out Pointer)
      with
        Global => SPARK.Pointers.Memory_Addresses,
        Post   =>
          (Static =>
             P /= Null_Pointer
             and In_Memory (+Memory, P)
             and Object_Logic_Equal (Get (+Memory, P).all, Copy (O))
             and Allocates (Memory_Map'(+Memory)'Old, +Memory, Only (P))
             and Monotonous_Memory (Memory_Map'(+Memory)'Old, +Memory)
             and Writes (Memory_Map'(+Memory)'Old, +Memory, None));

      --  Primitives for classical pointer functionalities. Deref will copy the
      --  designated value.

      function Deref (Memory : Memory_Type; P : Pointer) return Object
      with
        Global   => null,
        Pre      => (Static => In_Memory (+Memory, P)),
        Post     =>
          (Static =>
             Object_Logic_Equal (Deref'Result, Copy (Get (+Memory, P).all))),
        Annotate => (GNATprove, Inline_For_Proof);

      procedure Assign (Memory : in out Memory_Type; P : Pointer; O : Object)
      with
        Global => null,
        Pre    => (Static => In_Memory (+Memory, P)),
        Post   =>
          (Static =>
             Object_Logic_Equal (Get (+Memory, P).all, Copy (O))
             and Allocates (Memory_Map'(+Memory)'Old, +Memory, None)
             and Writes (Memory_Map'(+Memory)'Old, +Memory, Only (P))
             and Monotonous_Memory (Memory_Map'(+Memory)'Old, +Memory));

   end Copy_Operations;

   generic
      type Input (<>) is private;
      with function Create_Object (X : Input) return Object;
   procedure Create (Memory : in out Memory_Type; X : Input; P : out Pointer)
   with
     Global => SPARK.Pointers.Memory_Addresses,
     Post   =>
       (Static =>
          P /= Null_Pointer
          and In_Memory (+Memory, P)
          and Object_Logic_Equal (Get (+Memory, P).all, Create_Object (X))
          and Allocates (Memory_Map'(+Memory)'Old, +Memory, Only (P))
          and Writes (Memory_Map'(+Memory)'Old, +Memory, None)
          and Monotonous_Memory (Memory_Map'(+Memory)'Old, +Memory));

   procedure Move_Memory (Source, Target : in out Memory_Type; F : Footprint)
   with
     --  Move cells from a memory to another. This is correct because of the
     --  implicit invariant that two different memory objects are disjoint.
     Inline,
     Global => null,
     Pre    => (Static => (for all A in F => In_Memory (+Source, A))),
     Post   =>
       (Static =>
          Moves (Memory_Map'(+Source)'Old, +Source, F)
          and then Writes (Memory_Map'(+Source)'Old, +Source, None)
          and then Allocates (Memory_Map'(+Target)'Old, +Target, F)
          and then Writes (Memory_Map'(+Target)'Old, +Target, None)
          and then
            (for all A in F =>
               Object_Logic_Equal
                 (Get (+Target, A).all,
                  Get (Memory_Map'(+Source)'Old, A).all)));

   --  Abstract handles can be used to create recursive data structure. As the
   --  Pointer type has automated reclamation, use handles with reclamation.
   --  Weak handles can be used to create a cyclic data structure while
   --  retaining automated reclamation.
   --  The handle package given as parameter should have the same
   --  accessibility level as the generic instance.

   generic
      with package Auto_Reclaimed_Handles is new
        SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;
   package Handle_Operations is

      use Auto_Reclaimed_Handles;

      function Valid_Handle (H : Strong_Handle) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function "=" (X, Y : Strong_Handle) return Boolean
      with
        Global   => null,
        Pre      => (SPARKlib_Full => Valid_Handle (X) and Valid_Handle (Y)),
        Post     =>
          (Static =>
             "="'Result = (Of_Strong_Handle (X) = Of_Strong_Handle (Y))),
        Annotate => (GNATprove, Inline_For_Proof);

      --  Conversion functions

      function To_Strong_Handle (P : Pointer) return Strong_Handle
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             Valid_Handle (To_Strong_Handle'Result)
             and then Of_Strong_Handle (To_Strong_Handle'Result) = P);

      function Of_Strong_Handle (H : Strong_Handle) return Pointer
      with Global => null, Pre => (SPARKlib_Full => Valid_Handle (H));

      function Valid_Handle (H : Weak_Handle) return Boolean
      with Ghost => SPARKlib_Full, Global => null;

      function Peek (H : Weak_Handle) return Pointer
      with
        Import,
        Ghost  => Static,
        Global => null,
        Pre    => (SPARKlib_Full => Valid_Handle (H));
      --  Ghost function returning the pointer associated to a weak handle. The
      --  returned value might be deallocated so it is not executable.

      function To_Weak_Handle (P : Pointer) return Weak_Handle
      with
        Global => null,
        Post   =>
          (SPARKlib_Full => Valid_Handle (To_Weak_Handle'Result),
           Static        => Peek (To_Weak_Handle'Result) = P);

      function To_Weak_Handle (H : Strong_Handle) return Weak_Handle
      with
        Global => null,
        Pre    => (SPARKlib_Full => Valid_Handle (H)),
        Post   =>
          (SPARKlib_Full => Valid_Handle (To_Weak_Handle'Result),
           Static        =>
             Peek (To_Weak_Handle'Result) = Of_Strong_Handle (H));

      function "=" (X, Y : Weak_Handle) return Boolean
      with
        Global   => null,
        Pre      => (SPARKlib_Full => Valid_Handle (X) and Valid_Handle (Y)),
        Post     => (Static => "="'Result = (Peek (X) = Peek (Y))),
        Annotate => (GNATprove, Inline_For_Proof);

      --  If the designated value is reclaimed, converting a weak handle to
      --  a strong pointer might fail. The two functions below return
      --  Null_Pointer in this case. They are volatile because the reclamation
      --  is not part of the model. To avoid the volatile effect, use the
      --  generic variants below.

      function Of_Weak_Handle (H : Weak_Handle) return Pointer
      with
        Volatile_Function,
        Global => SPARK.Pointers.Memory_Addresses,
        Pre    => (SPARKlib_Full => Valid_Handle (H)),
        Post   =>
          (Static =>
             Of_Weak_Handle'Result = Peek (H)
             or Of_Weak_Handle'Result = Null_Pointer);

      function To_Strong_Handle (H : Weak_Handle) return Strong_Handle
      with
        Volatile_Function,
        Global => SPARK.Pointers.Memory_Addresses,
        Pre    => (SPARKlib_Full => Valid_Handle (H)),
        Post   =>
          (SPARKlib_Full => Valid_Handle (To_Strong_Handle'Result),
           Static        =>
             Of_Strong_Handle (To_Strong_Handle'Result) = Peek (H)
             or Of_Strong_Handle (To_Strong_Handle'Result) = Null_Pointer);

      --  Avoid the nondeterminism of the two functions above by supplying a
      --  function that can produce the underlying pointer. It is never
      --  called; being able to construct it is enough to make the result
      --  safe.

      generic
         type Input (<>) is private;
         with
           function Has_Witness (P : Pointer; X : Input) return Boolean
           with Ghost => Static;
         --  Has_Witness (P, X) should hold exactly when the auxiliary data X
         --  is enough to reconstruct a live pointer to the cell P designates.
         --  It is the precondition under which Witness succeeds, and the
         --  obligation the client must discharge at each conversion call
         --  below.

         with
           function Witness (H : Weak_Handle; X : Input) return Pointer
           with
             Pre  =>
               (Static => Valid_Handle (H) and then Has_Witness (Peek (H), X)),
             Post => (Static => Peek (H) = Witness'Result);
         --  Return the pointer H designates, as a witness that the cell is
         --  still alive: a Pointer is a counted reference, so a caller able
         --  to produce one is holding the cell alive. Witness cannot be
         --  ghost, but it is never called, so it need not be efficient.

      package Witnessed_Conversions
      is

         function Of_Weak_Handle (H : Weak_Handle; X : Input) return Pointer
         with
           Global => null,
           Pre    =>
             (SPARKlib_Full => Valid_Handle (H),
              Static        =>
                Peek (H) = Null_Pointer or else Has_Witness (Peek (H), X)),
           Post   => (Static => Of_Weak_Handle'Result = Peek (H));

         function To_Strong_Handle
           (H : Weak_Handle; X : Input) return Strong_Handle
         with
           Global => null,
           Pre    =>
             (SPARKlib_Full => Valid_Handle (H),
              Static        =>
                Peek (H) = Null_Pointer or else Has_Witness (Peek (H), X)),
           Post   =>
             (SPARKlib_Full => Valid_Handle (To_Strong_Handle'Result),
              Static        =>
                Of_Strong_Handle (To_Strong_Handle'Result) = Peek (H));

      end Witnessed_Conversions;

   private
      pragma SPARK_Mode (Off);

      use Link_Utilities;

      procedure Reclaim (X : in out Data_Placeholder_Access);

      Reclamation_Access : constant Reclamation_Procedure := Reclaim'Access;

   end Handle_Operations;

end SPARK.Pointers.Auto_Reclaimed.Separate_Memory;
