with Instances; use Instances;

procedure Constant_Uninitialized with SPARK_Mode is
   X : aliased Relaxed;
   P : constant not null access constant Relaxed := X'Access;
   Y : constant not null access constant Word :=
     Constant_Checked.Convert_Constant_Access (P); -- @PRECONDITION:FAIL
begin
   null;
end Constant_Uninitialized;
