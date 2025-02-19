--!----------------------------------------------------------------------------
--!  pmod lcd
--!  rev. 1.0 : 2024 provoost kris
--!----------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

use     work.pmod_lcd_pkg.all;
use     work.ascii_pkg.all;

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
                            s_sleep,  --! out of sleep
                            s_wake,   --! time needed to wake up
                            s_invctr_cmd, --! INVCTR command
                            s_invctr_p0,  --! INVCTR param
                            s_gmctrp_cmd, --! gamma correction
                            s_gmctrp_p0, --! gamma parameters
                            s_gmctrn_cmd, --! gamma correction
                            s_gmctrn_p0, --! gamma parameters
                            s_mad_cmd, --! MAD command
                            s_mad_p0,  --! MAD param
                            s_inv,    --! put display inverted
                            s_on,     --! put display on
                            s_cas_cmd, --! CAS command
                            s_cas_p0,  --! MAD command
                            s_cas_p1,
                            s_ras_cmd,
                            s_ras_p0,
                            s_ras_p1,
                            s_ramwr,
                            s_send_req,   --! request dara send
                            s_draw_char,   --! request character
                            s_done    --! close transmission
  );

  type   t_fsm_phy    is (  s_idle,   --! out of reset
                            s_req,    --! check if pulse is persitent
                            s_ack,    --! check if pulse is persitent
                            s_tx      --! sirialize data
  );
  --! clock reduction
  signal cntr         : unsigned(c_clk_reduce downto 0);
  signal spi_clk_ena  : std_logic;
  signal spi_clk_div  : std_logic;
  --! SPI interfacce
  signal spi_cs_n     : std_logic;
  signal spi_dc       : std_logic;
  signal spi_sda      : std_logic;

  --! reset pulse timer
  signal cnt_delay    : natural range 0 to c_sleep_out-1 ;

  --! controller
  signal fsm_spi      : t_fsm_spi;
  signal fsm_phy      : t_fsm_phy;
  signal rgb_hor      : t_raw_arr(0 to c_vert-1);
  signal rgb_ver      : std_logic_vector(c_bits-1 downto 0);
  signal write_cmd    : std_logic_vector(16*8-1 downto 0);
  signal sel_cmd      : std_logic;
  signal cnt_bit      : t_cnt_arr(0 to 2);
  signal cnt_pix      : natural range 0 to c_pixl-1 ;
  signal cnt_img_hor  : natural range 0 to c_hori-1 ;
  signal cnt_img_ver  : natural range 0 to c_vert-1 ;
  signal cnt_chr_hor  : natural range 0 to  8-1 ;
  signal cnt_chr_ver  : natural range 0 to 16-1 ;
  signal char_bit     : std_logic;

  --! serializer
  signal ser_tx_now   : std_logic;
  signal ser_tx_req   : std_logic;
  signal ser_tx_ack   : std_logic;
  signal ser_bits     : natural range 0 to 16*8-1;

-- lookup some rgb value in the ROM , and return the corresponding raw value
function f_rgb_to_raw(x : natural) return t_raw_arr is
  variable r  : std_logic_vector( 7 downto 0) := ( others => '0');
  variable g  : std_logic_vector( 7 downto 0) := ( others => '0');
  variable b  : std_logic_vector( 7 downto 0) := ( others => '0');
  variable y  : std_logic_vector(24-1 downto 0) := ( others => '0');
  variable res: t_raw_arr(0 to c_vert-1 ):= ( others => ( others => '0'));
