--
--  Copyright (C) 2022-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

pragma Ada_2022;

private with Ada.Finalization;

private generic
   type Element_Type (<>) is private;

package SPARK.Containers.Formal.Holders is

   type Element_Type_Access is access Element_Type;

   type Holder_Type is private;

   function Element (Container : Holder_Type) return Element_Type;
   --  Return the element held by Container

   function Element_Access
     (Container : Holder_Type) return not null access Element_Type;
   --  Return the stored access.

   procedure Replace_Element
     (Container : in out Holder_Type;
      Element   : Element_Type);
   --  Replace the Holder's element by Element and do the required

   procedure Move (Target, Source : in out Holder_Type);
   --  Move the content of the source to the target.

   procedure Adjust (Source : in out Holder_Type);
   --  Make a copy of Container in order to avoid sharing

   procedure Finalize (Container : in out Holder_Type);
   --  Finalize the element held by Container if necessary. It is still
   --  possible to use a finalized Holder_Type but the former value is lost.

   function Is_Null (Container : Holder_Type) return Boolean;

private

   type Holder_Type is new Ada.Finalization.Controlled
   with record
      Element : Element_Type_Access;
   end record;

   function Is_Null (Container : Holder_Type) return Boolean is
     (Container.Element = null);
end SPARK.Containers.Formal.Holders;
