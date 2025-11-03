--
--  Copyright (C) 2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body SPARK.Containers.Functional.Holder with SPARK_Mode => Off is

   ------------
   -- Adjust --
   ------------

   procedure Adjust (Ctrl_E : in out Element_Holder) is
   begin
      if Ctrl_E.Ref /= null then
         Ctrl_E.Ref.Reference_Count := Ctrl_E.Ref.Reference_Count + 1;
      end if;
   end Adjust;

   ------------------
   -- Create_Holder --
   ------------------

   function Create_Holder (E : Element_Type) return Element_Holder
   is
      Refcounted_E : constant Refcounted_Element_Access :=
        new Refcounted_Element'(Reference_Count => 1,
                                E_Access        => new Element_Type'(E));
   begin
      return Create (Refcounted_E);
   end Create_Holder;

   ---------
   -- Get --
   ---------

   function Get
     (E : Element_Holder) return not null Element_Access
   is
     (E.Ref.E_Access);

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Ctrl_E : in out Element_Holder) is

      procedure Unchecked_Free_Ref is new Ada.Unchecked_Deallocation
        (Object => Refcounted_Element,
         Name   => Refcounted_Element_Access);

      procedure Unchecked_Free_Element is new Ada.Unchecked_Deallocation
        (Object => Element_Type,
         Name   => Element_Access);

   begin
      if Ctrl_E.Ref /= null then
         Ctrl_E.Ref.Reference_Count := Ctrl_E.Ref.Reference_Count - 1;
         if Ctrl_E.Ref.Reference_Count = 0 then
            Unchecked_Free_Element (Ctrl_E.Ref.E_Access);
            Unchecked_Free_Ref (Ctrl_E.Ref);
         end if;
         Ctrl_E.Ref := null;
      end if;
   end Finalize;

end SPARK.Containers.Functional.Holder;
