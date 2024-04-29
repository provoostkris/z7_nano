------------------------------------------------------------------------------
--  led blink - based on counter
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     ieee.std_logic_misc.all;

entity led_blink is
  generic(
    g_mode        : in  positive range 1 to 3  := 3 -- 1: cnt mode
                                                    -- 2: pwm mode
                                                    -- 3: beat mode
  );
  port(
    clk           : in  std_logic;  --system clock
    reset_n       : in  std_logic;  --active low reset

    led           : out std_logic
  );
end led_blink;

architecture rtl of led_blink is

begin

--! use a counter based mode
gen_cnt: if g_mode = 1 generate
  i_cnt: entity work.cnt
  generic map (26)
  port    map (clk, reset_n,led);
end generate gen_cnt;

--! use a pwm based mode
gen_pwm: if g_mode = 2 generate
  i_pwm: entity work.pwm
  generic map (45)
  port    map (clk, reset_n,led);
end generate gen_pwm;

--! use a beat based mode
gen_beat: if g_mode = 3 generate
  i_beat: entity work.beat
  port    map (clk, reset_n,led);
end generate gen_beat;

end rtl;