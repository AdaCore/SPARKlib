--  A reclamation counter. It is hidden from SPARK: the Reclaim actual of the
--  library has no Global contract, so the side effect has to stay invisible.
--  It is only used to check, at run time, that the library reclaims when the
--  last pointer to a cell disappears.

package Counters with SPARK_Mode => Off is

   Reclaimed : Natural := 0;

   procedure Bump;

end Counters;
