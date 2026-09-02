library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.rmap_ahb_verif_pkg.all;
use work.rmap_ahb_verif_pkg.all;

entity tb_rmap_to_ahb_bridge is
end entity;

architecture sim of tb_rmap_to_ahb_bridge is

  signal clk           : std_logic := '0';
  signal rst_n         : std_logic := '0';

  signal rmap_valid    : std_logic := '0';
  signal rmap_is_write : std_logic := '0';
  signal rmap_address  : std_logic_vector(31 downto 0) := (others => '0');
  signal rmap_data_in  : std_logic_vector(31 downto 0) := (others => '0');
  signal rmap_data_out : std_logic_vector(31 downto 0);
  signal rmap_ready    : std_logic;

  signal haddr         : std_logic_vector(31 downto 0);
  signal hwrite        : std_logic;
  signal htrans        : std_logic_vector(1 downto 0);
  signal hsize         : std_logic_vector(2 downto 0);
  signal hburst        : std_logic_vector(2 downto 0);
  signal hprot         : std_logic_vector(3 downto 0);
  signal hwdata        : std_logic_vector(31 downto 0);
  signal hrdata        : std_logic_vector(31 downto 0);
  signal hready        : std_logic := '1';
  signal hresp         : std_logic_vector(1 downto 0) := "00";
  signal hbusreq       : std_logic;
  signal hgrant        : std_logic;

  -- Randomization seed
  signal seed : unsigned(31 downto 0) := x"12345678";

  function rand32(s : in unsigned) return unsigned is
  begin
    return s xor (s(30 downto 0) & '0') xor x"9E3779B9";
  end function;

begin

  clk <= not clk after 5 ns;

  dut: entity work.rmap_to_ahb_bridge
    port map (
      clk             => clk,
      rst_n           => rst_n,
      rmap_valid      => rmap_valid,
      rmap_is_write   => rmap_is_write,
      rmap_address    => rmap_address,
      rmap_data_in    => rmap_data_in,
      rmap_data_out   => rmap_data_out,
      rmap_ready      => rmap_ready,
      haddr           => haddr,
      hwrite          => hwrite,
      htrans          => htrans,
      hsize           => hsize,
      hburst          => hburst,
      hprot           => hprot,
      hwdata          => hwdata,
      hrdata          => hrdata,
      hready          => hready,
      hresp           => hresp,
      hbusreq         => hbusreq,
      hgrant          => hgrant
    );

  stim: process
    variable addr, data : std_logic_vector(31 downto 0);
    variable i : integer := 0;
  begin
    hrdata <= ( others => '0');
    rst_n <= '0';
    wait for 20 ns;
    wait until rising_edge(clk);
    rst_n <= '1';
    wait for 10 ns;
    wait until rising_edge(clk);

    for i in 0 to 9 loop
      seed <= rand32(seed);
      addr := std_logic_vector(seed and x"0000FFF0");
      seed <= rand32(seed);
      data := std_logic_vector(seed);
      hrdata <= std_logic_vector(seed);

      -- Write transaction
      rmap_valid    <= '1';
      rmap_is_write <= '1';
      rmap_address  <= addr;
      rmap_data_in  <= data;
      wait until rising_edge(clk);
      rmap_valid    <= '0';

      wait until rmap_ready = '1';
      check_write_transaction(clk, haddr, hwrite, htrans, hburst, hwdata, addr, data);
      wait until rising_edge(clk);

      -- Read transaction
      rmap_valid    <= '1';
      rmap_is_write <= '0';
      rmap_address  <= addr;
      wait until rising_edge(clk);
      rmap_valid    <= '0';

      wait until rmap_ready = '1';
      check_read_transaction(clk, haddr, hwrite, htrans, hburst, rmap_data_out, addr, hrdata);

      wait until rising_edge(clk);
      wait until rising_edge(clk);
    end loop;

    assert false report "Randomized simulation complete." severity note;
    wait;
  end process;

  grant: process
  begin
      hgrant <= '0';
      wait until rising_edge(hbusreq);
      wait until rising_edge(clk);
      hgrant <= '1';
      wait until rising_edge(rmap_ready);
      wait until rising_edge(clk);
  end process;

  time_out: process
  begin
    wait for 2 us;
    report "Time out expired." severity note;
    std.env.stop;
  end process;

end architecture;
