--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package provides a model of the address space, used to represent
--  operations that read the address of an object (the 'Address identity checks
--  performed by several bounded containers). The address space is modelled as
--  external state with asynchronous writers, so the prover never assumes a
--  stable or pure result for an address comparison: whether or not an
--  identity-based short-circuit or aliasing guard is taken, the surrounding
--  code must still be free of run-time errors.

package SPARK.Containers.Formal.Impl.Address_Space
  with
    SPARK_Mode,
    Abstract_State => (Address_State with External => Async_Writers),
    Initializes    => Address_State
is

   --  Generic comparison of object identities through their address. It is
   --  instantiated per container representation type. The body is SPARK_Mode
   --  => Off (the only place 'Address is read for a given representation) and
   --  reads the Address_State through its Global contract. Same_Object is a
   --  Volatile_Function, so the prover treats Same_Object (X, X) as an
   --  arbitrary boolean rather than a constant: proof must not depend on the
   --  outcome of the comparison.

   generic
      type Object_Type (<>) is private;
   package Address_Comparison with SPARK_Mode is

      function Object_Logical_Equal (Left, Right : Object_Type) return Boolean
      with
        Ghost    => Static,
        Global   => null,
        Annotate => (GNATprove, Logical_Equal);

      function Same_Object (Left, Right : Object_Type) return Boolean
      with
        Inline,
        Volatile_Function,
        Global => Address_Space.Address_State,
        Post   =>
          (Static =>
             (if Same_Object'Result then Object_Logical_Equal (Left, Right)));

   end Address_Comparison;

end SPARK.Containers.Formal.Impl.Address_Space;
