SQL> @2630331

PL/SQL procedure successfully completed.


PL/SQL procedure successfully completed.


Table dropped.


Table created.


1 row created.


1 row created.


1 row created.


1 row created.


Commit complete.


        A1 TEXT                                                                 
---------- ---------------------------------------------                        
         1 rou�de                                                               
         2 wasch�n                                                              
         3 naschon                                                              
         4 afmuenchen                                                           

4 rows selected.


Index created.


TOKEN_TEXT                                                       TOKEN_TYPE     
---------------------------------------------------------------- ----------     
AFMUENCHEN                                                                0     
NASCHON                                                                   0     
ROUEDE                                                                    0     
WASCHOEN                                                                  0     
WASCH�N                                                                   0     

5 rows selected.

SQL> 
SQL> select * from tt where contains(text,'afm'||unistr('\00FC')||'nchen')>0;

        A1 TEXT                                                                 
---------- ---------------------------------------------                        
         4 afmuenchen                                                           

SQL> select * from tt where contains(text,'afmuenchen') > 0;

        A1 TEXT                                                                 
---------- ---------------------------------------------                        
         4 afmuenchen                                                           

SQL> 
SQL> set echo on
SQL> 
SQL> --select * from tt where contains(text,'naschoen') > 0;
SQL> --select * from tt where contains(text,'naschon') > 0;
SQL> --select * from tt where contains(text,'na'||unistr('\00F6')||'n') > 0;
SQL> 
SQL> -- select * from tt where contains(text,'waschon') > 0;
SQL> -- select * from tt where contains(text,'waschoen') > 0;
SQL> -- select * from tt where contains(text,'wasch'||unistr('\00F6')||'n') > 0;
SQL> 
SQL> set echo off

Table dropped.


Table created.


PL/SQL procedure successfully completed.


EXPLAIN_ID  ID PARENT_ID OPERATION  OPTIONS    OBJECT_NAME          POSITION    
---------- --- --------- ---------- ---------- -------------------- --------    
Test         1         0 WORD                  WASCHOEN                    1    

SQL> spool off
