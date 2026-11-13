with Instances; use Instances;

procedure Constant_PI_Uninitialized with SPARK_Mode is
   X : aliased Relaxed;
   P : constant not null access constant Relaxed := X'Access;
   Y : constant not null access constant Positive_Word :=
     Constant_Invalid_Checked.Convert_Constant_Access (P); -- @PRECONDITION:FAIL
begin
   null;
end Constant_PI_Uninitialized;
