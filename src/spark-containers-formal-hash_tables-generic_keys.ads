--  Copyright (C) 2004-2025, Free Software Foundation, Inc.
--
--  SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
--

--  Hash_Table_Type is used to implement hashed containers. This package
--  declares hash-table operations that depend on keys.

generic
   with package HT_Types is new Generic_Hash_Table_Types (<>);

   use HT_Types;

   with function Next (Node : Node_Type) return Count_Type;

   with procedure Set_Next
     (Node : in out Node_Type;
      Next : Count_Type);

   type Key_Type (<>) is limited private;

   with function Hash (Key : Key_Type) return Hash_Type;

   with function Equivalent_Keys
     (Key  : Key_Type;
      Node : Node_Type) return Boolean;

package SPARK.Containers.Formal.Hash_Tables.Generic_Keys is
   pragma Pure;

   function Index
     (HT  : Hash_Table_Type;
      Key : Key_Type) return Hash_Type;
   pragma Inline (Index);
   --  Returns the bucket number (array index value) for the given key

   procedure Delete_Key_Sans_Free
     (HT  : in out Hash_Table_Type;
      Key : Key_Type;
      X   : out Count_Type);
   --  Removes the node (if any) with the given key from the hash table

   function Find
     (HT  : Hash_Table_Type;
      Key : Key_Type) return Count_Type;
   --  Returns the node (if any) corresponding to the given key

   generic
      with procedure New_Node
        (HT   : in out Hash_Table_Type;
         Node : out Count_Type);
   procedure Generic_Conditional_Insert
     (HT       : in out Hash_Table_Type;
      Key      : Key_Type;
      Node     : out Count_Type;
      Inserted : out Boolean);
   --  Attempts to insert a new node with the given key into the hash table.
   --  If a node with that key already exists in the table, then that node
   --  is returned and Inserted returns False. Otherwise New_Node is called
   --  to allocate a new node, and Inserted returns True.

   generic
      with function Hash (Node : Node_Type) return Hash_Type;
      with procedure Assign (Node : in out Node_Type; Key : Key_Type);
   procedure Generic_Replace_Element
     (HT   : in out Hash_Table_Type;
      Node : Count_Type;
      Key  : Key_Type);
   --  Assigns Key to Node, possibly changing its equivalence class. Procedure
   --  Assign is called to assign Key to Node. If Node is not in the same
   --  bucket as Key before the assignment, it is moved from its current bucket
   --  to the bucket implied by Key. Note that it is never proper to assign to
   --  Node a key value already in the hash table, and so if Key is equivalent
   --  to some other node then Program_Error is raised.

end SPARK.Containers.Formal.Hash_Tables.Generic_Keys;
