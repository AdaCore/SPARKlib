--
--  Copyright (C) 2016-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This body is provided as a work-around for a GNAT compiler bug, as GNAT
--  currently does not compile instantiations of the spec with imported ghost
--  generics.

pragma Ada_2012;
package body SPARK.Containers.Functional.Maps with SPARK_Mode => Off is

   ---------
   -- "=" --
   ---------

   function "=" (Left : Map; Right : Map) return Boolean is
     (raise Program_Error);

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Map; Right : Map) return Boolean is
     (raise Program_Error);

   ---------
   -- Add --
   ---------

   function Add
     (Container : Map;
      New_Key   : Key_Type;
      New_Item  : Element_Type) return Map
   is
     (raise Program_Error);

   ------------------
   -- Aggr_Include --
   ------------------

   procedure Aggr_Include
     (Container : in out Map;
      New_Key   : Key_Type;
      New_Item  : Element_Type)
   is
   begin
      raise Program_Error;
   end Aggr_Include;

   ------------
   -- Choose --
   ------------

   function Choose (Container : Map) return Key_Type is
     (raise Program_Error);

   -------------------------
   -- Element_Logic_Equal --
   -------------------------

   function Element_Logic_Equal (Left, Right : Element_Type) return Boolean is
     (raise Program_Error);

   --------------------
   -- Elements_Equal --
   --------------------

   function Elements_Equal (Left, Right : Map) return Boolean is
     (raise Program_Error);

   ---------------------------
   -- Elements_Equal_Except --
   ---------------------------

   function Elements_Equal_Except
     (Left    : Map;
      Right   : Map;
      New_Key : Key_Type) return Boolean
   is
     (raise Program_Error);

   function Elements_Equal_Except
     (Left  : Map;
      Right : Map;
      X     : Key_Type;
      Y     : Key_Type) return Boolean
   is
     (raise Program_Error);

   ---------------
   -- Empty_Map --
   ---------------

   function Empty_Map return Map is
     (raise Program_Error);

   ---------------------
   -- Equivalent_Maps --
   ---------------------

   function Equivalent_Maps (Left : Map; Right : Map) return Boolean is
     (raise Program_Error);

   ---------
   -- Get --
   ---------

   function Get (Container : Map; Key : Key_Type) return Element_Type is
     (raise Program_Error);

   -------------
   -- Has_Key --
   -------------

   function Has_Key (Container : Map; Key : Key_Type) return Boolean is
     (raise Program_Error);

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Map) return Boolean is
     (raise Program_Error);

   -------------------
   -- Keys_Included --
   -------------------

   function Keys_Included (Left : Map; Right : Map) return Boolean is
     (raise Program_Error);

   --------------------------
   -- Keys_Included_Except --
   --------------------------

   function Keys_Included_Except
     (Left    : Map;
      Right   : Map;
      New_Key : Key_Type) return Boolean
   is
     (raise Program_Error);

   function Keys_Included_Except
     (Left  : Map;
      Right : Map;
      X     : Key_Type;
      Y     : Key_Type) return Boolean
   is
     (raise Program_Error);

   --------------------------
   -- Lemma_Get_Equivalent --
   --------------------------

   procedure Lemma_Get_Equivalent
     (Container    : Map;
      Key_1, Key_2 : Key_Type)
   is null;

   ------------------------------
   -- Lemma_Has_Key_Equivalent --
   ------------------------------

   procedure Lemma_Has_Key_Equivalent
     (Container : Map;
      Key       : Key_Type)
   is null;

   ------------
   -- Length --
   ------------

   function Length (Container : Map) return Big_Natural is
     (raise Program_Error);

   ------------
   -- Remove --
   ------------

   function Remove (Container : Map; Key : Key_Type) return Map is
     (raise Program_Error);

   ---------------
   -- Same_Keys --
   ---------------

   function Same_Keys (Left : Map; Right : Map) return Boolean is
     (raise Program_Error);

   ---------
   -- Set --
   ---------

   function Set
     (Container : Map;
      Key       : Key_Type;
      New_Item  : Element_Type) return Map
   is
     (raise Program_Error);

end SPARK.Containers.Functional.Maps;
