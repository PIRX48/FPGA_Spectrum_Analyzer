----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:28:31 05/29/2026 
-- Design Name: 
-- Module Name:    mag - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity mag is
    port(CLK        : in  std_logic;
         RESET      : in  std_logic;
			
			MAG_DATA_END_IN : in  std_logic; 
         MAG_DATA_IN : in  std_logic_vector(31 downto 0);
--         MAG_IDX_IN  : in  std_logic_vector(9 downto 0);
         MAG_DATA_VALID_IN : in  std_logic;
			
			MAG_DATA_END_OUT : out  std_logic; 
         MAG_DATA_OUT : out std_logic_vector(31 downto 0);
--         MAG_IDX_OUT  : out std_logic_vector(9 downto 0);
         MAG_DATA_VALID_OUT : out std_logic);
end entity;

architecture rtl of mag is

--Cordic IP core created by Xilinx
COMPONENT cordic_core
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_cartesian_tvalid : IN STD_LOGIC;
    s_axis_cartesian_tlast : IN STD_LOGIC;
    s_axis_cartesian_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_dout_tvalid : OUT STD_LOGIC;
    m_axis_dout_tlast : OUT STD_LOGIC;
    m_axis_dout_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;

component dbfs_mitchell_halla is
    Port (
        CLK      : in  STD_LOGIC;
		  RESET    : in  STD_LOGIC;
		  
        MICHELL_DATA_IN        : in  STD_LOGIC_VECTOR(31 downto 0);
		  MICHELL_DATA_VALID_IN  : in  STD_LOGIC;
		  MICHELL_LAST_IN        : in  STD_LOGIC;
		  
        MICHELL_DATA_OUT       : out  STD_LOGIC_VECTOR(31 downto 0); -- Wynik Q8.24 (signed)
		  MICHELL_DATA_VALID_OUT : out  STD_LOGIC;
		  MICHELL_LAST_OUT       : out  STD_LOGIC
    );
end component;

signal data_reg_1  : signed(31 downto 0);
signal data_reg_2_1  : signed(31 downto 0);
signal data_reg_2_2  : signed(31 downto 0);
signal data_reg_3  : signed(31 downto 0);
	 
--signal idx_reg_1   : std_logic_vector(9 downto 0);
--signal idx_reg_2   : std_logic_vector(9 downto 0);
--signal idx_reg_3   : std_logic_vector(9 downto 0);
	 
signal valid_reg_1 : std_logic;
signal valid_reg_2 : std_logic;
signal valid_reg_3 : std_logic;

signal end_reg_1 : std_logic;
signal end_reg_2 : std_logic;
signal end_reg_3 : std_logic;

--signal mag_data_out_s : std_logic_vector(31 downto 0);

begin


process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '0' then
                data_reg_1  <= (others => '0');
					 data_reg_2_1  <= (others => '0');
					 data_reg_2_2  <= (others => '0');
					 data_reg_3  <= (others => '0');
					 
--                idx_reg_1   <= (others => '0');
--					 idx_reg_2   <= (others => '0');
--					 idx_reg_3   <= (others => '0');

                valid_reg_1 <= '0';
					 valid_reg_2 <= '0';
					 valid_reg_3 <= '0';
					 
					 end_reg_1   <= '0';
					 end_reg_2   <= '0';
					 end_reg_3   <= '0';

            else
                data_reg_1  <= signed(MAG_DATA_IN);
					 data_reg_2_1  <= data_reg_1(15 downto 0) * data_reg_1(15 downto 0);
					 data_reg_2_2  <= data_reg_1(31 downto 16) * data_reg_1(31 downto 16);
					 data_reg_3  <= data_reg_2_1 + data_reg_2_2;
					 
--					 idx_reg_1 <= MAG_IDX_IN;
--                idx_reg_2 <= idx_reg_1;
--					 idx_reg_23 <= idx_reg_2;
					 
                valid_reg_1 <= MAG_DATA_VALID_IN;
                valid_reg_2 <= valid_reg_1;
					 valid_reg_3 <= valid_reg_2;
					 
					 end_reg_1 <= MAG_DATA_END_IN;
                end_reg_2 <= end_reg_1;
					 end_reg_3 <= end_reg_2;

            end if;
        end if;
end process;

c2 : dbfs_mitchell_halla
  PORT MAP (
    CLK => CLK,
    RESET => RESET,
	 
    MICHELL_DATA_IN       => std_logic_vector(data_reg_3),
    MICHELL_DATA_VALID_IN => valid_reg_3,
    MICHELL_LAST_IN       => end_reg_3,
	 
    MICHELL_DATA_OUT       => MAG_DATA_OUT,
    MICHELL_DATA_VALID_OUT => MAG_DATA_VALID_OUT,
    MICHELL_LAST_OUT       => MAG_DATA_END_OUT
  );

end architecture;

