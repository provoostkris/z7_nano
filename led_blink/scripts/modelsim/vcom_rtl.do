------------------------------------------------------------------------------
--  Compilation execution script
--  rev. 1.0 : 2023 Provoost Kris
------------------------------------------------------------------------------

  set fp [open $path_rtl/rtl.txt]
  while {-1 != [gets $fp line]} {
      set file_src $path_rtl/$line
      puts $file_src
      vcom  -quiet -work work $file_src
  }