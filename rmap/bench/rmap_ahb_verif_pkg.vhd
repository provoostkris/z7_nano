library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package rmap_ahb_verif_pkg is

  procedure check_write_transaction (
    signal clk    : in std_logic;
    signal haddr  : in std_logic_vector(31 downto 0);
    signal hwrite : in std_logic;
    signal htrans : in std_logic_vector(1 downto 0);
    signal hburst : in std_logic_vector(2 downto 0);
    signal hwdata : in std_logic_vector(31 downto 0);
    constant expected_addr : in std_logic_vector(31 downto 0);
    constant expected_data : in std_logic_vector(31 downto 0)
  );

  procedure check_read_transaction (
    signal clk    : in std_logic;
    signal haddr  : in std_logic_vector(31 downto 0);
    signal hwrite : in std_logic;
    signal htrans : in std_logic_vector(1 downto 0);
    signal hburst : in std_logic_vector(2 downto 0);
    signal rmap_data_out : in std_logic_vector(31 downto 0);
    constant expected_addr : in std_logic_vector(31 downto 0);
    constant expected_data : in std_logic_vector(31 downto 0)
  );

end package;

package body rmap_ahb_verif_pkg is

  procedure check_write_transaction (
    signal clk    : in std_logic;
    signal haddr  : in std_logic_vector(31 downto 0);
    signal hwrite : in std_logic;
    signal htrans : in std_logic_vector(1 downto 0);
    signal hburst : in std_logic_vector(2 downto 0);
    signal hwdata : in std_logic_vector(31 downto 0);
    constant expected_addr : in std_logic_vector(31 downto 0);
    constant expected_data : in std_logic_vector(31 downto 0)
  ) is
  begin
    wait until rising_edge(clk);
    assert haddr = expected_addr
      report "Write address mismatch" severity error;
    assert hwrite = '1'
      report "Write control signal mismatch" severity error;
    assert htrans = "10"
      report "HTRANS should be NONSEQ for single transfer" severity error;
    assert hburst = "000"
      report "HBURST should be SINGLE for single transfer" severity error;
    assert hwdata = expected_data
      report "Write data mismatch" severity error;
  end procedure;

  procedure check_read_transaction (
    signal clk    : in std_logic;
    signal haddr  : in std_logic_vector(31 downto 0);
    signal hwrite : in std_logic;
    signal htrans : in std_logic_vector(1 downto 0);
    signal hburst : in std_logic_vector(2 downto 0);
    signal rmap_data_out : in std_logic_vector(31 downto 0);
    constant expected_addr : in std_logic_vector(31 downto 0);
    constant expected_data : in std_logic_vector(31 downto 0)
  ) is
  begin
    wait until rising_edge(clk);
    assert haddr = expected_addr
      report "Read address mismatch" severity error;
    assert hwrite = '0'
      report "Read control signal mismatch" severity error;
    assert htrans = "10"
      report "HTRANS should be NONSEQ for single transfer" severity error;
    assert hburst = "000"
      report "HBURST should be SINGLE for single transfer" severity error;
    assert rmap_data_out = expected_data
      report "Read data mismatch" severity error;
  end procedure;

end package body;
