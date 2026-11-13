with Ada.Finalization;
with SPARK.Containers.Formal.Unbounded_Holders;

--  Check that the holders reclaim their elements: each element is finalized
--  exactly once, when it is replaced or removed, or when its holder is
--  finalized. Also check that Move, Swap and Reference do not copy the
--  elements. The element type counts its objects and its copies for that. As
--  it is controlled, turn off proof.

procedure Reclamation_Test with SPARK_Mode => Off is

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
     SPARK.Containers.Formal.Unbounded_Holders (Item);
   use Item_Holders;

begin
   pragma Assert (Live = 0);

   declare
      H : Holder := To_Holder (Make (1));
      G : Holder;
   begin
      pragma Assert (Live = 1);

      --  A copy of a holder has its own element

      G := H;
      pragma Assert (Live = 2);

      declare
         C : constant Holder := Copy (H);
      begin
         pragma Assert (Live = 3);
         pragma Assert (C = H);
      end;
      pragma Assert (Live = 2);

      --  Assign and Replace_Element reclaim the previous element

      Assign (Target => G, Source => H);
      pragma Assert (Live = 2);

      Replace_Element (G, Make (2));
      pragma Assert (Live = 2);
      pragma Assert (Element (G).Value = 2);

      --  Reference gives access to the element in place

      Reference (G).Value := 3;
      pragma Assert (Live = 2);
      pragma Assert (Element (G).Value = 3);

      --  Swap keeps both elements

      Swap (G, H);
      pragma Assert (Live = 2);
      pragma Assert (Element (H).Value = 3);

      --  Move reclaims the element of its target

      Move (Target => G, Source => H);
      pragma Assert (Live = 1);
      pragma Assert (Is_Empty (H));
      pragma Assert (Element (G).Value = 3);

      --  Clear reclaims the element

      Clear (G);
      pragma Assert (Live = 0);
      Clear (G);
      pragma Assert (Live = 0);

      --  Leave an element in each holder at the end of the scope

      Replace_Element (G, Make (4));
      H := G;
      pragma Assert (Live = 2);
   end;

   --  The finalization of G and H has reclaimed their elements

   pragma Assert (Live = 0);

   --  Swap, Move and Reference do not copy the elements. Check it on an
   --  instance whose postconditions are not executed, as their evaluation
   --  copies the holders.

   declare
      pragma Assertion_Policy (SPARKlib_Full => Ignore);

      package Plain_Holders is new
        SPARK.Containers.Formal.Unbounded_Holders (Item);

      H : Plain_Holders.Holder := Plain_Holders.To_Holder (Make (5));
      G : Plain_Holders.Holder;

      Copies_Before : constant Natural := Copies;
   begin
      Plain_Holders.Swap (G, H);
      Plain_Holders.Move (Target => H, Source => G);
      Plain_Holders.Reference (H).Value := 6;
      pragma Assert (Copies = Copies_Before);
      pragma Assert (Live = 1);
      pragma Assert (Plain_Holders.Element (H).Value = 6);
   end;

   pragma Assert (Live = 0);
end Reclamation_Test;
