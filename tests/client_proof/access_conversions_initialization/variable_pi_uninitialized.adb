with Instances; use Instances;

procedure Variable_PI_Uninitialized with SPARK_Mode is
   X : aliased Relaxed;
   P : not null access Relaxed := X'Access;
   Y : not null access Positive_Word :=
     Variable_Invalid_Checked.Convert_Access (P); -- @PRECONDITION:FAIL
begin
   null;
end Variable_PI_Uninitialized;
