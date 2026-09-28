--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Extensions_Allowed (On);

--  This package is used both by automatically reclaimed pointers and by
--  their handles. To break the cycle and allow recursive types to be defined,
--  handles are instantiated with an empty placeholder instead of an actual
--  element type. An extra field, stored just after the pointer, is used to
--  store the reclamation procedure that will be used to reclaim the actual
--  object. It will depend on the pointer instance that uses the handle.
--  Automatically reclaimed handles and pointers are compatible in the sense
--  that a pointer to a handle can safely be converted to a pointer to an
--  object.

private generic

   type Element_Type is private;
   --  Type designated by the pointer

   type Extra_Data_Type is private;
   --  Type of an additional object that is stored just after the pointer.
   --  Automatically reclaimed handles use it to store an access to the
   --  reclamation procedure that will reclaim the real object instead of the
   --  placeholder.

   with procedure Reclaim (E : in out Element_Type; D : Extra_Data_Type);
   --  Procedure that reclaims the object E. It takes the extra data as a
   --  parameter so the handles can use it to reclaim the real data.

package SPARK.Pointers.Ref_Counting with SPARK_Mode => Off
is
   type Single_Count_And_Data is record
      Count : Natural := 0;
      Data  : Element_Type;
   end record;

   type Single_Count_And_Data_Access is access Single_Count_And_Data;

   type Shared_Ref is record
      Shared_Data : Single_Count_And_Data_Access;
      Extra_Data  : Extra_Data_Type;
   end record
   with
     Finalizable =>
       (Adjust => Adjust, Finalize => Finalize, Relaxed_Finalization => True);
   pragma No_Component_Reordering (Shared_Ref);

   procedure Adjust (P : in out Shared_Ref);
   procedure Finalize (P : in out Shared_Ref);

   type Dual_Count_And_Data is record
      Strong_Count : Natural := 0;
      Weak_Count   : Natural := 0;
      Data         : Element_Type;
   end record;

   type Dual_Count_And_Data_Access is access Dual_Count_And_Data;

   type Dual_Ref is record
      Shared_Data : Dual_Count_And_Data_Access;
      Extra_Data  : Extra_Data_Type;
   end record;
   pragma No_Component_Reordering (Dual_Ref);

   type Strong_Ref is record
      Counter : Dual_Ref;
   end record
   with
     Finalizable =>
       (Adjust => Adjust, Finalize => Finalize, Relaxed_Finalization => True);

   procedure Adjust (P : in out Strong_Ref);
   procedure Finalize (P : in out Strong_Ref);

   type Weak_Ref is record
      Counter : Dual_Ref;
   end record
   with
     Finalizable =>
       (Adjust => Adjust, Finalize => Finalize, Relaxed_Finalization => True);

   procedure Adjust (P : in out Weak_Ref);
   procedure Finalize (P : in out Weak_Ref);

   --  Conversions between the two kinds of reference. They are operations
   --  rather than reinterpretations of the same bits: going from one kind to
   --  the other moves a different counter, so a copy would count the wrong
   --  reference. Both expect a target that holds no reference yet.

   procedure Downgrade (P : Strong_Ref; R : out Weak_Ref);
   --  Make R a weak reference to the cell P designates

   procedure Upgrade (P : Weak_Ref; R : out Strong_Ref; Success : out Boolean);
   --  Make R a strong reference to the cell P designates, if that cell is
   --  still alive. Otherwise R designates nothing and Success is False.

end SPARK.Pointers.Ref_Counting;
