--
--  Copyright (C) 2022-2026, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

with Ada.Unchecked_Deallocation;

package body SPARK.Containers.Formal.Holders is

   procedure Finalize_Element is new
     Ada.Unchecked_Deallocation
       (Object => Element_Type,
        Name   => Element_Type_Access);
   --  Deallocate an Element_Type

   ------------
   -- Adjust --
   ------------

   procedure Adjust (Source : in out Holder_Type) is
   begin
      if Source.Element /= null then
         Source.Element := new Element_Type'(Source.Element.all);
      end if;
   end Adjust;

   -------------
   -- Element --
   -------------

   function Element (Container : Holder_Type) return Element_Type is
   begin
      if Container.Element = null then
         raise Constraint_Error with "Holder is empty";
      end if;

      return Container.Element.all;
   end Element;

   --------------------
   -- Element_Access --
   --------------------

   function Element_Access
     (Container : Holder_Type) return not null access Element_Type is
   begin
      if Container.Element = null then
         raise Constraint_Error with "Holder is empty";
      end if;

      return Container.Element;
   end Element_Access;

   --------------
   -- Finalize --
   --------------

   procedure Finalize (Container : in out Holder_Type) is
   begin
      if Container.Element /= null then
         Finalize_Element (Container.Element);
      end if;
   end Finalize;

   ----------
   -- Move --
   ----------

   procedure Move (Target, Source : in out Holder_Type) is
   begin
      if Target.Element /= null then
         Finalize_Element (Target.Element);
      end if;

      Target.Element := Source.Element;
      Source.Element := null;
   end Move;

   ---------------------
   -- Replace_Element --
   ---------------------

   procedure Replace_Element
     (Container : in out Holder_Type; Element : Element_Type) is
   begin
      if Container.Element /= null then
         Finalize_Element (Container.Element);
      end if;

      Container.Element := new Element_Type'(Element);
   end Replace_Element;

end SPARK.Containers.Formal.Holders;
