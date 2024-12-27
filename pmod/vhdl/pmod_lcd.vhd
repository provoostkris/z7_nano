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
    dc            : out std_logic;
    sda           : out std_logic;
    sck           : out std_logic;
    rst           : out std_logic
  );
end pmod_lcd;

architecture rtl of pmod_lcd is

  type   t_fsm_spi    is (  s_idle,   --! out of reset
                            s_reset,  --! release reset
                            s_to_sleep,  --! preset state
                            s_sleep,  --! out of sleep
                            s_wake,   --! time needed to wake up
                            s_to_on,  --! preset state
                            s_on,     --! put disply on
                            s_cs,     --! release cs
                            s_cs_n,   --! activate cs
                            s_send,   --! send data
                            s_done    --! close transmission
  );

  --! clock reduction
  signal cntr         : unsigned(c_clk_reduce downto 0);
  signal spi_clk_ena  : std_logic;
  signal spi_clk_div  : std_logic;
  --! SPI interfacce
  signal spi_cs_n     : std_logic;
  signal spi_dc       : std_logic;

  --! reset pulse timer
  signal cnt_delay    : integer range 0 to c_rst_time_hld-1 ;

  --! controller
  signal fsm_spi      : t_fsm_spi;
  signal rgb_hor      : t_raw_arr(0 to c_vert-1);
  signal rgb_ver      : std_logic_vector(c_bits-1 downto 0);
  signal write_cmd    : std_logic_vector(8-1 downto 0);
  signal cnt_bit      : t_cnt_arr(0 to 2);
  signal cnt_pix      : integer range 0 to c_pixl-1 ;
  signal cnt_hor      : integer range 0 to c_hori-1 ;
  signal cnt_ver      : integer range 0 to c_vert-1 ;
  signal cnt_off_h    : integer range 0 to c_hori-1 ;
  signal cnt_off_v    : integer range 0 to c_vert-1 ;

-- lookup some rgb value in the ROM , and return the corresponding raw value
function f_rgb_to_raw(x : natural) return t_raw_arr is
  variable r  : std_logic_vector( 7 downto 0) := ( others => '0');
  variable g  : std_logic_vector( 7 downto 0) := ( others => '0');
  variable b  : std_logic_vector( 7 downto 0) := ( others => '0');
  variable y  : std_logic_vector(24-1 downto 0) := ( others => '0');
  variable res: t_raw_arr(0 to c_vert-1 ):= ( others => ( others => '0'));
