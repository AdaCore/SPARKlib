--
--  Copyright (C) 2022-2025, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

with Interfaces; use Interfaces;
with SPARK.Pointers.Abstract_Maps;
with SPARK.Pointers.Abstract_Sets;

generic
   type Object (<>) is private;
package SPARK.Pointers.Pointers_With_Aliasing_Separate_Memory with
  SPARK_Mode,
  Always_Terminates
is
   pragma Unevaluated_Use_Of_Old (Allow);

   --  Identity function on objects. As the library copies objects inside
   --  code annotated with SPARK_Mode => Off, we need to make sure that such
   --  copies are allowed by SPARK.
   function Check_No_Deep_Objects (O : Object) return Object is (O) with Ghost;

   --  Model for the memory, this is not executable

   package Memory_Model is
      type Address_Type is new Unsigned_64;
      --  Address type on 64 bits machines

      package Address_To_Object_Maps is new SPARK.Pointers.Abstract_Maps
        (Address_Type, 0, Object);
      --  Use an abstract map rather than a functional map to avoid taking up
      --  memory space as the memory model cannot be ghost.

      subtype Memory_Map is Address_To_Object_Maps.Map;

      type Memory_Type is new Address_To_Object_Maps.Ownership_Map;

      --  Whether an address designates some valid data in the memory
      function Valid (M : Memory_Map; A : Address_Type) return Boolean renames
        Address_To_Object_Maps.Has_Key;

      function Get (M : Memory_Map; A : Address_Type) return Object renames
        Address_To_Object_Maps.Get;

      function Copy (O : Object) return Object is (O);

      function Object_Logic_Equal (Left, Right : Object) return Boolean with
        Ghost,
        Import,
        Global => null,
        Annotate => (GNATprove, Logical_Equal);
      --  Logical equality on objects. It is marked as import as it cannot be
      --  safely executed on most object types.

      --  Functions to make it easier to specify the frame of subprograms
      --  modifying a memory.

      package Address_Sets is new SPARK.Pointers.Abstract_Sets
        (Address_Type, 0);
      --  Use an abstract set rather than a functional set to avoid taking up
      --  memory space as the footprints cannot be ghost.

      type Footprint is new Address_Sets.Set;

      function None return Footprint renames Empty_Set;
      function Only (A : Address_Type) return Footprint renames Singleton;

      function Writes
        (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is
        (for all A in Address_Type =>
           (if not Contains (Target, A) and Valid (M1, A) and Valid (M2, A)
            then Object_Logic_Equal (Get (M1, A), Get (M2, A))))
      with Ghost;

      function Allocates
        (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is
        ((for all A in Address_Type =>
            (if Valid (M2, A) then Contains (Target, A) or Valid (M1, A)))
         and (for all A in Address_Type =>
                  (if Contains (Target, A)
                   then not Valid (M1, A) and Valid (M2, A))))
      with Ghost;

      function Deallocates
        (M1, M2 : Memory_Map; Target : Footprint) return Boolean
      is
        ((for all A in Address_Type =>
            (if Valid (M1, A) then Contains (Target, A) or Valid (M2, A)))
         and (for all A in Address_Type =>
                  (if Contains (Target, A)
                   then not Valid (M2, A) and Valid (M1, A))))
      with Ghost;
   end Memory_Model;

   use Memory_Model;

   type Pointer is private with
     Default_Initial_Condition => Address (Pointer) = 0;
   function Null_Pointer return Pointer with
     Global => null,
     Post   => Address (Null_Pointer'Result) = 0;
   function Address (P : Pointer) return Address_Type with
     Global => null;

   function "=" (P1, P2 : Pointer) return Boolean with
     Global   => null,
     Post     => "="'Result = (Address (P1) = Address (P2)),
     Annotate => (GNATprove, Inline_For_Proof);

   procedure Create (Memory : in out Memory_Type; O : Object; P : out Pointer)
   with
     Global => null,
     Post   =>
       Valid (+Memory, Address (P))
         and then Allocates (Memory_Map'(+Memory)'Old,
                             +Memory,
                             Only (Address (P)))
         and then Deallocates (Memory_Map'(+Memory)'Old, +Memory, None)
         and then Writes (Memory_Map'(+Memory)'Old, +Memory, None)
         and then Object_Logic_Equal (Deref (Memory, P), Copy (O));

   --  Primitives for classical pointer functionalities. Deref will copy the
   --  designated value.

   function Deref (Memory : Memory_Type; P : Pointer) return Object with
     Global   => null,
     Pre      => Valid (+Memory, Address (P)),
     Post     => Deref'Result = Get (+Memory, Address (P)),
     Annotate => (GNATprove, Inline_For_Proof);

   procedure Assign (Memory : in out Memory_Type; P : Pointer; O : Object) with
     Global => null,
     Pre    => Valid (+Memory, Address (P)),
     Post   =>
       Object_Logic_Equal (Get (+Memory, Address (P)), Copy (O))
         and then Allocates (Memory_Map'(+Memory)'Old, +Memory, None)
         and then Deallocates (Memory_Map'(+Memory)'Old, +Memory, None)
         and then Writes (Memory_Map'(+Memory)'Old,
                          +Memory,
                          Only (Address (P)));

   procedure Dealloc (Memory : in out Memory_Type; P : in out Pointer) with
     Global => null,
     Pre    => Valid (+Memory, Address (P)) or P = Null_Pointer,
     Post   =>
       P = Null_Pointer
         and then Allocates (Memory_Map'(+Memory)'Old, +Memory, None)
         and then
           (if P'Old = Null_Pointer
            then Deallocates (Memory_Map'(+Memory)'Old, +Memory, None)
            else Deallocates
                   (Memory_Map'(+Memory)'Old, +Memory, Only (Address (P)'Old)))
         and then Writes (Memory_Map'(+Memory)'Old, +Memory, None);

   procedure Move_Memory (Source, Target : in out Memory_Type; F : Footprint)
   with
   --  Move addresses from a memory to another.
   --  This is correct because of the implicit invariant that 2 different
   --  memory objects are necessarily disjoint.
     Inline,
     Global => null,
     Pre    => (for all A in F => Valid (+Source, A)),
     Post   =>
       Allocates (Memory_Map'(+Source)'Old, +Source, None)
         and then Deallocates (Memory_Map'(+Source)'Old, +Source, F)
         and then Writes (Memory_Map'(+Source)'Old, +Source, None)
         and then Allocates (Memory_Map'(+Target)'Old, +Target, F)
         and then Deallocates (Memory_Map'(+Target)'Old, +Target, None)
         and then Writes (Memory_Map'(+Target)'Old, +Target, None)
         and then (for all A in F =>
                     Get (+Target, A) = Get (Memory_Map'(+Source)'Old, A));

   --  Primitives to access the content of a memory cell directly. Ownership is
   --  used to preserve the link between the dereferenced value and the
   --  memory model.

   function Constant_Reference
     (Memory : Memory_Type; P : Pointer)
      return not null access constant Object
   with
     Global => null,
     Pre    => Valid (+Memory, Address (P)),
     Post   =>
       Object_Logic_Equal
         (Constant_Reference'Result.all, Get (+Memory, Address (P)));

   function At_End (X : access constant Object) return access constant Object
   is
     (X)
   with
     Ghost,
     Annotate => (GNATprove, At_End_Borrow);

   function At_End (X : Memory_Type) return Memory_Type
   is
     (X)
   with
     Ghost,
     Annotate => (GNATprove, At_End_Borrow);

   function Reference
     (Memory : Memory_Type;
      P      : Pointer)
      return not null access Object
   with
     Global => null,
     Pre    => Valid (+Memory, Address (P)),
     Post   =>
       Object_Logic_Equal
         (At_End (Reference'Result).all,
          Get (+At_End (Memory), Address (P)))
         and then Allocates (+Memory, +At_End (Memory), None)
         and then Deallocates (+Memory, +At_End (Memory), None)
         and then Writes (+Memory,
                          +At_End (Memory),
                          Only (Address (P)));

private
   pragma SPARK_Mode (Off);
   type Pointer_B is access Object;
   function Eq (P1, P2 : Pointer_B) return Boolean renames "=";
   type Pointer is new Pointer_B;
end SPARK.Pointers.Pointers_With_Aliasing_Separate_Memory;
