------------------------------------------------------------------------------
--  ehternet frame reciever with CRC check and destination check
--  rev. 1.0 : 2024 provoost kris
------------------------------------------------------------------------------

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.eth_pkg.all;
-------------------------------------------------------------------------------
entity eth_frm_rx is

  port (
    iclk          : in std_logic;
    irst_n        : in std_logic;

    irxdata       : in std_logic_vector(7 downto 0);
    irxdv         : in std_logic;
    irxer         : in std_logic;

    orxerr        : out std_logic;
    olenerr       : out std_logic;
    ochecksumerr  : out std_logic;
    opayloadlen   : buffer unsigned(15 downto 0);

    my_dest_mac   : in std_logic_vector(47 downto 0);
    mac_match     : out std_logic;

    osof          : out std_logic;
    oeof          : out std_logic;
    orxdata       : out std_logic_vector(7 downto 0);
    orxdv         : out std_logic
    );

end entity eth_frm_rx;
-------------------------------------------------------------------------------
architecture rtl of eth_frm_rx is

  type t_arr_slv_8  is array (4 downto 0) of std_logic_vector( 7 downto 0);
  type t_arr_slv_32 is array (4 downto 0) of std_logic_vector(31 downto 0);

  signal sof, eof      : std_logic;
  signal crcen, crcen2 : std_logic;

  signal dvdly   : std_logic_vector(4 downto 0);
  signal datadly : t_arr_slv_8;

  type state_t is ( idle,
                    sfd,
                    dest_mac,
                    source_mac,
                    frame_type,
                    payload
                  );
  signal state       : state_t;
  signal bytecnt     : unsigned(15 downto 0);
  signal destmacaddr : std_logic_vector(47 downto 0);

  signal rxdv        : std_logic;
  signal dataen      : std_logic;

  signal crc_calculated : t_arr_slv_32;
  signal crc_is_fine    : std_logic;

