--
--  Copyright (C) 2025-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

--  To allow reference counting

private with Ada.Finalization;

private generic
   type Element_Type (<>) is private;

package SPARK.Containers.Functional.Holder with SPARK_Mode => Off
is

   type Element_Access is access all Element_Type;

   type Element_Holder is private;

   function Create_Holder (E : Element_Type) return Element_Holder;

   function Get (E : Element_Holder) return not null Element_Access;

private

   type Reference_Count_Type is new Natural;

   type Refcounted_Element is record
      Reference_Count : Reference_Count_Type;
      E_Access        : Element_Access;
   end record;

   type Refcounted_Element_Access is access Refcounted_Element;

   type Element_Holder is new Ada.Finalization.Controlled with record
      Ref : Refcounted_Element_Access := null;
   end record;

   function Create (R : Refcounted_Element_Access) return Element_Holder
   is (Ada.Finalization.Controlled with Ref => R);

   procedure Adjust (Ctrl_E : in out Element_Holder);

   procedure Finalize (Ctrl_E : in out Element_Holder);

end SPARK.Containers.Functional.Holder;