begin
  for i in 0 to c_vert-1 loop
    -- lookup the color value in the ROM
    r := std_logic_vector(to_unsigned(c_color_map(x)(0),r'length));
    g := std_logic_vector(to_unsigned(c_color_map(x)(1),g'length));
    b := std_logic_vector(to_unsigned(c_color_map(x)(2),b'length));
    -- concat and return
    y := r & g & b ;
    res(i) := y;
  end loop;

  return res;
end function f_rgb_to_raw;

function f_format_565(x : std_logic_vector) return std_logic_vector is
  variable y  : std_logic_vector(c_bits_565-1 downto 0) := ( others => '0');
begin
    -- slice vector
    y :=  x(24-1 downto 24-5) &
          x(16-1 downto 16-6) &
          x(08-1 downto 08-5) ;
    return y;
end function f_format_565;

function f_format_666(x : std_logic_vector) return std_logic_vector is
  variable y  : std_logic_vector(c_bits_666-1 downto 0) := ( others => '0');
begin
    -- slice vector
    y :=  x(24-1 downto 24-6) & "00" &
          x(16-1 downto 16-6) & "00" &
          x(08-1 downto 08-6) & "00" ;
    return y;
end function f_format_666;

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
  spi_clk_div <= '0' when cntr < to_unsigned(2**(cntr'length-1),cntr'length) else '1' ;

  --! SPI control signals
  process(reset_n, clk) is
    begin
        if reset_n='0' then
          cs    <= '1';
          sck   <= '0';
          dc    <= '0';
        elsif rising_edge(clk) then
          cs          <= spi_cs_n;
          sck         <= spi_clk_div and not spi_cs_n;
          dc          <= spi_dc;
        end if;
  end process;

  -- from the pixel counter , derive the row and column location
  cnt_hor <= cnt_pix mod c_hori;
  cnt_ver <= cnt_pix /   c_hori;
  -- add the offset for the first pixel lookup
  cnt_off_h <= (cnt_hor + c_off_h) mod c_hori;
  cnt_off_v <= (cnt_ver + c_off_v) mod c_vert;

  -- process(reset_n, clk) is
  --   begin
  --       if reset_n='0' then
  --         rgb_hor  <= ( others => ( others => '0'));
  --         rgb_ver  <= ( others => '0');
  --       elsif rising_edge(clk) then
  --         rgb_hor  <= f_rgb_to_raw(cnt_hor);
  --         rgb_ver  <= f_format_565(rgb_hor(cnt_ver));
  --       end if;
  -- end process;

  -- shift out data bits
  -- sda    <= rgb_ver(cnt_bit(cnt_bit'high));
  -- sda    <= f_format_565(c_tst_colors)(cnt_bit(cnt_bit'high));

  sda    <= write_cmd(cnt_bit(cnt_bit'high)) when spi_dc = '0' else f_format_565(c_tst_colors)(cnt_bit(cnt_bit'high));

  -- SPI controller
  process(reset_n, clk) is
    begin
        if reset_n='0' then
          rst        <= '0';
          spi_cs_n   <= '1';
          spi_dc     <= '0';
          cnt_bit    <= ( others => 0);
          cnt_pix    <= 0;
          cnt_delay  <= c_rst_time_act-1;
          write_cmd  <= ( others => '0');
        elsif rising_edge(clk) then
        if spi_clk_ena = '1' then
          case fsm_spi is

            when s_idle =>
              if cnt_delay = 0 then
                fsm_spi   <= s_reset;
                cnt_delay <= c_rst_time_hld-1;
              else
                cnt_delay <= cnt_delay-1;
              end if;
              rst       <= '0';
              spi_cs_n  <= '1';

            when s_reset =>
              if cnt_delay = 0 then
                fsm_spi   <= s_to_sleep;
              else
                cnt_delay <= cnt_delay-1;
              end if;
              rst       <= '1';
              spi_cs_n  <= '1';

            when s_to_sleep =>
              fsm_spi   <= s_sleep;
              cnt_bit(0)<= 8-1;
              write_cmd <= c_SLPOUT;
              spi_dc    <= '0';
              spi_cs_n  <= '0';
              cnt_delay <= c_sleep_out-1;

            when s_sleep =>
              if cnt_bit(0) = 0 then
                fsm_spi   <= s_wake;
                spi_cs_n  <= '1';
              else
                cnt_bit(0)    <= cnt_bit(0) - 1;
              end if;

            when s_wake =>
              if cnt_delay = 0 then
                fsm_spi   <= s_to_on;
              else
                cnt_delay <= cnt_delay-1;
              end if;
              rst       <= '1';
              spi_cs_n  <= '1';

            when s_to_on =>
              fsm_spi   <= s_on;
              cnt_bit(0)<= 8-1;
              write_cmd <= c_DISPON;
              spi_dc    <= '0';
              spi_cs_n  <= '0';

            when s_on =>
              if cnt_bit(0) = 0 then
                fsm_spi   <= s_cs;
                spi_cs_n  <= '1';
              else
                cnt_bit(0)    <= cnt_bit(0) - 1;
              end if;

            when s_cs =>
              fsm_spi   <= s_cs_n;
              spi_cs_n  <= '1';
              spi_dc    <= '1';

            when s_cs_n =>
              fsm_spi   <= s_send;
              spi_cs_n  <= '0';
              cnt_bit(0)<= c_bits-1;
              cnt_pix   <= 0 ;

            when s_send =>
              if cnt_bit(0) = 0 then
                cnt_bit(0) <= c_bits-1;
                if cnt_pix = c_pixl-1 then
                  fsm_spi  <= s_done;
                  spi_cs_n <= '1';
                else
                  cnt_pix   <= cnt_pix + 1;
                end if;
              else
                cnt_bit(0)    <= cnt_bit(0) - 1;
              end if;

            when s_done =>
              -- fsm_spi   <= s_idle;
              cnt_delay <= c_rst_time_act-1;

            when others =>
              fsm_spi <= s_idle;
              cnt_delay <= c_rst_time_act-1;

          end case;
        end if;
        -- pipe
        cnt_bit(1 to cnt_bit'high)    <= cnt_bit(0 to cnt_bit'high-1);
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