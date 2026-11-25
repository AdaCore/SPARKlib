with Gen_Inst;

generic
   type Element_Type (<>) is private;
   with package Inst is new Gen_Inst (Element_Type, Eq => <>);
   with function Value (N : Positive) return Element_Type;
   with function Same_Value (Left, Right : Element_Type) return Boolean;
procedure Test_Gen with SPARK_Mode;
