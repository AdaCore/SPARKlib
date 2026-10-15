--  A reclamation counter used only by the SPARK_Mode Off lifetime tests

package Counters
  with SPARK_Mode => Off
is

   Reclaimed : Natural := 0;

   procedure Bump;

end Counters;
