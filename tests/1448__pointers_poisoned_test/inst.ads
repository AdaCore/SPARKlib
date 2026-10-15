with Ada.Unchecked_Deallocation;
with SPARK.Pointers.Handles.Owning_Handles;
with SPARK.Pointers.Poisoned.Pointers;
with SPARK.Pointers.Poisoned.Views;

package Inst
  with SPARK_Mode
is
   pragma Unevaluated_Use_Of_Old (Allow);
   --  Needed where Array_Operations is instantiated: the pragma on the
   --  library unit does not reach the instance.

   type Object is record
      V : Natural;
   end record;

   type Index is range 1 .. 10;

   --  Each flavour lives in its own nested package: Views.Array_Operations
   --  refers to Is_Poisoned in the predicate of Readable_Array, so the parent
   --  instance has to be use-visible where it is instantiated, and the two
   --  Is_Poisoned would otherwise hide each other.

   package Pointer_Side is
      package Pointers is new SPARK.Pointers.Poisoned.Pointers (Object);
      use Pointers;

      function Id (O : Object) return Object
      is (O);
      function Create_Pointer is new Pointers.Create (Object, Id);

      type Pointer_Array is array (Index range <>) of Pointer;
      package Pointer_Arrays is new
        Pointers.Array_Operations (Index, Pointer_Array);

      --  Deep-copy operations: Create_Copy fills a fresh cell from an Object,
      --  Assign overwrites the value an existing cell designates.

      package Copy_Ops is new Pointers.Copy_Operations;

      --  A Pointer is subject to ownership, so handles over it are owning
      --  handles: Create_Handle builds one, and the caller reclaims the
      --  holder through the handle.

      subtype Object_Handle is SPARK.Pointers.Handles.Owning_Handles.Handle;
      --  Handle_Operations does not declare the handle type; it uses the one
      --  from Owning_Handles, so a client has to name that package itself.

      function Create_Object_Handle is new
        Pointers.Handle_Operations.Create_Handle (Object, Create_Pointer);
   end Pointer_Side;

   package Owning_Side is
      type Int_Access is access Integer;
      type Owning_Object is record
         D : Int_Access;
      end record;

      function Is_Reclaimed (O : Owning_Object) return Boolean
      is (O.D = null)
      with Ghost => Static;

      procedure Free is new Ada.Unchecked_Deallocation (Integer, Int_Access);

      package Pointers is new
        SPARK.Pointers.Poisoned.Pointers (Owning_Object, Is_Reclaimed);

      function Copy (O : Owning_Object) return Owning_Object
      with
        Global => null,
        Post   =>
          ((O.D = null) = (Copy'Result.D = null))
          and then (if O.D /= null then Copy'Result.D.all = O.D.all);

      package Copy_Ops is new Pointers.Copy_Operations (Copy);

      procedure Reclaim (P : in out Pointers.Pointer)
      with
        Pre  => (Static => not Pointers.Is_Poisoned (P)),
        Post => (Static => Pointers."=" (P, Pointers.Null_Pointer));
   end Owning_Side;

   package View_Side is
      package Views is new SPARK.Pointers.Poisoned.Views (Object);
      use Views;

      type Object_Array is array (Index range <>) of aliased Object;
      package View_Arrays is new Views.Array_Operations (Index, Object_Array);

      --  Create builds a view of a new value, which can fill a poisoned view

      function Make (V : Natural) return Object
      is ((V => V));
      function Create_View is new Views.Create (Natural, Make);
   end View_Side;

end Inst;
