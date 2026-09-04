library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.amba.all;

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

  signal ahbi          : ahb_mst_in_type  := ahbm_in_none;
  signal ahbo          : ahb_mst_out_type := ahbm_none;

  signal data_store    : std_logic_vector(31 downto 0) := (others => '0');

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
      ahbi            => ahbi,
      ahbo            => ahbo
    );

  stim: process
    variable addr, data : std_logic_vector(31 downto 0);
  begin
    ahbi.hresp <= HRESP_OKAY;
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

      -- Write transaction
      rmap_valid    <= '1';
      rmap_is_write <= '1';
      rmap_address  <= addr;
      rmap_data_in  <= data;
      wait until rising_edge(clk);
      rmap_valid    <= '0';
      rmap_is_write <= '0';
      rmap_address  <= ( others => '0');
      rmap_data_in  <= ( others => '0');

      wait until rmap_ready = '1';

      -- Read transaction
      rmap_valid    <= '1';
      rmap_is_write <= '0';
      rmap_address  <= addr;
      wait until rising_edge(clk);
      rmap_valid    <= '0';
      wait until rising_edge(clk);

      wait until rmap_ready = '1';
      if rmap_data_out /= data then
        report "Error: rmap_data_out should be : " & to_hstring(rmap_data_out) severity error;
      end if;
      wait until rising_edge(clk);
    end loop;

    assert false report "Randomized simulation complete." severity note;
    wait;
  end process;

  grant: process
  begin
      ahbi.hgrant <= (others => '0');
      wait until rising_edge(ahbo.hbusreq);
      wait until rising_edge(clk);
      ahbi.hgrant(0) <= '1';
      wait until rising_edge(rmap_ready);
      wait until rising_edge(clk);
  end process;


      -- always ready
      ahbi.hready <= '1';

  --! the last written data is stored
  --! so it can be read back
  p_data_wr: process (clk)
  begin
    if rising_edge(clk) then
      if ahbi.hgrant(0) = '1' and
         ahbo.hbusreq = '1' and
         ahbo.hwrite = '1' and
         ahbi.hready = '1' then
          data_store <= ahbo.hwdata;
      end if;
    end if;
  end process;
  --! read back the data
  p_data_rd: process (ahbi.hgrant(0))
  begin
    if rising_edge(ahbi.hgrant(0)) then
      if ahbo.hbusreq = '1' and
         ahbo.hwrite = '0' and
         ahbi.hready = '1' then
          ahbi.hrdata <= data_store;
      end if;
    end if;
  end process;


  time_out: process
  begin
    wait for 1200 ns;
    report "Time out expired." severity note;
    std.env.stop;
  end process;

end architecture;
