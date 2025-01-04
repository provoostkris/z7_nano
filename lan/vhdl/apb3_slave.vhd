------------------------------------------------------------------------------
--!  APB3_slave
--!  rev. 1.0 : 2025 MicroSoft copilot
------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity apb3_slave is
    port(
        PCLK    : in  std_logic;          -- APB clock
        PRESETn : in  std_logic;          -- APB reset (active low)
        PSEL    : in  std_logic;          -- APB slave select
        PENABLE : in  std_logic;          -- APB enable
        PWRITE  : in  std_logic;          -- APB write
        PADDR   : in  std_logic_vector(31 downto 0); -- APB address
        PWDATA  : in  std_logic_vector(31 downto 0); -- APB write data
        PRDATA  : out std_logic_vector(31 downto 0); -- APB read data
        PREADY  : out std_logic;          -- APB ready
        PSLVERR : out std_logic;          -- APB slave error
        reg_val : out std_logic_vector(31 downto 0) -- register value
    );
end apb3_slave;

architecture Behavioral of apb3_slave is
    signal reg_data : std_logic_vector(31 downto 0);
begin

    --! assign for external use
    reg_val <= reg_data ;

    --! slave control
    process(PCLK, PRESETn)
    begin
        if PRESETn = '0' then
            PRDATA   <= (others => '0');
            PREADY   <= '0';
            PSLVERR  <= '0';
            reg_data <= (others => '0');
        elsif rising_edge(PCLK) then
            if PSEL = '1' then
                if PENABLE = '1' then
                    if PWRITE = '1' then
                        reg_data <= PWDATA;
                        PREADY <= '1';
                        PSLVERR <= '0';
                    else
                        PRDATA <= reg_data;
                        PREADY <= '1';
                        PSLVERR <= '0';
                    end if;
                else
                    PREADY <= '0';
                    PSLVERR <= '0';
                end if;
            else
                PREADY <= '0';
                PSLVERR <= '0';
            end if;
        end if;
    end process;
end Behavioral;