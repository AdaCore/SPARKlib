--  Reclamation observations for the execution-only test. The proved test
--  uses separate instances whose reclamation callbacks have no global effects.

package Counters
  with SPARK_Mode => Off
is

   Reclaimed : Natural := 0;

   procedure Bump;

end Counters;
