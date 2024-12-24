--!----------------------------------------------------------------------------
--!  pmod lcd
--!  rev. 1.0 : 2024 provoost kris
--!----------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.pmod_lcd_pkg.all;

entity pmod_lcd is
  port(
    clk           : in  std_logic;  --system clock
    reset_n       : in  std_logic;  --active low reset

    cs            : out std_logic;
    sda           : out std_logic;
    sck           : out std_logic;
    rst           : out std_logic
  );
end pmod_lcd;

architecture rtl of pmod_lcd is

  type   t_fsm_spi    is (  s_idle,   --! out of reset
                            s_send,   --! send data
                            s_done    --! close transmission
  );

  --! clock reduction
  signal cntr         : unsigned(1 downto 0);
  signal spi_clk_ena  : std_logic;

  --! controller
  signal fsm_spi      : t_fsm_spi;
  signal rgb          : std_logic_vector(c_bits-1 downto 0);
  signal cnt_bit      : integer range 0 to c_bits-1 ;
  signal cnt_pix      : integer range 0 to c_pixl-1 ;
  -- signal pixl_mem     : t_pixl_arr( 0 to c_pixl-1) ;

-- lookup some rgb value in the ROM , and return the corresponding raw value
function f_rgb_to_raw(x : natural) return std_logic_vector is
  variable r  : std_logic_vector( 4 downto 0) := ( others => '0');
  variable g  : std_logic_vector( 5 downto 0) := ( others => '0');
  variable b  : std_logic_vector( 4 downto 0) := ( others => '0');
  variable y  : std_logic_vector(15 downto 0) := ( others => '0');
begin
  -- take the color and rescale them in 5 or 6 bit values
  r := std_logic_vector(to_unsigned(c_color_map(x)(0)/2**3,r'length));
  g := std_logic_vector(to_unsigned(c_color_map(x)(1)/2**2,g'length));
  b := std_logic_vector(to_unsigned(c_color_map(x)(2)/2**3,b'length));
  -- concat and return
  y := r & g & b ;
  return y;
end function f_rgb_to_raw;

begin

  -- simple counter to bring SPI frequency in range of component
  process(reset_n, clk) is
    begin
        if reset_n='0' then
          cntr  <= ( others => '0');
        elsif rising_edge(clk) then
          cntr <= cntr + to_unsigned(1,cntr'length);
        end if;
  end process;

  spi_clk_ena <= '1' when cntr = to_unsigned((2**cntr'length)-1,cntr'length) else '0' ;
  sck         <= '0' when cntr < to_unsigned(2**(cntr'length-1),cntr'length) else '1' ;

  -- see data sheet rst must be always high
  rst    <= '1';

  -- TODO , check data sheet for image and char display
  sda    <= rgb(cnt_bit);
  rgb    <= f_rgb_to_raw(cnt_pix);

  -- SPI controller
  process(reset_n, clk) is
    begin
        if reset_n='0' then
          cs     <= '1';
          cnt_bit    <= 0;
          cnt_pix    <= 0;
        elsif rising_edge(clk) then
        if spi_clk_ena = '1' then
          case fsm_spi is
            when s_idle =>
              fsm_spi <= s_send;
              cs        <= '0';
              cnt_bit   <= c_bits-1;
              cnt_pix   <= c_pixl-1;
            when s_send =>
              if cnt_bit = 0 then
                cnt_bit   <= c_bits-1;
                if cnt_pix = 0 then
                  fsm_spi <= s_done;
                  cs      <= '1';
                else
                  cnt_pix   <= cnt_pix - 1;
                end if;
              else
                cnt_bit    <= cnt_bit - 1;
              end if;
            when s_done =>
              fsm_spi   <= s_idle;
            when others =>
              fsm_spi <= s_idle;
          end case;
        end if;
        end if;
    end process;

  -- write pixel memory
  -- process(reset_n, clk) is
  --   begin
  --       if reset_n='0' then
  --         pixl_mem  <= (  others => (  others => '0') );
  --       elsif rising_edge(clk) then

  --       end if;
  -- end process;

end rtl;