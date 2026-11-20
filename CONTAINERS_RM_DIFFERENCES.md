# Formal container differences from the Ada Reference Manual

This is a working record of deliberate choices in SPARKlib's formal container
specifications and implementations that differ from the corresponding Ada
containers. Extend it as the defensive-code review identifies further choices,
then incorporate the user-facing explanations into the SPARK User's Guide,
under **Modified API of Formal Containers** in `spark_libraries.rst`.

## Formal vectors: `Delete` by index

Ada RM A.18.2 permits `Index` in `First_Index (Container) ..
Last_Index (Container) + 1` for `Delete`, including the position immediately
after the last element. Deleting at that position has no effect. SPARKlib's
bounded and unbounded formal vectors deliberately require `Index` in
`First_Index (Container) .. Last_Index (Container)` for both the one-argument
and explicit-`Count` overloads. This keeps the one-argument postcondition
that `Length (Container) = Length (Container)'Old - 1` for every permitted
call. With `SPARKlib_Defensive` checks disabled, the bodies follow the RM
and treat `Index = Last_Index + 1` as a no-op, including when `Count = 0`
or the vector is empty.

## Bounded formal vectors: inserting another vector

Ada RM A.18.2 gives `Insert_Vector`, `Prepend_Vector`, and `Append_Vector` a
maximum-length condition. A.18.19 adds capacity conditions to several bounded
vector operations, but does not name these three. SPARKlib requires
`Length (Container) <= Capacity (Container) - Length (New_Item)` in their
public `SPARKlib_Defensive` preconditions. Since bounded-vector capacity is at
most `Last_Count`, this condition also implies the maximum-length bound. The
bodies raise `Capacity_Error` if the combined length is representable but
exceeds the fixed capacity while defensive checks are disabled.

## Bounded formal vectors: `Generic_Sorting.Merge`

The Ada RM's `Containers.Vectors.Generic_Sorting.Merge` requires that the
combined length fit `Maximum_Length`. The bounded-vector section does not add
a `Merge`-specific capacity precondition. SPARKlib deliberately requires
`Length (Source) <= Capacity (Target) - Length (Target)` in its public
`SPARKlib_Defensive` precondition. This ensures that the merged elements fit
the fixed capacity of `Target`; it can reject a call whose combined length
still fits the RM's `Maximum_Length`. With defensive checks disabled, the
implementation raises `Capacity_Error` when the combined length exceeds
`Target.Capacity` but remains representable. Parameter aliasing is covered by
the assumption below.

Ada RM references: A.18.2, *The Generic Package Containers.Vectors*, and
A.18.19, *The Generic Package Containers.Bounded_Vectors*.

## Formal unbounded ordered maps: existing keys at maximum length

The Ada RM requires `Length (Container) <= Count_Type'Last - 1` for
`Insert` and `Include`, even when the key already exists, and specifies
`Constraint_Error` if the condition fails. SPARKlib deliberately allows the
five-parameter `Insert`, as well as `Include`, when the key exists at maximum
length:
their public `SPARKlib_Defensive` precondition is
`Length (Container) < Count_Type'Last or Contains (Container, Key)`.

With defensive checks disabled, the implementation looks for an existing key
before attempting to grow a full map. The five-parameter `Insert` returns its
cursor with `Inserted = False`, and `Include` replaces the corresponding key
and element. If the key is absent at maximum length, `Resize` raises
`Constraint_Error`.

Ada RM reference: A.18.6, *The Generic Package Containers.Ordered_Maps*.

## Formal unbounded ordered sets: existing elements at maximum length

The Ada RM requires `Length (Container) <= Count_Type'Last - 1` for
`Insert` and `Include`, even when the element already exists, and specifies
`Constraint_Error` if the condition fails. SPARKlib deliberately allows the
four-parameter `Insert`, as well as `Include`, when the element exists at
maximum length: their public `SPARKlib_Defensive` precondition is
`Length (Container) < Count_Type'Last or Contains (Container, New_Item)`.

With defensive checks disabled, the implementation looks for an existing
element before attempting to grow a full set. The four-parameter `Insert`
returns its cursor with `Inserted = False`, and `Include` replaces the
corresponding element. If the element is absent at maximum length, `Resize`
raises `Constraint_Error`.

