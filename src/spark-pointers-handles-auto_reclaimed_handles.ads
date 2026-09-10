--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--
--  Handles for pointers reclaimed automatically when the last reference
--  disappears. They come in two flavors, one with a notion of weak handles
--  that can be used to avoid cycles in data structures and one without.
--
--  The Handle_Operations of the pointer units stores Reclaim'Access in the
--  reference counter. Where No_Implicit_Dynamic_Code is enforced, as in the
--  light runtime, it can therefore only be instantiated at library level:
--  taking 'Access of a subprogram nested in a subprogram needs a trampoline.

pragma Extensions_Allowed (On);

private with SPARK.Pointers.Ref_Counting;

package SPARK.Pointers.Handles.Auto_Reclaimed_Handles
  with SPARK_Mode
is

   generic
   package Without_Weak_Handles is

      type Handle is private
      with
        Default_Initial_Condition => null,
        Annotate                  =>
          (GNATprove, Predefined_Equality, "No_Equality");

      function "=" (X, Y : Handle) return Boolean is abstract;
      --  Handles have no identity of their own; compare them through the
      --  "=" of the Handle_Operations of the pointer unit they belong to.

      --  The package below is used to link these handles to the concrete
      --  pointer type they represent. They should never be called from
      --  user code.

      package Link_Utilities
        with SPARK_Mode => Off
      is

         type Data_Placeholder is null record;

         type Data_Placeholder_Access is access Data_Placeholder;
         for Data_Placeholder_Access'Size use Standard'Address_Size;
         --  A thin pointer: a handle is reinterpreted as a one-word
         --  pointer, which a fat pointer would break.

         type Reclamation_Procedure is
           access procedure (X : in out Data_Placeholder_Access);

         function Null_Handle (P : Reclamation_Procedure) return Handle;

         function Check_Reclamation
           (H : Handle; P : Reclamation_Procedure) return Boolean;
      end Link_Utilities;

   private
      pragma SPARK_Mode (Off);

      use Link_Utilities;

      procedure Reclaim
        (D : in out Data_Placeholder_Access; P : Reclamation_Procedure);

      package Ref_Counted_Data is new
        SPARK.Pointers.Ref_Counting
          (Data_Placeholder_Access,
           Reclamation_Procedure,
           Reclaim);

      type Handle is record
         Data : Ref_Counted_Data.Shared_Ref;
      end record;
      --  The Handle type is compatible with the reference counted types used
      --  in the Auto_Reclaimed library. An access type to a Handle can safely
      --  be reinterpreted as an access type to a shared pointer, and
      --  reclamation will be handled consistently, provided the Reclaim
      --  procedure matches.

   end Without_Weak_Handles;

   generic
   package With_Weak_Handles is

      type Strong_Handle is private
      with
        Default_Initial_Condition => null,
        Annotate                  =>
          (GNATprove, Predefined_Equality, "No_Equality");

      type Weak_Handle is private
      with
        Default_Initial_Condition => null,
        Annotate                  =>
          (GNATprove, Predefined_Equality, "No_Equality");

      --  Handles have no identity of their own; compare them through the
      --  "=" of the Handle_Operations of the pointer unit they belong to.

      function "=" (X, Y : Strong_Handle) return Boolean is abstract;

      function "=" (X, Y : Weak_Handle) return Boolean is abstract;

      --  The package below is used to link these handles to the concrete
      --  pointer type they represent. They should never be called from
      --  user code.

      package Link_Utilities
        with SPARK_Mode => Off
      is

         type Data_Placeholder is null record;

         type Data_Placeholder_Access is access Data_Placeholder;
         for Data_Placeholder_Access'Size use Standard'Address_Size;
         --  A thin pointer: a handle is reinterpreted as a one-word
         --  pointer, which a fat pointer would break.

         type Reclamation_Procedure is
           access procedure (X : in out Data_Placeholder_Access);

         function Null_Strong_Handle
           (P : Reclamation_Procedure) return Strong_Handle;

         function Check_Reclamation
           (H : Strong_Handle; P : Reclamation_Procedure) return Boolean;

         function Check_Reclamation
           (H : Weak_Handle; P : Reclamation_Procedure) return Boolean;

         function Same_Pointer (X, Y : Strong_Handle) return Boolean;

         function Same_Pointer (X, Y : Weak_Handle) return Boolean;

         procedure Downgrade (H : Strong_Handle; W : out Weak_Handle);

         procedure Upgrade
           (W : Weak_Handle; H : out Strong_Handle; Success : out Boolean);

      end Link_Utilities;

   private
      pragma SPARK_Mode (Off);

      use Link_Utilities;

      procedure Reclaim
        (D : in out Data_Placeholder_Access; P : Reclamation_Procedure);

      package Ref_Counted_Data is new
        SPARK.Pointers.Ref_Counting
          (Data_Placeholder_Access,
           Reclamation_Procedure,
           Reclaim);

      type Strong_Handle is record
         Data : Ref_Counted_Data.Strong_Ref;
      end record;

      type Weak_Handle is record
         Data : Ref_Counted_Data.Weak_Ref;
      end record;
      --  The Handle type is compatible with the reference counted types used
      --  in the Auto_Reclaimed library. An access type to a Handle can safely
      --  be reinterpreted as an access type to a shared pointer, and
      --  reclamation will be handled consistently, provided the Reclaim
      --  procedure matches.

   end With_Weak_Handles;

end SPARK.Pointers.Handles.Auto_Reclaimed_Handles;
