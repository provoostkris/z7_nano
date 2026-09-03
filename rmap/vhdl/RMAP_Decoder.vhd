-- ============================================================================
-- Title       : RMAP_Decoder
-- Description : ECSS RMAP packet decoder with CRC validation
-- Author      : Kris Provoost
-- ============================================================================

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.pckg_rmap.all;

entity RMAP_Decoder is
  Port (
    clk           : in  std_logic;
    rstn          : in  std_logic;
    byte_in       : in  std_logic_vector(7 downto 0);
    byte_valid    : in  std_logic;
    byte_last     : in  std_logic;
    packet_ready  : out std_logic;
    packet_error  : out std_logic;
    rmap_fields   : out RMAP_Fields_t;
    payload_out   : out std_logic_vector(7 downto 0);
    payload_valid : out std_logic;
    payload_end   : out std_logic
  );
end RMAP_Decoder;

architecture Behavioral of RMAP_Decoder is

  type State_t is ( Idle,
                    Header,
                    Payload,
                    HDR_CRC,
                    DAT_CRC,
                    Done,
                    Error);
  signal state : State_t := Idle;

  signal byte_cnt : integer := 0;
  signal payload_cnt : integer := 0;

  signal header_crc_val  : std_logic;
  signal data_crc_val    : std_logic;
  signal crc_hdr_byte    : std_logic_vector(7 downto 0);
  signal crc_hdr_reg     : std_logic_vector(7 downto 0);
  signal crc_dat_byte    : std_logic_vector(7 downto 0);
  signal crc_dat_reg     : std_logic_vector(7 downto 0);
  signal crc_hdr_capt    : std_logic_vector(7 downto 0);
  signal crc_dat_capt    : std_logic_vector(7 downto 0);

begin

  -- Header CRC
process(clk)
  begin
    if rising_edge(clk) then
      if rstn = '0' then
        crc_hdr_byte <= ( others => '0');
        crc_hdr_reg  <= ( others => '0');
      else
        crc_hdr_byte <= byte_in;
        if header_crc_val then
          crc_hdr_reg <= RMAP_CalculateCRC(crc_hdr_reg,crc_hdr_byte);
        end if;
      end if;
    end if;
end process;

-- Payload CRC
process(clk)
  begin
    if rising_edge(clk) then
      if rstn = '0' then
        crc_dat_byte <= ( others => '0');
        crc_dat_reg  <= ( others => '0');
      else
        crc_dat_byte <= byte_in;
        if data_crc_val then
          crc_dat_reg <= RMAP_CalculateCRC(crc_dat_reg,crc_dat_byte);
        end if;
      end if;
    end if;
end process;

header_crc_val <= byte_valid when (state = Header) else '0';
payload_valid <= data_crc_val;

  process(clk)
  begin
    if rising_edge(clk) then
      if rstn = '0' then
        state <= Idle;
        byte_cnt <= 0;
        payload_cnt <= 0;
        packet_ready <= '0';
        packet_error <= '0';
        data_crc_val <= '0';
        payload_out  <= ( others => '0');
        payload_end  <= '0';
        crc_hdr_capt <= ( others => '0');
        crc_dat_capt <= ( others => '0');
      else

        case state is

          when Idle =>
            if byte_valid = '1' then
              state <= Header;
            end if;
            byte_cnt <= 1;
            payload_cnt <= 0;
            rmap_fields.target_logical <= byte_in;

          when Header =>
            if byte_valid = '1' then
              case byte_cnt is
                when 1 => rmap_fields.protocol_id <= byte_in;
                when 2 => rmap_fields.instruction <= byte_in;
                when 3 => rmap_fields.key <= byte_in;
                when 4 => rmap_fields.initiator_logical <= byte_in;
                when 5 => rmap_fields.transaction_id(15 downto 8) <= byte_in;
                when 6 => rmap_fields.transaction_id(7 downto 0)  <= byte_in;
                when 7 => rmap_fields.ext_address <= byte_in;
                when 8 => rmap_fields.address(31 downto 24) <= byte_in;
                when 9 => rmap_fields.address(23 downto 16) <= byte_in;
                when 10 => rmap_fields.address(15 downto 8)  <= byte_in;
                when 11 => rmap_fields.address(7 downto 0)   <= byte_in;
                when 12 => rmap_fields.data_length(23 downto 16) <= byte_in;
                when 13 => rmap_fields.data_length(15 downto 8) <= byte_in;
                when 14 => rmap_fields.data_length(7 downto 0) <= byte_in;
                when others =>
                  crc_hdr_capt <= byte_in;
                  state <= Payload;
              end case;
              byte_cnt <= byte_cnt + 1;
            end if;

          when Payload =>

            if byte_valid = '1' then
              if payload_cnt = to_integer(unsigned(rmap_fields.data_length)) then
                state <= HDR_CRC;
                crc_dat_capt <= byte_in;
                data_crc_val <= '0';
                payload_end <= byte_last;
              else
                payload_out <= byte_in;
                data_crc_val <= '1';
                payload_end  <= '0';
                payload_cnt <= payload_cnt + 1;
              end if;
              -- substract the CRC byte, and indicate the last byte
              if payload_cnt = to_integer(unsigned(rmap_fields.data_length))-1 then
                payload_end  <= '1';
              else
                payload_end  <= byte_last;
              end if;
            end if;

          when HDR_CRC =>
            if crc_hdr_capt = crc_hdr_reg then
              state <= DAT_CRC;
            else
              packet_error <= '1';
              state <= Error;
            end if;
            -- reset the values
            payload_out  <= ( others => '0');
            payload_end  <= '0';

          when DAT_CRC =>
            if crc_dat_capt = crc_dat_reg then
              state <= Done;
              packet_ready <= '1';
            else
              packet_error <= '1';
              state <= Error;
            end if;

          when Done =>
            packet_ready <= '0';
            packet_error <= '0';
            data_crc_val <= '0';
            state <= Idle;

          when Error =>
            packet_ready <= '0';
            packet_error <= '0';
            data_crc_val <= '0';
            state <= Idle;

        end case;
      end if;
    end if;
  end process;

end Behavioral;