begin
  for i in 0 to c_res_y-1 loop
    -- lookup the color value in the ROM
    r := std_logic_vector(to_unsigned(c_color_map(x+i*c_hori)(0),r'length));
    g := std_logic_vector(to_unsigned(c_color_map(x+i*c_hori)(1),g'length));
    b := std_logic_vector(to_unsigned(c_color_map(x+i*c_hori)(2),b'length));
    -- concat and return
    y := r & g & b ;
    res(i) := y;
  end loop;

  return res;
end function f_rgb_to_raw;

-- function f_format_565(x : std_logic_vector) return std_logic_vector is
--   variable y  : std_logic_vector(c_bits_565-1 downto 0) := ( others => '0');
-- begin
--     -- slice vector
--     y :=  x(24-1 downto 24-5) & -- slice 5 bits
--           x(16-1 downto 16-6) & -- slice 6 bits
--           x(08-1 downto 08-5) ; -- slice 5 bits
--     return y;
-- end function f_format_565;

function f_format_666(x : std_logic_vector) return std_logic_vector is
  variable y  : std_logic_vector(c_bits_666-1 downto 0) := ( others => '0');
begin
    -- slice vector
    y :=  x(24-1 downto 24-6) & "00" & -- slice 6 bits add 2 bits
          x(16-1 downto 16-6) & "00" & -- slice 6 bits add 2 bits
          x(08-1 downto 08-6) & "00" ; -- slice 6 bits add 2 bits
    return y;
end function f_format_666;


function f_1608_to_bit(c : natural ; x : natural ; y : natural) return std_logic is
  variable res  : std_logic := '0' ;
begin
  -- lookup the bit , black or white , in the characters
  res := c_ascii_1608(c)(x)(y);
  return res;
end function f_1608_to_bit;

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
  --- for a full display area
  cnt_img_hor <= cnt_pix mod c_hori;
  cnt_img_ver <= cnt_pix /   c_hori;
  --- for only a character area
  cnt_chr_hor <= cnt_pix mod 8;
  cnt_chr_ver <= cnt_pix /   8;

  -- pipe the lookup functions , for color maps and char maps
  process(reset_n, sel_cmd, clk) is
    begin
        if reset_n='0' then
          rgb_hor  <= ( others => ( others => '0'));
          rgb_ver  <= ( others => '0');
          char_bit <= '0';
        elsif rising_edge(clk) then
        -- only compute when colors are needed
        if sel_cmd = '0' then
          rgb_hor  <= f_rgb_to_raw(cnt_img_hor);
          rgb_ver  <= f_format_666(rgb_hor(cnt_img_ver));
          char_bit <= f_1608_to_bit(8,cnt_chr_ver,cnt_chr_hor);
        end if;
        end if;
  end process;

  -- shift out data bits
  -- test 1 : rgb_ver(cnt_bit(cnt_bit'high));
  -- test 2 : f_format_666(c_tst_colors)(cnt_bit(cnt_bit'high));

  -- data is command+parameter or pixel
  spi_sda     <=  write_cmd(cnt_bit(cnt_bit'high)) when sel_cmd = '1' else
                  char_bit;
  -- rgb_ver(cnt_bit(cnt_bit'high));
  sda         <= spi_sda;

  -- SPI controller
  process(reset_n, clk) is
    begin
        if reset_n='0' then
          fsm_spi    <= s_idle;
          rst        <= '0';
          spi_dc     <= '0';
          cnt_pix    <= 0;
          cnt_delay  <= c_rst_time_act-1;
          write_cmd  <= ( others => '0');
          sel_cmd    <= '0';
          ser_tx_req <= '0';
          ser_tx_now <= '0';
          ser_bits   <= 0;
        elsif rising_edge(clk) then
          case fsm_spi is

            when s_idle =>
              if cnt_delay = 0 then
                fsm_spi   <= s_reset;
                cnt_delay <= c_rst_time_hld-1;
              else
                cnt_delay <= cnt_delay-1;
              end if;
              rst       <= '0';
              sel_cmd   <= '1';

            when s_reset =>
              if cnt_delay = 0 then
                fsm_spi   <= s_sleep;
              else
                cnt_delay <= cnt_delay-1;
              end if;
              rst       <= '1';

            when s_sleep =>
              ser_bits  <= c_SLPOUT'high;
              write_cmd(c_SLPOUT'range) <= c_SLPOUT;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_wake;
              else
                ser_tx_req <= '1';
              end if;
              cnt_delay <= c_sleep_out-1;

            when s_wake =>
              if cnt_delay = 0 then
                fsm_spi   <= s_invctr_cmd;
              else
                cnt_delay <= cnt_delay-1;
              end if;
              sel_cmd   <= '1';
              cnt_pix   <= 0;

            when s_invctr_cmd =>
              ser_bits  <= c_INVCTR'high;
              write_cmd(c_INVCTR'range) <= c_INVCTR;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_invctr_p0;
              else
                ser_tx_req  <= '1';
              end if;

            when s_invctr_p0 =>
              ser_bits  <= c_INVCTR_P0'high;
              write_cmd(c_INVCTR_P0'range) <= c_INVCTR_P0;
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_gmctrp_cmd;
              else
                ser_tx_req  <= '1';
              end if;

          when s_gmctrp_cmd =>
            ser_bits  <= c_GMCTRP1'high;
            write_cmd(c_GMCTRP1'range) <= c_GMCTRP1;
            spi_dc    <= '0';
            if ser_tx_ack = '1' then
              ser_tx_req  <= '0';
              fsm_spi     <= s_gmctrp_p0;
            else
              ser_tx_req  <= '1';
            end if;

          when s_gmctrp_p0 =>
            ser_bits  <= c_GMCTRP1_P0'high;
            write_cmd(c_GMCTRP1_P0'range) <= c_GMCTRP1_P0;
            spi_dc    <= '1';
            if ser_tx_ack = '1' then
              ser_tx_req  <= '0';
              fsm_spi     <= s_gmctrn_cmd;
            else
              ser_tx_req  <= '1';
            end if;

          when s_gmctrn_cmd =>
            ser_bits  <= c_GMCTRN1'high;
            write_cmd(c_GMCTRN1'range) <= c_GMCTRN1;
            spi_dc    <= '0';
            if ser_tx_ack = '1' then
              ser_tx_req  <= '0';
              fsm_spi     <= s_gmctrn_p0;
            else
              ser_tx_req  <= '1';
            end if;

          when s_gmctrn_p0 =>
            ser_bits  <= c_GMCTRN1_P0'high;
            write_cmd(c_GMCTRN1_P0'range) <= c_GMCTRN1_P0;
            spi_dc    <= '1';
            if ser_tx_ack = '1' then
              ser_tx_req  <= '0';
              fsm_spi     <= s_mad_cmd;
            else
              ser_tx_req  <= '1';
            end if;

            when s_mad_cmd =>
              ser_bits  <= c_MADCTL'high;
              write_cmd(c_MADCTL'range) <= c_MADCTL;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_mad_p0;
              else
                ser_tx_req  <= '1';
              end if;

            when s_mad_p0 =>
              ser_bits  <= c_MADCTL_P0'high;
              write_cmd(c_MADCTL_P0'range) <= c_MADCTL_P0;
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_inv;
              else
                ser_tx_req  <= '1';
              end if;

            when s_inv =>
              ser_bits  <= c_DISPINV'high;
              write_cmd(c_DISPINV'range) <= c_DISPINV;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_on;
              else
                ser_tx_req  <= '1';
              end if;

            when s_on =>
              ser_bits  <= c_DISPON'high;
              write_cmd(c_DISPON'range) <= c_DISPON;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_cas_cmd;
              else
                ser_tx_req  <= '1';
              end if;

            when s_cas_cmd =>
              ser_bits  <= c_CASET'high;
              write_cmd(c_CASET'range) <= c_CASET;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_cas_p0;
              else
                ser_tx_req  <= '1';
              end if;

            when s_cas_p0 =>
              ser_bits  <= 16-1;
              write_cmd(16-1 downto 0) <= std_logic_vector(to_unsigned(c_ras_xs,16));
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_cas_p1;
              else
                ser_tx_req  <= '1';
              end if;

            when s_cas_p1 =>
              ser_bits  <= 16-1;
              -- write_cmd(16-1 downto 0) <= std_logic_vector(to_unsigned(c_ras_xe,16));
              write_cmd(16-1 downto 0) <= std_logic_vector(to_unsigned(c_ras_xs+8-1,16));
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_ras_cmd;
              else
                ser_tx_req  <= '1';
              end if;

            when s_ras_cmd =>
             ser_bits  <= c_RASET'high;
             write_cmd(c_RASET'range) <= c_RASET;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_ras_p0;
              else
                ser_tx_req  <= '1';
              end if;

            when s_ras_p0 =>
              ser_bits  <= 16-1;
              write_cmd(16-1 downto 0) <= std_logic_vector(to_unsigned(c_cas_ys,16));
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_ras_p1;
              else
                ser_tx_req  <= '1';
              end if;

            when s_ras_p1 =>
              ser_bits  <= 16-1;
              -- write_cmd(16-1 downto 0) <= std_logic_vector(to_unsigned(c_cas_ye,16));
              write_cmd(16-1 downto 0) <= std_logic_vector(to_unsigned(c_cas_ys+16-1,16));
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_ramwr;
              else
                ser_tx_req  <= '1';
              end if;

            when s_ramwr =>
              ser_bits  <= c_RAMWR'high;
              write_cmd(c_RAMWR'range) <= c_RAMWR;
              spi_dc    <= '0';
              if ser_tx_ack = '1' then
                ser_tx_req  <= '0';
                fsm_spi     <= s_draw_char;
              else
                ser_tx_req  <= '1';
              end if;

            when s_send_req =>
              ser_bits  <= c_bits-1;
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_now <= '1';
                if cnt_pix = c_pixl-1 then
                  fsm_spi  <= s_done;
                  ser_tx_req  <= '0';
                else
                  fsm_spi   <= s_send_req;
                  cnt_pix   <= cnt_pix + 1;
                end if;
              else
                ser_tx_req <= '1';
              end if;
              sel_cmd   <= '0';

            when s_draw_char =>
              ser_bits  <= c_bits-1;
              spi_dc    <= '1';
              if ser_tx_ack = '1' then
                ser_tx_now <= '1';
                if cnt_pix = 16*8-1 then
                  fsm_spi  <= s_done;
                  ser_tx_req  <= '0';
                else
                  fsm_spi   <= s_draw_char;
                  cnt_pix   <= cnt_pix + 1;
                end if;
              else
                ser_tx_req <= '1';
              end if;
              sel_cmd   <= '0';

            when s_done =>
              fsm_spi   <= s_wake;
              cnt_delay <= c_rst_time_act-1;

            when others =>
              fsm_spi <= s_idle;
              cnt_delay <= c_rst_time_act-1;

          end case;
        end if;
    end process;


  -- SPI SERIALIZE
  process(reset_n, clk) is
    begin
        if reset_n='0' then
          fsm_phy    <= s_idle;
          spi_cs_n   <= '1';
          ser_tx_ack <= '0';
          cnt_bit    <= ( others => 0);
        elsif rising_edge(clk) then
          case fsm_phy is

            when s_idle =>
              if ser_tx_req = '1' then
                fsm_phy   <= s_req;
                cnt_bit(0)<= ser_bits;
              else
                fsm_phy   <= s_idle;
                spi_cs_n  <= '1';
              end if;

            when s_req =>
              if ser_tx_now = '1' then
                fsm_phy   <= s_tx;
              elsif spi_clk_ena = '1' then
                fsm_phy   <= s_tx;
                spi_cs_n  <= '0';
              end if;

            when s_tx =>
              if spi_clk_ena = '1' then
                if cnt_bit(0) = 0 then
                  fsm_phy   <= s_ack;
                  ser_tx_ack <= '1';
                else
                  cnt_bit(0)    <= cnt_bit(0) - 1;
                end if;
              end if;

            when s_ack =>
              ser_tx_ack <= '0';
              fsm_phy <= s_idle;

            when others =>
              fsm_phy <= s_idle;

          end case;
        -- pipe
        cnt_bit(1 to cnt_bit'high)    <= cnt_bit(0 to cnt_bit'high-1);
        end if;
    end process;

end rtl;