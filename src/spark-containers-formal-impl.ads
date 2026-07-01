--
--  Copyright (C) 2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This package is the root of the shared implementation infrastructure of
--  the bounded formal containers: the address-space model (child
--  Address_Space) and the generic object-identity comparison (child
--  Address_Comparison), which model the 'Address checks used by the
--  SPARK_Mode => On implementations. The bare data-structure implementation
--  of each container does NOT live here; it lives in a private generic child
--  of the container itself, e.g. SPARK.Containers.Formal.Vectors.Impl.

package SPARK.Containers.Formal.Impl
  with SPARK_Mode, Pure
is
end SPARK.Containers.Formal.Impl;
