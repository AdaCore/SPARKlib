--
--  Copyright (C) 2016-2024, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  This body is provided as a work-around for a GNAT compiler bug, as GNAT
--  currently does not compile instantiations of the spec with imported ghost
--  generics.

pragma Ada_2022;

package body SPARK.Containers.Functional.Sets with SPARK_Mode => Off is

   ---------
   -- "=" --
   ---------

   function "=" (Left : Set; Right : Set) return Boolean is
     (raise Program_Error);

   ----------
   -- "<=" --
   ----------

   function "<=" (Left : Set; Right : Set) return Boolean is
     (raise Program_Error);

   ---------
   -- Add --
   ---------

   function Add (Container : Set; Item : Element_Type) return Set is
     (raise Program_Error);

   ------------------
   -- Aggr_Include --
   ------------------

   procedure Aggr_Include (Container : in out Set; Item : Element_Type) is
   begin
      raise Program_Error;
   end Aggr_Include;

   --------------
   -- Contains --
   --------------

   function Contains (Container : Set; Item : Element_Type) return Boolean is
     (raise Program_Error);

   ------------
   -- Choose --
   ------------

   function Choose (Container : Set) return Element_Type is
     (raise Program_Error);

   ---------------
   -- Empty_Set --
   ---------------

   function Empty_Set return Set is
     (raise Program_Error);

   ---------------------
   -- Included_Except --
   ---------------------

   function Included_Except
     (Left  : Set;
      Right : Set;
      Item  : Element_Type) return Boolean
   is
     (raise Program_Error);

   -----------------------
   -- Included_In_Union --
   -----------------------

   function Included_In_Union
     (Container : Set;
      Left      : Set;
      Right     : Set) return Boolean
   is
     (raise Program_Error);

   ---------------------------
   -- Includes_Intersection --
   ---------------------------

   function Includes_Intersection
     (Container : Set;
      Left      : Set;
      Right     : Set) return Boolean
   is
     (raise Program_Error);

   ------------------
   -- Intersection --
   ------------------

   function Intersection (Left : Set; Right : Set) return Set is
     (raise Program_Error);

   --------------
   -- Is_Empty --
   --------------

   function Is_Empty (Container : Set) return Boolean is
     (raise Program_Error);

   ------------------
   -- Is_Singleton --
   ------------------

   function Is_Singleton
     (Container : Set;
      New_Item  : Element_Type) return Boolean
   is
     (raise Program_Error);

   -------------------------------
   -- Lemma_Contains_Equivalent --
   -------------------------------

   procedure Lemma_Contains_Equivalent
     (Container : Set;
      Item      : Element_Type)
   is null;

   ------------
   -- Length --
   ------------

   function Length (Container : Set) return Big_Natural is
     (raise Program_Error);

   -----------------
   -- Not_In_Both --
   -----------------

   function Not_In_Both
     (Container : Set;
      Left      : Set;
      Right     : Set) return Boolean
   is
     (raise Program_Error);

   ----------------
   -- No_Overlap --
   ----------------

   function No_Overlap (Left : Set; Right : Set) return Boolean is
     (raise Program_Error);

   ------------------
   -- Num_Overlaps --
   ------------------

   function Num_Overlaps (Left : Set; Right : Set) return Big_Natural is
     (raise Program_Error);

   ------------
   -- Remove --
   ------------

   function Remove (Container : Set; Item : Element_Type) return Set is
     (raise Program_Error);

   -----------
   -- Union --
   -----------

   function Union (Left : Set; Right : Set) return Set is
     (raise Program_Error);

end SPARK.Containers.Functional.Sets;
