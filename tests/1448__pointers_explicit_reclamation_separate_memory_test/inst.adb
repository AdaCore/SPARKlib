package body Inst
  with SPARK_Mode
is

   package body Owning is

      function Copy (O : Object) return Object is
      begin
         if O.D = null then
            return (D => null);
         else
            return (D => new Integer'(O.D.all));
         end if;
      end Copy;

   end Owning;

end Inst;
