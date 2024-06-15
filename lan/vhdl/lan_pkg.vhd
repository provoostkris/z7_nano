library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
package lan_pkg is


-- The following configurations are set at the design top level
-- - SRC MAC: 02-AA-BB-CC-DD-EE
-- - DST MAC: 02-BB-CC-DD-DD-FF
-- for local MAC range the guide https://www.blackmanticore.com/fc5c95c7c2e29e262ec89c539852f8fb is followed

  type t_byte_arr is array (integer range <>) of std_logic_vector(7 downto 0);
  constant c_pkg_dummy_eth :
            t_byte_arr( 0 to 63) := (  x"02", x"AA", x"BB", x"CC", x"DD", x"EE", x"02", x"BB", 
                                       x"CC", x"DD", x"EE", x"FF", x"08", x"00", x"45", x"00", 
                                       x"00", x"32", x"1e", x"49", x"40", x"00", x"40", x"11",
                                       x"04", x"50", x"0a", x"00", x"02", x"02", x"0a", x"00",
                                       x"6B", x"72", x"69", x"73", x"20", x"70", x"72", x"6F", --kris
                                       x"76", x"6F", x"6F", x"73", x"74", x"20", x"66", x"70", --provoost 
                                       x"67", x"61", x"20", x"6C", x"61", x"6E", x"20", x"64", --lan
                                       x"65", x"73", x"69", x"67", x"6E", x"00", x"00", x"00"  --design 
                                    );

end package lan_pkg;
-------------------------------------------------------------------------------
package body lan_pkg is



end package body lan_pkg;
