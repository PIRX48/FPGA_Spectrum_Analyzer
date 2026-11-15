----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:28:12 03/15/2026 
-- Design Name: 
-- Module Name:    uart_tx - Behavioral 
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

entity uart_tx is
    Port ( CLK   : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
			  
           UART_TX_START_IN : in  STD_LOGIC;
           UART_TX_DATA_IN  : in  STD_LOGIC_VECTOR (7 downto 0);
			  UART_TX_START_SW_IN : in STD_LOGIC;
			  
           UART_TX_OUT      : out  STD_LOGIC;
           UART_TX_BUSY_OUT : out  STD_LOGIC);
end uart_tx;

architecture Behavioral of uart_tx is

type state_type is (IDLE, START, DATA, STOP);
signal state : state_type := IDLE;

signal bit_index : integer range 0 to 7 := 0;
signal tx_reg : std_logic := '1';
signal data_buff : std_logic_vector (7 downto 0) := (others => '0');

signal baud_cnt : unsigned (3 downto 0) := (others => '0');
signal baud_tick : std_logic := '0';

begin

UART_TX_OUT <= tx_reg and UART_TX_START_SW_IN;
UART_TX_BUSY_OUT <= '0' when state = IDLE else '1';

process (CLK)
	begin
		if rising_edge(CLK) then
			if reset = '0' then
				baud_cnt <= (others => '0');
				baud_tick <= '0';
			else
				if baud_cnt = 15 then
					baud_cnt <= (others => '0');
					baud_tick <= '1';
				else
					baud_cnt <= baud_cnt + 1;
					baud_tick <= '0';
				end if;
			end if;
		end if;
end process;

process (CLK)
	begin
		if rising_edge(CLK) then
			if reset = '0' then
				state <= IDLE;
				bit_index <= 0;
				tx_reg <= '1';
			elsif baud_tick = '1' then
				case state is
					when IDLE =>
						tx_reg <= '1';
						if UART_TX_START_IN = '1' then
							state <= START;
							data_buff <= UART_TX_DATA_IN;
						end if;
						
					when START =>
						tx_reg <= '0';
						state <= DATA;
						
					when DATA =>
						tx_reg <= data_buff(bit_index);
						if bit_index = 7 then
							state <= STOP;
							bit_index <= 0;
						else
							bit_index <= bit_index + 1;
						end if;
					
					when STOP =>
						tx_reg <= '1';
						state <= IDLE;
						
				end case;
			end if;
		end if;
	end process;
	


end Behavioral;

