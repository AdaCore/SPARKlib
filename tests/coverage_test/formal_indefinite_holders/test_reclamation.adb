with Ada.Finalization;
with Ada.Text_IO;
with SPARK.Containers.Formal.Indefinite_Holders;

--  Check that the holders reclaim their elements: each element is finalized
--  exactly once, when it is replaced or removed, or when its holder is
--  finalized. Also check that Move, Swap and Reference do not copy the
--  elements. The element type counts its objects and its copies for that. As
--  it is controlled, turn off proof.

procedure Test_Reclamation with SPARK_Mode => Off is

   Live : Integer := 0;
   --  Number of objects of type Item which have been initialized or adjusted
   --  and have not been finalized yet.

   Copies : Natural := 0;
   --  Number of copies of objects of type Item

   package Items is

      type Item is new Ada.Finalization.Controlled with record
         Value : Integer := 0;
      end record;

      overriding
      procedure Initialize (X : in out Item);
      overriding
      procedure Adjust (X : in out Item);
      overriding
      procedure Finalize (X : in out Item);

      function Make (Value : Integer) return Item;

   end Items;

   package body Items is

      ------------
      -- Adjust --
      ------------

      overriding
      procedure Adjust (X : in out Item) is
      begin
         Live := Live + 1;
         Copies := Copies + 1;
      end Adjust;

      --------------
      -- Finalize --
      --------------

      overriding
      procedure Finalize (X : in out Item) is
      begin
         Live := Live - 1;
      end Finalize;

      ----------------
      -- Initialize --
      ----------------

      overriding
      procedure Initialize (X : in out Item) is
      begin
         Live := Live + 1;
      end Initialize;

      ----------
      -- Make --
      ----------

      function Make (Value : Integer) return Item is
      begin
         return Result : Item do
            Result.Value := Value;
         end return;
      end Make;

   end Items;
   use Items;

   package Item_Holders is new
     SPARK.Containers.Formal.Indefinite_Holders (Item);
   use Item_Holders;


   procedure Assert (B : Boolean; S : String) is
   begin
      if not B then
         Ada.Text_IO.Put_Line (S);
      end if;
   end Assert;

   procedure Test_Copy is
      H : Holder := To_Holder (Make (1));
      G : Holder;
   begin
      Assert (Live = 1, "To_Holder keeps one live element");
      G := H;
      Assert (Live = 2, "Assignment creates a separate element");
      declare
         C : constant Holder := Copy (H);
      begin
         Assert (Live = 3, "Copy creates a separate element");
         Assert (C = H, "Copy preserves the value");
      end;
      Assert (Live = 2, "Scoped copy is reclaimed");
   end Test_Copy;

   procedure Test_Replacement is
      H : Holder := To_Holder (Make (1));
      G : Holder := To_Holder (Make (2));
   begin
      Assign (G, H);
      Assert (Live = 2, "Assign reclaims the old target element");
      G := H;
      Assert (Live = 2, "Assignment reclaims the old target element");
      Replace_Element (G, Make (3));
      Assert (Live = 2, "Replace_Element reclaims the old element");
      Assert (Element (G).Value = 3, "Replacement preserves the new value");
      Assert (Element (H).Value = 1, "Replacement does not affect the source");
   end Test_Replacement;

   procedure Test_Clear is
      H : Holder := To_Holder (Make (1));
   begin
      Clear (H);
      Assert (Live = 0, "Clear reclaims the element");
      Clear (H);
      Assert (Live = 0, "Repeated Clear does not reclaim twice");
   end Test_Clear;

   procedure Test_Move is
      H : Holder := To_Holder (Make (1));
      G : Holder := To_Holder (Make (2));
   begin
      Move (G, H);
      Assert (Live = 1, "Move reclaims the old target element");
      Assert (Is_Empty (H), "Move empties its source");
      Assert (Element (G).Value = 1, "Move preserves the source value");
   end Test_Move;

   procedure Test_Finalization is
   begin
      declare
         H : Holder := To_Holder (Make (1));
         G : Holder := H;
      begin
         Assert (Live = 2, "Both holders own an element before scope exit");
      end;
      Assert (Live = 0, "Scope exit reclaims both elements");
   end Test_Finalization;

   procedure Test_No_Copies is
      --  Executing postconditions can copy holders while observing them

      pragma Assertion_Policy (SPARKlib_Full => Ignore);

      package Plain_Holders is new
        SPARK.Containers.Formal.Indefinite_Holders (Item);
      use Plain_Holders;

      H : Plain_Holders.Holder := To_Holder (Make (5));
      G : Plain_Holders.Holder := To_Holder (Make (6));
      Copies_Before : constant Natural := Copies;
   begin
      Swap (G, H);
      Assert (Copies = Copies_Before and Live = 2,
              "Swap preserves both elements without copying");
      Move (H, G);
      Assert (Copies = Copies_Before and Live = 1,
              "Move reclaims the target without copying the source");
      Reference (H).Value := 7;
      Assert (Copies = Copies_Before and Live = 1,
              "Reference updates the element without copying");
      Assert (Constant_Reference (H).Value = 7,
              "Constant_Reference observes the updated value");
      Assert (Copies = Copies_Before,
              "Constant_Reference does not copy the element");
   end Test_No_Copies;

begin
   Test_Copy;
   Assert (Live = 0, "Copy test reclaims all elements");
   Test_Replacement;
   Assert (Live = 0, "Replacement test reclaims all elements");
   Test_Clear;
   Assert (Live = 0, "Clear test reclaims all elements");
   Test_Move;
   Assert (Live = 0, "Move test reclaims all elements");
   Test_Finalization;
   Test_No_Copies;
   Assert (Live = 0, "No-copy test reclaims all elements");
end Test_Reclamation;
