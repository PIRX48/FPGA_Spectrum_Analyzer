----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:34:43 03/19/2026 
-- Design Name: 
-- Module Name:    fsm - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fsm is
    Port ( CLK   : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
			  
			  FSM_START_IN    :in STD_LOGIC;
			  FSM_TX_BUSY_IN  :in STD_LOGIC;
			  FSM_DONE_OUT    :out STD_LOGIC;

			  FSM_RAM_DATA_IN  :in STD_LOGIC_VECTOR(31 downto 0);
			  FSM_RAM_ADR_OUT  : out STD_LOGIC_VECTOR(9 downto 0);
			  
			  FSM_TX_START_OUT  : out STD_LOGIC;
			  FSM_TX_DATA_OUT   : out STD_LOGIC_VECTOR(7 downto 0));
end fsm;

architecture Behavioral of fsm is

type state_type is (IDLE, START_BIT, WAIT_LENGHT_LSB, SEND_LENGHT_LSB, WAIT_LENGHT_MSB, SEND_LENGHT_MSB,
WAIT_DATA_0, SEND_DATA_0, WAIT_DATA_1, SEND_DATA_1, WAIT_DATA_2, SEND_DATA_2, WAIT_DATA_3, SEND_DATA_3,
WAIT_CRC_LSB, SEND_CRC_LSB, WAIT_CRC_MSB, SEND_CRC_MSB, DONE);

signal state      : state_type := IDLE;

signal start_sync_0    : std_logic := '0';
signal start_sync_1    : std_logic := '0';

signal valid_start_d : std_logic := '0';
signal valid_start_rise : std_logic := '0';

signal idx : integer range 0 to 1023 := 0;

signal start      : std_logic := '1';

signal crc        : std_logic_vector(15 downto 0) := x"FFFF";

function crc16_update(
    crc_in  : std_logic_vector(15 downto 0);
    data_in : std_logic_vector(7 downto 0)
) return std_logic_vector is
    variable crc  : unsigned(15 downto 0) := unsigned(crc_in);
    variable data : unsigned(7 downto 0)  := unsigned(data_in);
begin
    -- XOR CRC z bajtem danych
    crc := crc xor resize(data, 16);
	 
    -- 8 iteracji
    for i in 0 to 7 loop
        if (crc(0) = '1') then
            crc := (crc srl 1) xor x"A001";
        else
            crc := crc srl 1;
        end if;
    end loop;

    return std_logic_vector(crc);
end function;

begin

process(CLK)
begin
    if rising_edge(CLK) then
        start_sync_0 <= FSM_START_IN;
        start_sync_1 <= start_sync_0;
    end if;
end process;

process(CLK)
begin
    if rising_edge(CLK) then
        valid_start_d <= start_sync_1;
        valid_start_rise <= start_sync_1 and not valid_start_d;
    end if;
end process;

process(clk)
begin
    if rising_edge(clk) then
        if reset = '0' then
            state            <= IDLE;
				FSM_TX_START_OUT <= '0';
				FSM_DONE_OUT <= '0';
				FSM_TX_DATA_OUT  <= (others => '0');
            idx              <= 0;
				crc              <= x"FFFF";
				
        else
            case state is
				
					when IDLE =>
						if valid_start_rise = '1' then
							FSM_TX_DATA_OUT <= (others => '0');
							FSM_DONE_OUT <= '0';
							idx   <= 0;
							crc   <= x"FFFF";
							state <= START_BIT;
						end if;
				
					when START_BIT =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= x"AA";
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, x"AA");
							state <= WAIT_LENGHT_LSB;
						end if;
						
					when WAIT_LENGHT_LSB =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_LENGHT_LSB;
						end if;
						
					when SEND_LENGHT_LSB =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= x"00"; -- 2048 LSB
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, x"00");
							state <= WAIT_LENGHT_MSB;
						end if;
						
					when WAIT_LENGHT_MSB =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_LENGHT_MSB;
						end if;
						
					when SEND_LENGHT_MSB =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= x"08"; -- 2048 MSB
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, x"08");
							state <= WAIT_DATA_0;
						end if;
						
					when WAIT_DATA_0 =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							FSM_RAM_ADR_OUT <= std_logic_vector(to_unsigned(idx, FSM_RAM_ADR_OUT'length));
							state <= SEND_DATA_0;
						end if;
						
					when SEND_DATA_0 =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= FSM_RAM_DATA_IN(7 downto 0);
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, FSM_RAM_DATA_IN(7 downto 0));
							state <= WAIT_DATA_1;
						end if;
						
						when WAIT_DATA_1 =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_DATA_1;
						end if;
						
					when SEND_DATA_1 =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= FSM_RAM_DATA_IN(15 downto 8);
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, FSM_RAM_DATA_IN(15 downto 8));
							state <= WAIT_DATA_2;
						end if;
						
						when WAIT_DATA_2 =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_DATA_2;
						end if;
						
					when SEND_DATA_2 =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= FSM_RAM_DATA_IN(23 downto 16);
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, FSM_RAM_DATA_IN(23 downto 16));
							state <= WAIT_DATA_3;
						end if;
						
					when WAIT_DATA_3 =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_DATA_3;
						end if;
						
					when SEND_DATA_3 =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= FSM_RAM_DATA_IN(31 downto 24);
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							crc <= crc16_update(crc, FSM_RAM_DATA_IN(31 downto 24));
							if idx = 511 then
								state <= WAIT_CRC_LSB;
							else
								idx <= idx + 1;
								state <= WAIT_DATA_0;
							end if;
						end if;
						
					when WAIT_CRC_LSB =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_CRC_LSB;
						end if;
					
					when SEND_CRC_LSB =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= CRC(7 downto 0);
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '0';
							state <= WAIT_CRC_MSB;
						end if;
					
					when WAIT_CRC_MSB =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '0';
							state <= SEND_CRC_MSB;
						end if;
					
					when SEND_CRC_MSB =>
						if FSM_TX_BUSY_IN = '0' then
							FSM_TX_DATA_OUT <= CRC(15 downto 8);
							FSM_TX_START_OUT <= '1';
							FSM_DONE_OUT <= '1';
							state <= DONE;
						end if;
						
					when DONE =>
						if FSM_TX_BUSY_IN = '1' then
							FSM_TX_START_OUT <= '0';
							FSM_DONE_OUT <= '1';
							idx <= 0;
							state <= IDLE;
						end if;
						
					when others =>
							state <= IDLE;
						
            end case;
        end if;
    end if;
end process;

end Behavioral;

