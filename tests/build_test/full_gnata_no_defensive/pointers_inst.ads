pragma Extensions_Allowed (On);

with SPARK.Containers.Functional.Infinite_Sequences;
with SPARK.Containers.Functional.Sets;
with SPARK.Pointers.Abstract_Maps;
with SPARK.Pointers.Abstract_Reachability;
with SPARK.Pointers.Abstract_Sets;
with SPARK.Pointers.Auto_Reclaimed.Global_Memory;
with SPARK.Pointers.Auto_Reclaimed.Immutable;
with SPARK.Pointers.Auto_Reclaimed.Separate_Memory;
with SPARK.Pointers.Explicit_Reclamation.Global_Memory;
with SPARK.Pointers.Explicit_Reclamation.Separate_Memory;
with SPARK.Pointers.Handles.Auto_Reclaimed_Handles;
with SPARK.Pointers.Poisoned.Pointers;
with SPARK.Pointers.Poisoned.Views;

--  Check that it is possible to instantiate all the generics of the pointer
--  library, nested ones included.
--
--  This is a library-level package, not part of Main: in the light runtime,
--  the Handle_Operations of the auto-reclaimed units can only be instantiated
--  at library level, as they take 'Access of a subprogram declared in their
--  private part.

package Pointers_Inst with SPARK_Mode is
   pragma Unevaluated_Use_Of_Old (Allow);

   function Id (X : Integer) return Integer is (X);

   function Is_Reclaimed (Unused : Integer) return Boolean is (True)
   with Ghost => Static;

   --  Each unit is instantiated in its own package, as some nested generics
   --  need their parent instance to be use-visible, see below.

   --  Abstract models

   package Maps is new SPARK.Pointers.Abstract_Maps (Integer, 0, Integer);
   package Sets is new SPARK.Pointers.Abstract_Sets (Integer, 0);

   package Ghost_Containers with Ghost => Static is
      package Key_Sets is new SPARK.Containers.Functional.Sets (Integer);
      package Key_Sequences is new
        SPARK.Containers.Functional.Infinite_Sequences
          (Integer, Use_Logical_Equality => True);
   end Ghost_Containers;

   function Next (X : Integer) return Integer is (X)
   with Ghost => Static;

   package Reachability is new
     SPARK.Pointers.Abstract_Reachability
       (Memory_Maps   => Maps,
        Next          => Next,
        Key_Sets      => Ghost_Containers.Key_Sets,
        Key_Sequences => Ghost_Containers.Key_Sequences);

   --  Explicit reclamation

   package Explicit_Global is
      package Pointers is new
        SPARK.Pointers.Explicit_Reclamation.Global_Memory
          (Integer, Is_Reclaimed);
      package Copy is new Pointers.Copy_Operations (Id);
      procedure Create is new Pointers.Create (Integer, Id);
   end Explicit_Global;

   package Explicit_Separate is
      package Pointers is new
        SPARK.Pointers.Explicit_Reclamation.Separate_Memory
          (Integer, Is_Reclaimed);
      package Copy is new Pointers.Copy_Operations (Id);
      procedure Create is new Pointers.Create (Integer, Id);
   end Explicit_Separate;

   --  Auto reclaimed, immutable. The structural variants need an object
   --  holding handles to objects of the same type.

   package Auto_Reclaimed_Immutable is
      package Handles is new
        SPARK.Pointers.Handles.Auto_Reclaimed_Handles.Without_Weak_Handles;

      subtype Way is Positive range 1 .. 2;
      type Handle_Array is array (Way) of aliased Handles.Handle;

      type Cell is record
         Value    : Integer;
         Children : Handle_Array;
      end record;

      function Id (X : Cell) return Cell is (X);

      package Pointers is new SPARK.Pointers.Auto_Reclaimed.Immutable (Cell);
      package Copy is new Pointers.Copy_Operations (Id);
      function Create is new Pointers.Create (Cell, Id);
      package Handle_Ops is new Pointers.Handle_Operations (Handles);

      function Next
        (O : not null access constant Cell)
         return access constant Handles.Handle
      is (O.Children (1)'Access)
      with Global => null;
      package Variant is new Handle_Ops.Structural_Variant (Next);

      function Next
        (O : not null access constant Cell; W : Way)
         return access constant Handles.Handle
      is (O.Children (W)'Access)
      with Global => null;
      package Multiway_Variant is new
        Handle_Ops.Multiway_Structural_Variant (Way, Next);
   end Auto_Reclaimed_Immutable;

   --  Auto reclaimed, global and separate memory. The formal Witness of
   --  Witnessed_Conversions names Weak_Handle directly, so the handle package
   --  must be use-visible at the instantiation.

   package Auto_Reclaimed_Global is
      package Pointers is new
        SPARK.Pointers.Auto_Reclaimed.Global_Memory (Integer);
      use Pointers;
      package Copy is new Pointers.Copy_Operations (Id);
      procedure Create is new Pointers.Create (Integer, Id);

      package Handles is new
        SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;
      use Handles;
      package Handle_Ops is new Pointers.Handle_Operations (Handles);
      use Handle_Ops;

      function Is_Supported (P, X : Pointer) return Boolean
      is (X = P)
      with Ghost => Static;

      function Witness (H : Weak_Handle; X : Pointer) return Pointer
      is (X)
      with
        Pre  =>
          (SPARKlib_Full => Valid_Handle (H),
           Static        => Is_Supported (Peek (H), X)),
        Post => (Static => Peek (H) = Witness'Result);
      package Conversions is new
        Handle_Ops.Witnessed_Conversions (Pointer, Is_Supported, Witness);
   end Auto_Reclaimed_Global;

   package Auto_Reclaimed_Separate is
      package Pointers is new
        SPARK.Pointers.Auto_Reclaimed.Separate_Memory (Integer);
      use Pointers;
      package Copy is new Pointers.Copy_Operations (Id);
      procedure Create is new Pointers.Create (Integer, Id);

      package Handles is new
        SPARK.Pointers.Handles.Auto_Reclaimed_Handles.With_Weak_Handles;
      use Handles;
      package Handle_Ops is new Pointers.Handle_Operations (Handles);
      use Handle_Ops;

      function Is_Supported (P, X : Pointer) return Boolean
      is (X = P)
      with Ghost => Static;

      function Witness (H : Weak_Handle; X : Pointer) return Pointer
      is (X)
      with
        Pre  =>
          (SPARKlib_Full => Valid_Handle (H),
           Static        => Is_Supported (Peek (H), X)),
        Post => (Static => Peek (H) = Witness'Result);
      package Conversions is new
        Handle_Ops.Witnessed_Conversions (Pointer, Is_Supported, Witness);
   end Auto_Reclaimed_Separate;

   --  Poisoned.Views.Array_Operations refers to Is_Poisoned, so the parent
   --  instance must be use-visible at the instantiation.

   package Poisoned_Pointers is
      package Pointers is new
        SPARK.Pointers.Poisoned.Pointers (Integer, Is_Reclaimed);
      use Pointers;
      function Create is new Pointers.Create (Integer, Id);
      package Copy is new Pointers.Copy_Operations (Id);
      type Pointer_Array is array (Positive range <>) of Pointer;
      package Arrays is new
        Pointers.Array_Operations (Positive, Pointer_Array);
      function Create_Handle is new
        Pointers.Handle_Operations.Create_Handle (Integer, Create);
   end Poisoned_Pointers;

   package Poisoned_Views is
      package Views is new
        SPARK.Pointers.Poisoned.Views (Integer, Is_Reclaimed);
      use Views;
      type Integer_Array is array (Positive range <>) of aliased Integer;
      package Arrays is new Views.Array_Operations (Positive, Integer_Array);
   end Poisoned_Views;

end Pointers_Inst;
