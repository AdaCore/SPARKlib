pragma SPARK_Mode (On);

with SPARK.Containers.Functional.Total_Maps;

package Inst is new
  SPARK.Containers.Functional.Total_Maps (Integer, Integer, 0, "=", "=");
