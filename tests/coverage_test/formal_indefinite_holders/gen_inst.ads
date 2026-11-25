with SPARK.Containers.Formal.Indefinite_Holders;

generic
   type Element_Type (<>) is private;
   with function Eq (Left, Right : Element_Type) return Boolean;
package Gen_Inst with SPARK_Mode is
   function Equal (Left, Right : Element_Type) return Boolean is
     (Eq (Left, Right));

   package Holders is new
     SPARK.Containers.Formal.Indefinite_Holders (Element_Type, Eq);
end Gen_Inst;
