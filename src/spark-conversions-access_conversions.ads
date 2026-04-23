--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

--  This package provides functions that can be used to convert between access
--  types in SPARK. They are provided inside generics. There are four flavors,
--  two for access-to-constant types and two for access-to-variable type.
--  In each category, there a package for target types that are necessarily
--  valid and one for target types that might have invalid values. The value
--  designated by the result of the conversion has to be valid though.
--  The instances of Ada.Unchecked_Conversion in the specification of the
--  generic packages are used to force the analysis tool to generate the
--  appropriate checks to make sure that the access conversion is safe.

with Ada.Unchecked_Conversion;

package SPARK.Conversions.Access_Conversions
  with SPARK_Mode
is

   generic
      type Source_Type is private;
      type Target_Type is private;
   package Access_Constant_Conversions is

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      with Ghost => SPARKlib_Full, Annotate => (GNATprove, Logical_Equal);

      function Object_Conversion is new
        Ada.Unchecked_Conversion (Source_Type, Target_Type);
      --  Make sure that it is safe to reinterpret an object of type
      --  Source_Type as an object of type Target_Type.

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             (declare
                Target : constant Target_Type :=
                  Object_Conversion (Source.all);
              begin
                Target_Logical_Equal
                  (Convert_Constant_Access'Result.all, Target)));

   end Access_Constant_Conversions;

   generic
      type Source_Type is private;
      type Target_Type is private;
   package Access_Variable_Conversions is

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      with Ghost => SPARKlib_Full, Annotate => (GNATprove, Logical_Equal);

      function Object_Conversion is new
        Ada.Unchecked_Conversion (Source_Type, Target_Type);
      --  Make sure that it is safe to reinterpret an object of type
      --  Source_Type as an object of type Target_Type.

      function Object_Reverse_Conversion is new
        Ada.Unchecked_Conversion (Target_Type, Source_Type);
      --  Make sure that it is safe to reinterpret an object of type
      --  Target_Type as an object of type Source_Type. This is necessary for
      --  Reference.

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             (declare
                Target : constant Target_Type :=
                  Object_Conversion (Source.all);
              begin
                Target_Logical_Equal
                  (Convert_Constant_Access'Result.all, Target)));

      function At_End
        (X : access constant Source_Type) return access constant Source_Type
      is (X)
      with Ghost, Annotate => (GNATprove, At_End_Borrow);

      function At_End
        (X : access constant Target_Type) return access constant Target_Type
      is (X)
      with Ghost, Annotate => (GNATprove, At_End_Borrow);

      function Convert_Access
        (Source : not null access Source_Type)
         return not null access Target_Type
      with
        Global => null,
        Post   =>
          (SPARKlib_Full =>
             (declare
                Target : constant Target_Type :=
                  Object_Conversion (At_End (Source).all);
              begin
                Target_Logical_Equal
                  (At_End (Convert_Access'Result).all, Target)));

   end Access_Variable_Conversions;

   generic
      type Source_Type is private;
      type Target_Type is private;
   package Access_Constant_Conversions_Potentially_Invalid is

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      with Ghost => SPARKlib_Full, Annotate => (GNATprove, Logical_Equal);

      function Object_Conversion is new
        Ada.Unchecked_Conversion
          (Source_Type,
           -- incorrect formatting of aspects on generic instances
           --!format off
           Target_Type) with Potentially_Invalid;
           --!format on
      --  Make sure that it is safe to reinterpret an object of type
      --  Source_Type as a potentially invalid object of type Target_Type.

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      with
        Global => null,
        Pre    =>
          (SPARKlib_Defensive => Object_Conversion (Source.all)'Valid_Scalars),
        Post   =>
          (SPARKlib_Full =>
             (declare
                Target : constant Target_Type := Object_Conversion (Source.all)
                with Potentially_Invalid;
              begin
                Target'Valid_Scalars
                and then
                  Target_Logical_Equal
                    (Convert_Constant_Access'Result.all, Target)));

   end Access_Constant_Conversions_Potentially_Invalid;

   generic
      type Source_Type is private;
      type Target_Type is private;
   package Access_Variable_Conversions_Potentially_Invalid is

      function Target_Logical_Equal (X, Y : Target_Type) return Boolean
      with Ghost => SPARKlib_Full, Annotate => (GNATprove, Logical_Equal);

      function Object_Conversion is new
        Ada.Unchecked_Conversion
          (Source_Type,
           -- incorrect formatting of aspects on generic instances
           --!format off
           Target_Type) with Potentially_Invalid;
           --!format on
      --  Make sure that it is safe to reinterpret an object of type
      --  Source_Type as a potentially invalid object of type Target_Type.

      function Object_Reverse_Conversion is new
        Ada.Unchecked_Conversion (Target_Type, Source_Type);
      --  Make sure that it is safe to reinterpret an object of type
      --  Target_Type as an object of type Source_Type. This is necessary for
      --  Reference. We cannot support potentially invalid data here, as there
      --  is no way to constrain what can be stored in the borrowed object.

      function Convert_Constant_Access
        (Source : not null access constant Source_Type)
         return not null access constant Target_Type
      with
        Global => null,
        Pre    =>
          (SPARKlib_Defensive => Object_Conversion (Source.all)'Valid_Scalars),
        Post   =>
          (SPARKlib_Full =>
             (declare
                Target : constant Target_Type := Object_Conversion (Source.all)
                with Potentially_Invalid;
              begin
                Target'Valid_Scalars
                and then
                  Target_Logical_Equal
                    (Convert_Constant_Access'Result.all, Target)));

      function At_End
        (X : access constant Source_Type) return access constant Source_Type
      is (X)
      with Ghost, Annotate => (GNATprove, At_End_Borrow);

      function At_End
        (X : access constant Target_Type) return access constant Target_Type
      is (X)
      with Ghost, Annotate => (GNATprove, At_End_Borrow);

      function Convert_Access
        (Source : not null access Source_Type)
         return not null access Target_Type
      with
        Global => null,
        Pre    =>
          (SPARKlib_Defensive => Object_Conversion (Source.all)'Valid_Scalars),
        Post   =>
          (SPARKlib_Full =>
             (declare
                Target : constant Target_Type :=
                  Object_Conversion (At_End (Source).all)
                with Potentially_Invalid;
              begin
                Target'Valid_Scalars
                and then
                  Target_Logical_Equal
                    (At_End (Convert_Access'Result).all, Target)));

   end Access_Variable_Conversions_Potentially_Invalid;

end SPARK.Conversions.Access_Conversions;