Ada RM reference: A.18.9, *The Generic Package Containers.Ordered_Sets*.

## Formal unbounded hashed maps: existing keys at maximum length

The Ada RM requires `Length (Container) <= Count_Type'Last - 1` for
`Insert` and `Include`, even when the key exists, and specifies
`Constraint_Error` on failure. It also says that `Insert` grows capacity first
when the table is full. SPARKlib deliberately allows the five-parameter
`Insert`, as well as `Include`, when the key exists at maximum length: their
public `SPARKlib_Defensive` precondition is
`Length (Container) < Count_Type'Last or Contains (Container, Key)`.

With defensive checks disabled, the implementation looks for an existing key
before attempting to grow a full map. The five-parameter `Insert` returns
its cursor with `Inserted = False`, and `Include` replaces the corresponding
key and element. If the key is absent at maximum length, `Resize` raises
`Constraint_Error`.

Ada RM reference: A.18.5, *The Generic Package Containers.Hashed_Maps*.

## Formal unbounded hashed sets: existing elements at maximum length

The Ada RM requires `Length (Container) <= Count_Type'Last - 1` for
`Insert` and `Include`, even when the element exists, and specifies
`Constraint_Error` on failure. It also says that `Insert` grows capacity first
when the table is full. SPARKlib deliberately allows the four-parameter
`Insert`, as well as `Include`, when the element exists at maximum length:
their public `SPARKlib_Defensive` precondition is
`Length (Container) < Count_Type'Last or Contains (Container, New_Item)`.

With defensive checks disabled, the implementation looks for an existing
element before attempting to grow a full set. The four-parameter `Insert`
returns its cursor with `Inserted = False`, and `Include` replaces the
corresponding element. If the element is absent at maximum length, `Resize`
raises `Constraint_Error`.

Ada RM reference: A.18.8, *The Generic Package Containers.Hashed_Sets*.

## Formal hashed sets: `Replace_Element` with an existing element

Ada RM A.18.7 and A.18.8 do not state this distinct-element restriction in
the `Replace_Element` precondition. SPARKlib adds it for bounded and
unbounded hashed sets: their public preconditions
allow `Replace_Element` when `New_Item` is equivalent to the element at
`Position`, or when the set does not contain an element equivalent to
`New_Item`. Replacing one element with an element equivalent to a different
element already in the set would violate the set's uniqueness invariant.

With `SPARKlib_Defensive` checks disabled, the shared hash-table helper still
checks for that duplicate and raises `Program_Error`. The check is
unconditional so that the replacement cannot silently introduce duplicate
equivalent elements.

## Bounded containers: capacity and maximum length

Keep the shorter public capacity precondition where it implies the RM's
maximum-length condition. Keep both implementation checks when defensive
checks are disabled: raise `Constraint_Error` first if the new length exceeds
the maximum, and `Capacity_Error` if it is representable but exceeds capacity.
Maximum-length overflow without capacity overflow is impossible, but both
exception paths are possible. This is the agreed policy.

## Defensive coverage convention for deleted cursors

For the defensive-code tests, a saved cursor whose element has been deleted is
treated as a cursor for which `Has_Element (Container, Position)` is false.
The tests then exercise the implementation's guard for that failed condition
with `SPARKlib_Defensive` disabled. When the corresponding RM operation
distinguishes `No_Element` from a non-`No_Element` cursor that fails
`Has_Element`, retain its exception distinction: `Constraint_Error` for
`No_Element` and `Program_Error` for failed `Has_Element`. Ada RM A.18.3
classifies use of an invalid cursor by these operations as erroneous execution;
the tests choose to exercise SPARKlib's defensive guards anyway.

## Assumptions: parameter aliasing

GNATprove checks that actual parameters do not alias when a corresponding
formal is writable. Public contracts therefore assume distinct objects for
`Assign` and `Move` across formal containers, `Splice` and
`Generic_Sorting.Merge` on lists, and `Insert_Vector`, `Prepend_Vector`,
`Append_Vector`, and `Generic_Sorting.Merge` on vectors. Same-object calls
from outside SPARK are outside these contracts; their runtime behavior varies
by operation. Address comparisons between two read-only inputs do not impose
this assumption.
