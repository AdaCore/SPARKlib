with Instances; use Instances;

procedure Variable_Constant_Uninitialized with SPARK_Mode is
   X : aliased Relaxed;
   P : constant not null access constant Relaxed := X'Access;
   Y : constant not null access constant Word :=
     Variable_Checked.Convert_Constant_Access (P); -- @PRECONDITION:FAIL
begin
   null;
end Variable_Constant_Uninitialized;
