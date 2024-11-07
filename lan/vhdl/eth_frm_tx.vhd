------------------------------------------------------------------------------
--  ETH TX framer
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-------------------------------------------------------------------------------
entity eth_frm_tx is

  port (

    clk          : in  std_logic;
    rst_n        : in  std_logic;
    -- signal from axis stream
    s_tready     : out std_logic;
    s_tdata      : in  std_logic_vector(7 downto 0);
    s_tdata      : in  std_logic;
    s_tvalid     : in  std_logic;
    -- signals to phy
    txdata       : out std_logic_vector(7 downto 0);
    txen         : out std_logic;
    txerr        : out std_logic
    );

end entity eth_frm_tx;
-------------------------------------------------------------------------------
architecture rtl of eth_frm_tx is

  type state_t is ( idle,
                    preamble,
                    delimit,
                    send_data,
                    pad,
                    send_crc,
                    ipg
                  );
  signal state                      : state_t;
  attribute syn_encoding            : string;
  attribute syn_encoding of state_t : type is "safe,onehot";

  signal cnt_bytes : unsigned(15 downto 0);

  signal crcinit   : std_logic;
  signal crcen     : std_logic;
  signal crc       : std_logic_vector(31 downto 0);

begin  -- architecture rtl

  --! calculate the crc 32
  i_eth_crc32 : entity work.eth_crc32
    port map (
      iclk    => clk,
      irst_n  => rst_n,
      iinit   => crcinit,
      icalcen => crcen,
      idata   => s_tdata,
      ocrc    => crc
    );

  -- no error use for TX framer
  txerr        <= '0';

  process (clk, rst_n) is
  begin
    if rst_n = '0' then
      state        <= idle;
      cnt_bytes      <= (others => '0');
      crcinit      <= '0';
      crcen        <= '0';
      s_tready     <= '0';
      txdata       <= (others => '0');
      txen         <= '0';
    elsif rising_edge(clk) then
      case state is
        -----------------------------------------------------------------------
        when idle =>
          crcinit      <= '0';
          cnt_bytes    <= to_unsigned(0,cnt_bytes'length);
          -- if the TX contains data , then start framing
          if s_tvalid = '1' then
            state        <= preamble;
          end if;
        -----------------------------------------------------------------------
        when preamble =>
          crcinit      <= '1';
          txen         <= '1';
          txdata       <= x"55";
          cnt_bytes    <= cnt_bytes + to_unsigned(1,cnt_bytes'length) ;
          if cnt_bytes = to_unsigned(6,cnt_bytes'length) then
            state        <= delimit;
          end if;
        -----------------------------------------------------------------------
        when delimit =>
          crcinit      <= '0';
          txen         <= '1';
          txdata       <= x"d5";
          crcen        <= '1';
          s_tready     <= '1';
          state        <= send_data;
        -----------------------------------------------------------------------
        when send_data =>
          cnt_bytes    <= to_unsigned(0,cnt_bytes'length);

          txen         <= s_tvalid;
          txdata       <= s_tdata;

          if s_tdata = '1' then
            state        <= send_crc;
            crcen        <= '0';
            s_tready     <= '0';
          end if;
        -----------------------------------------------------------------------
        when send_crc =>
          txen         <= '1';
          cnt_bytes    <= cnt_bytes + to_unsigned(1,cnt_bytes'length) ;
          case cnt_bytes(1 downto 0) is
            when b"00"  => txdata <= crc(31 downto 24);
            when b"01"  => txdata <= crc(23 downto 16);
            when b"10"  => txdata <= crc(15 downto 08);
            when others => txdata <= crc(07 downto 00);
                           state  <= ipg;
          end case;
        -----------------------------------------------------------------------
        when ipg =>                     -- 96 bits(12 bytes) time
          txen         <= '0';
          txdata       <= ( others => '0');
          cnt_bytes    <= cnt_bytes + to_unsigned(1,cnt_bytes'length) ;
          if cnt_bytes = to_unsigned(15,cnt_bytes'length) then
            state     <= idle;
          end if;
        -----------------------------------------------------------------------
        when others => null;
      end case;
    end if;
  end process;

end architecture rtl;