pragma Check_Policy (SPARKlib_Defensive => Disable);

with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with SPARK.Containers.Formal.Indefinite_Holders;

procedure Test is
   --  The postconditions assume non-overlapping arguments

   pragma Assertion_Policy (SPARKlib_Full => Ignore);
   pragma Warnings (Off, "writable actual for * overlaps with actual for *");

   Last_Label    : Unbounded_String := Null_Unbounded_String;
   First_Failure : Unbounded_String := Null_Unbounded_String;
   Failure_Count : Natural := 0;

   procedure Set_Label (Label : String) is
   begin
      Last_Label := To_Unbounded_String (Label);
   end Set_Label;

   procedure Record_Failure is
   begin
      Failure_Count := Failure_Count + 1;
      if Failure_Count = 1 then
         First_Failure := Last_Label;
      end if;
   end Record_Failure;

   procedure Check_Results is
   begin
      if Failure_Count /= 0 then
         raise Program_Error with
           Natural'Image (Failure_Count)
           & " defensive checks failed; first: "
           & To_String (First_Failure);
      end if;
   end Check_Results;

   package String_Holders is new
     SPARK.Containers.Formal.Indefinite_Holders (String);
   use String_Holders;

   procedure Test_Element is
      H : Holder;
   begin
      Set_Label ("Element on empty holder");
      begin
         declare
            Item : constant String := Element (H);
         begin
            null;
         end;
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Element;

   procedure Test_Constant_Reference is
      H : Holder;
   begin
      Set_Label ("Constant_Reference on empty holder");
      begin
         declare
            Item : constant String := Constant_Reference (H).all;
         begin
            null;
         end;
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Constant_Reference;

   procedure Test_Reference is
      H : Holder;
   begin
      Set_Label ("Reference on empty holder");
      begin
         declare
            Item : constant String := Reference (H).all;
         begin
            null;
         end;
      exception
         when Constraint_Error => return;
         when others => null;
      end;
      Record_Failure;
   end Test_Reference;

   procedure Test_Assign is
      H : Holder := To_Holder ("abc");
   begin
      Set_Label ("Assign with the same holder");
      Assign (H, H);
      if Is_Empty (H) or else Element (H) /= "abc" then
         Record_Failure;
      end if;
   exception
      when others => Record_Failure;
   end Test_Assign;

   procedure Test_Move is
      H : Holder := To_Holder ("abc");
   begin
      Set_Label ("Move with the same holder");
      Move (H, H);
      if Is_Empty (H) or else Element (H) /= "abc" then
         Record_Failure;
      end if;
   exception
      when others => Record_Failure;
   end Test_Move;

   procedure Test_Swap is
      H : Holder := To_Holder ("abc");
   begin
      Set_Label ("Swap with the same holder");
      Swap (H, H);
      if Is_Empty (H) or else Element (H) /= "abc" then
         Record_Failure;
      end if;
   exception
      when others => Record_Failure;
   end Test_Swap;

   procedure Test_Replace_Element is
      H : Holder := To_Holder ("abc");
   begin
      Set_Label ("Replace_Element with an alias of its element");
      Replace_Element (H, Constant_Reference (H).all);
      if Is_Empty (H) or else Element (H) /= "abc" then
         Record_Failure;
      end if;
   exception
      when others => Record_Failure;
   end Test_Replace_Element;

begin
   Test_Element;
   Test_Constant_Reference;
   Test_Reference;
   Test_Assign;
   Test_Move;
   Test_Swap;
   Test_Replace_Element;
   Check_Results;
end Test;
