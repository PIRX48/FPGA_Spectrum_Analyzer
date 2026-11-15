----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:11:13 03/22/2026 
-- Design Name: 
-- Module Name:    ram_dual_port - Behavioral 
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

entity ram_dual_port is
    Port ( CLK_IN : in  STD_LOGIC;
			  CLK_OUT : in  STD_LOGIC;
			  
			  RAM_WE_IN : in  STD_LOGIC;
           RAM_DATA_IN : in  STD_LOGIC_VECTOR (31 downto 0);
           RAM_ADR_IN : in  STD_LOGIC_VECTOR(9 downto 0);
           
           RAM_DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0);
           RAM_ADR_OUT : in  STD_LOGIC_VECTOR(9 downto 0));
end ram_dual_port;

architecture Behavioral of ram_dual_port is

type ram_type is array (0 to 1023) of std_logic_vector (31 downto 0);
signal ram : ram_type := (others => (others => '0'));

signal data_out_reg : std_logic_vector (31 downto 0);

begin

write_process : process (CLK_IN)
begin
if rising_edge (CLK_IN) then
		if RAM_WE_IN = '1' then 
			ram(to_integer(unsigned(RAM_ADR_IN))) <= RAM_DATA_IN;
		end if;
end if;
end process;

read_process : process (CLK_OUT)
begin
if rising_edge (CLK_OUT) then
		data_out_reg <= ram(to_integer(unsigned(RAM_ADR_OUT)));
end if;
end process;

RAM_DATA_OUT <= data_out_reg;

end Behavioral;

