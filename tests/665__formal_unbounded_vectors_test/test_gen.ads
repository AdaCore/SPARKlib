with Gen_Inst;

generic
  type Index_Type is range <>;
  with package Inst is new Gen_Inst (Index_Type);
procedure Test_Gen with SPARK_Mode;
