--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This level never needs to be enabled by users, but it should not depend on
--  Static to preserve reclamation checks.

pragma Assertion_Level (SPARKlib_Internal);

package SPARK.Pointers.Parameter_Checks
  with SPARK_Mode
is

   --  Check that the actual array type admits the same component states
   --  and bounds as an ordinary array of the index and component types.

   generic
      type Index_Type is (<>);
      type Element_Type is private;
      type Array_Type is array (Index_Type range <>) of Element_Type;

   package Array_Checks with Ghost => Static
   is

      type Local_Array is array (Index_Type range <>) of Element_Type;

      procedure Check_Array_Type
        (X : in out Array_Type; Y : in out Local_Array)
      with Global => null, Always_Terminates;

   end Array_Checks;

   --  Check that Is_Reclaimed implies reclamation for type T

   generic
      type T (<>) is private;
      with
        function Is_Reclaimed (X : T) return Boolean
        with Ghost => Static;

   package Is_Reclaimed_Checks
   is
      pragma Assertion_Policy (SPARKlib_Internal => Ignore);

      procedure Check_Reclamation
      with Global => null, Always_Terminates, Ghost => SPARKlib_Internal;

   end Is_Reclaimed_Checks;

   --  Check that Reclaim reclaims values of type T

   generic
      type T (<>) is private;
      with procedure Reclaim (X : in out T);

   package Reclamation_Checks
   is
      pragma Assertion_Policy (SPARKlib_Internal => Ignore);

      procedure Check_Reclamation
      with Global => null, Always_Terminates, Ghost => SPARKlib_Internal;

   end Reclamation_Checks;

   --  Check that objects of type T are preserved on assignment

   generic
      type T is private;

   package Assignment_Checks with Ghost => Static
   is

      function Logical_Eq (X, Y : T) return Boolean
      with Import, Global => null, Annotate => (GNATprove, Logical_Equal);

      procedure Check_Assignment (X : in out T; X_Save : T)
      with Global => null, Always_Terminates, Pre => Logical_Eq (X, X_Save);

   end Assignment_Checks;

end SPARK.Pointers.Parameter_Checks;
