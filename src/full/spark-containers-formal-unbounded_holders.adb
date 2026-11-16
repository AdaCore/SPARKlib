--
--  Copyright (C) 2026, AdaCore
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with System;
use type System.Address;

package body SPARK.Containers.Formal.Unbounded_Holders
  with SPARK_Mode => Off
is

   ---------
   -- "=" --
   ---------

   function "=" (Left, Right : Holder) return Boolean is
   begin
      if EHT.Is_Null (Left.Content) then
         return EHT.Is_Null (Right.Content);
      elsif EHT.Is_Null (Right.Content) then
         return False;
      else
         return
           EHT.Element_Access (Left.Content).all
           = EHT.Element_Access (Right.Content).all;
      end if;
   end "=";

   ------------
   -- Assign --
   ------------

   procedure Assign (Target : in out Holder; Source : Holder) is
   begin
      if Target'Address = Source'Address then
         return;
      end if;

      --  The assignment of the controlled component deallocates the element
      --  of Target, if any, and copies the element of Source, if any.

      Target.Content := Source.Content;
   end Assign;

   -----------
   -- Clear --
   -----------

   procedure Clear (Container : in out Holder) is
   begin
      EHT.Finalize (Container.Content);
   end Clear;

   ------------------------
   -- Constant_Reference --
   ------------------------

   function Constant_Reference
     (Container : Holder) return not null access constant Element_Type is
   begin
      return EHT.Element_Access (Container.Content);
   end Constant_Reference;

   ----------
   -- Copy --
   ----------

   function Copy (Source : Holder) return Holder is
   begin
      return Source;
   end Copy;

   -------------
   -- Element --
   -------------

   function Element (Container : Holder) return Element_Type is
   begin
      return EHT.Element (Container.Content);
   end Element;

   ------------------
   -- Empty_Holder --
   ------------------

   function Empty_Holder return Holder is
   begin
      return (Content => <>);
   end Empty_Holder;

   ------------------
   -- Formal_Model --
   ------------------

   package body Formal_Model is

      -------------------------
      -- Element_Logic_Equal --
      -------------------------

      function Element_Logic_Equal (Left, Right : Element_Type) return Boolean
      is
      begin
         return Left = Right;
      end Element_Logic_Equal;

   end Formal_Model;

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Holder) return Boolean is
   begin
      return EHT.Is_Null (Container.Content);
   end Is_Empty;

   ----------
   -- Move --
   ----------

   procedure Move (Target : in out Holder; Source : in out Holder) is
   begin
      if Target'Address = Source'Address then
         return;
      end if;

      EHT.Move (Target => Target.Content, Source => Source.Content);
   end Move;

   ---------------
   -- Reference --
   ---------------

   function Reference (Container : Holder) return not null access Element_Type
   is
   begin
      return EHT.Element_Access (Container.Content);
   end Reference;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out Holder; New_Item : Element_Type)
   is
      New_Content : EHT.Holder_Type;
   begin
      --  Copy New_Item before deallocating the element of Container, as
      --  New_Item might be a view of this element.

      EHT.Replace_Element (New_Content, New_Item);
      EHT.Move (Target => Container.Content, Source => New_Content);
   end Replace_Element;

   ----------
   -- Swap --
   ----------

   procedure Swap (Left, Right : in out Holder) is
      Left_Content : EHT.Holder_Type;
   begin
      --  Exchange the accesses to the elements. This has no effect if Left
      --  and Right are the same object.

      EHT.Move (Target => Left_Content, Source => Left.Content);
      EHT.Move (Target => Left.Content, Source => Right.Content);
      EHT.Move (Target => Right.Content, Source => Left_Content);
   end Swap;

   ---------------
   -- To_Holder --
   ---------------

   function To_Holder (New_Item : Element_Type) return Holder is
   begin
      return Result : Holder do
         EHT.Replace_Element (Result.Content, New_Item);
      end return;
   end To_Holder;

end SPARK.Containers.Formal.Unbounded_Holders;
