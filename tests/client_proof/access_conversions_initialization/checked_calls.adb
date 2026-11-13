with Instances; use Instances;

procedure Checked_Calls with SPARK_Mode is
   use type Word;
   X : aliased Relaxed := (Value => 42);
begin
   declare
      P : constant not null access constant Relaxed := X'Access;
      Y : constant not null access constant Word :=
        Constant_Checked.Convert_Constant_Access (P);
   begin
      pragma Assert (Y.all = 42);
   end;
   declare
      P : not null access Relaxed := X'Access;
      Y : not null access Word := Variable_Checked.Convert_Access (P);
   begin
      Y.all := 43;
   end;
   pragma Assert (X.Value = 43);
   declare
      P : constant not null access constant Relaxed := X'Access;
      Y : constant not null access constant Positive_Word :=
        Constant_Invalid_Checked.Convert_Constant_Access (P);
   begin
      pragma Assert (Y.all = 43);
   end;
   declare
      P : not null access Relaxed := X'Access;
      Y : not null access Positive_Word :=
        Variable_Invalid_Checked.Convert_Access (P);
   begin
      Y.all := 44;
   end;
   pragma Assert (X.Value = 44);
   declare
      P : constant not null access constant Relaxed := X'Access;
      Y : constant not null access constant Word :=
        Variable_Checked.Convert_Constant_Access (P);
   begin
      pragma Assert (Y.all = 44);
   end;
   declare
      P : constant not null access constant Relaxed := X'Access;
      Y : constant not null access constant Positive_Word :=
        Variable_Invalid_Checked.Convert_Constant_Access (P);
   begin
      pragma Assert (Y.all = 44);
   end;
end Checked_Calls;
