TYPE Addr
  x AS INTEGER
  y AS INTEGER
END TYPE
TYPE Person
  nm AS STRING * 4
  home AS Addr
END TYPE
DIM crowd(3) AS Person
crowd(2).home.y = 9
crowd(2).home.x = crowd(2).home.y * 2
PRINT crowd(2).home.x; crowd(2).home.y
