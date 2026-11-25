package body Clients
  with SPARK_Mode
is

   ---------------
   -- Duplicate --
   ---------------

   procedure Duplicate (Source : Holder; Target : out Holder) is
   begin
      Target := Empty_Holder;
      Assign (Target, Source);
   end Duplicate;

   -----------------
   -- Make_Circle --
   -----------------

   procedure Make_Circle (H : in out Shape_Holders.Holder; R : Natural) is
      S : constant Shape'Class := Shape_Holders.Element (H);
   begin
      Shape_Holders.Replace_Element
        (H, Circle'(X => S.X, Y => S.Y, Radius => R));
   end Make_Circle;

   -----------------
   -- Name_Length --
   -----------------

   function Name_Length (H : Holder) return Natural is
   begin
      return Constant_Reference (H).all'Length;
   end Name_Length;

   -------------
   -- Name_Or --
   -------------

   function Name_Or (H : Holder; Default : String) return String is
   begin
      if Is_Empty (H) then
         return Default;
      else
         return Element (H);
      end if;
   end Name_Or;

   ------------
   -- Radius --
   ------------

   function Radius (H : Shape_Holders.Holder) return Natural is
   begin
      return Circle (Shape_Holders.Constant_Reference (H).all).Radius;
   end Radius;

   ------------
   -- Rotate --
   ------------

   procedure Rotate (A, B, C : in out Holder) is
      Tmp : Holder;
   begin
      Move (Target => Tmp, Source => C);
      Swap (A, B);
      Swap (A, Tmp);
      Move (Target => C, Source => Tmp);
   end Rotate;

   ---------------
   -- Set_First --
   ---------------

   procedure Set_First (H : in out Holder; C : Character) is
   begin
      declare
         R : access String := Reference (H);
      begin
         R (R'First) := C;
      end;
   end Set_First;

   --------------
   -- Set_Name --
   --------------

   procedure Set_Name (H : in out Holder; Name : String) is
   begin
      Replace_Element (H, Name);
   end Set_Name;

   ---------------
   -- Translate --
   ---------------

   procedure Translate (H : in out Shape_Holders.Holder; DX : Integer) is
      S : Shape'Class := Shape_Holders.Element (H);
   begin
      S.X := S.X + DX;
      Shape_Holders.Replace_Element (H, S);
   end Translate;

   ------------------------
   -- Translate_In_Place --
   ------------------------

   procedure Translate_In_Place (H : in out Shape_Holders.Holder; DX : Integer)
   is
   begin
      declare
         S : access Shape'Class := Shape_Holders.Reference (H);
      begin
         S.X := S.X + DX;
      end;
   end Translate_In_Place;

end Clients;