begin

  oeof    <= eof;

  --! create enable signals
  rxdv    <= irxdv and dataen and not irxer;    -- when the data is valid
  crcen2  <= irxdv and crcen  and not irxer;    -- when the data needs checksum

  --! register outputs
  process (iclk, irst_n) is
  begin
    if irst_n = '0' then
      orxdata <= (others => '0');
      orxdv   <= '0';
      orxerr  <= '0';
    elsif rising_edge(iclk) then
      orxdata <= datadly(datadly'high);
      orxdv   <= dvdly(dvdly'high) and dataen;
      orxerr  <= irxdv and irxer;
    end if;
  end process;

  --! make a 4 stage delay to compensate for crc calculations
  process (iclk, irst_n) is
  begin
    if irst_n = '0' then
      dvdly      <= (others => '0');
      datadly    <= (others => (others => '0'));
    elsif rising_edge(iclk) then
      datadly    <= datadly(datadly'high-1 downto 0) & irxdata;
      dvdly      <= dvdly(dvdly'high-1 downto 0) & rxdv;
    end if;
  end process;

  --! calculate the checksum
  i_eth_crc32 : entity work.eth_crc32
    port map (
      iclk    => iclk,
      irst_n  => irst_n,
      iinit   => sof,
      icalcen => crcen2,
      idata   => irxdata,
      ocrc    => crc_calculated(0)
    );

  --! compare checksum with recieved data
  process (iclk, irst_n) is
  begin
    if irst_n = '0' then
      crc_calculated(crc_calculated'high downto 1) <= (others => (others => '0'));
      crc_is_fine       <= '0';
    elsif rising_edge(iclk) then
      crc_calculated(crc_calculated'high downto 1) <= crc_calculated(crc_calculated'high-1 downto 0);
      if  datadly(3) = crc_calculated(crc_calculated'high)(8*4-1 downto 8*4-8) and
          datadly(2) = crc_calculated(crc_calculated'high)(8*3-1 downto 8*3-8) and
          datadly(1) = crc_calculated(crc_calculated'high)(8*2-1 downto 8*2-8) and
          datadly(0) = crc_calculated(crc_calculated'high)(8*1-1 downto 8*1-8) then
        crc_is_fine       <= '1';
      else
        crc_is_fine       <= '0';
      end if;
    end if;
  end process;



  process (iclk, irst_n) is
    variable ethtype : std_logic_vector(15 downto 0);
  begin
    if irst_n = '0' then
      state        <= idle;
      eof          <= '0';
      bytecnt      <= (others => '0');
      opayloadlen  <= (others => '0');
      mac_match    <= '0';
      crcen        <= '0';
      sof          <= '0';
      dataen       <= '0';
      destmacaddr  <= (others => '0');
      olenerr      <= '0';
      ochecksumerr <= '0';
      osof         <= '0';
    elsif rising_edge(iclk) then
      eof  <= '0';
      sof  <= '0';
      osof <= '0';

      case state is
        -----------------------------------------------------------------------
        when idle =>
          crcen        <= '0';
          dataen       <= '0';
          mac_match    <= '0';
          olenerr      <= '0';
          ochecksumerr <= '0';

          if irxdata = c_eth_preamble then
            state   <= sfd;
            bytecnt <= (others => '0');
            sof     <= '1';
          end if;
        -----------------------------------------------------------------------
        when sfd =>
          if irxdata = c_eth_preamble then
            bytecnt <= bytecnt + 1;
          elsif irxdata = c_eth_sfd then
            if bytecnt(2 downto 0) = b"110" then
              state   <= dest_mac;
              crcen   <= '1';
              dataen  <= '1';
              osof    <= '1';
              bytecnt <= (others => '0');
            else
              state <= idle;
            end if;
          else
            state <= idle;
          end if;
          if irxdv = '0' then
            state   <= idle;
            eof     <= '1';
            olenerr <= '1';
          end if;
        -----------------------------------------------------------------------
        when dest_mac =>
          if irxdv = '1' and irxer = '0' then
            bytecnt <= bytecnt + 1;
            -- store destination mac addr
            case bytecnt(2 downto 0) is
              when b"000" => destmacaddr(47 downto 40) <= irxdata;
              when b"001" => destmacaddr(39 downto 32) <= irxdata;
              when b"010" => destmacaddr(31 downto 24) <= irxdata;
              when b"011" => destmacaddr(23 downto 16) <= irxdata;
              when b"100" => destmacaddr(15 downto  8) <= irxdata;
              when b"101" => destmacaddr( 7 downto  0) <= irxdata;
              when others => null;
            end case;
            if bytecnt(2 downto 0) = b"101" then
              bytecnt(2 downto 0) <= (others => '0');
              state               <= source_mac;
            end if;
          end if;

          if irxdv = '0' then
            state   <= idle;
            eof     <= '1';
            olenerr <= '1';
          end if;
        -----------------------------------------------------------------------
        when source_mac =>
          -- raise a flag when the frame was for me
          if destmacaddr = my_dest_mac           -- unicast
          or destmacaddr = mac_addr_ctrl         -- multicast for flow control
          or destmacaddr = x"ffffffffffff" then  -- broadcast
            mac_match <= '1';
          end if;
          -- keep frame type
          if irxdv = '1' and irxer = '0' then
            bytecnt <= bytecnt + 1;
            if bytecnt(2 downto 0) = b"101" then
              state               <= frame_type;
              bytecnt(2 downto 0) <= (others => '0');
            end if;
          end if;
          if irxdv = '0' then
            state   <= idle;
            eof     <= '1';
            olenerr <= '1';
          end if;
        -----------------------------------------------------------------------
        when frame_type =>
          if irxdv = '1' and irxer = '0' then
            bytecnt <= bytecnt + 1;
            case bytecnt(0) is
              when '0'    => ethtype(15 downto 8) := irxdata;
              when others => ethtype( 7 downto 0) := irxdata;
            end case;

            if bytecnt(0) = '1' then
              bytecnt(1 downto 0) <= (others => '0');
              state   <= payload;
              dataen  <= '1';
              -- depending on the standard either type or length is in these bytes
              opayloadlen <= unsigned(ethtype);
            end if;
          end if;
          if irxdv = '0' then
            state   <= idle;
            eof     <= '1';
            olenerr <= '1';
          end if;
        -----------------------------------------------------------------------
        when payload =>
          if irxdv = '1' and irxer = '0' then
            bytecnt <= bytecnt + 1;
          end if;
          -- an IPG is transmitted before the next frame, already move to idle again
          if irxdv = '0' then
            state         <= idle;
            dataen        <= '0';
            eof           <= '1';
            ochecksumerr  <= crc_is_fine;
          end if;
        -----------------------------------------------------------------------
        when others =>
          state <= idle;
      end case;

    end if;
  end process;

end architecture rtl;