----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:18:50 03/22/2026 
-- Design Name: 
-- Module Name:    data_collector - Behavioral 
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

entity data_collector is
    Port ( CLK : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
			  
           DC_DATA_VALID_IN : in  STD_LOGIC;
           DC_DATA_IN       : in  STD_LOGIC_VECTOR (31 downto 0);
--			  DC_DATA_IDX_IN   : in  STD_LOGIC_VECTOR (9 downto 0);
			  DC_DATA_END_IN   : in std_logic;
			  
           DC_START_CONV_IN : in  STD_LOGIC;
           DC_END_CONV_OUT  : out  STD_LOGIC;
			  
           DC_WE_OUT   : out  STD_LOGIC;
           DC_ADR_OUT  : out  STD_LOGIC_VECTOR (9 downto 0);
           DC_DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0));
end data_collector;

architecture Behavioral of data_collector is

type state_type is (IDLE, WAIT_PERIOD, WAIT_DATA, WRITE_DATA, DONE);
signal state : state_type;

signal idx : integer range 0 to 1023 := 0;

--signal idx : std_logic_vector(9 downto 0) := (others => '0');

signal counter : integer range 0 to 12_280_000 - 1 := 0;

signal data  : std_logic_vector(15 downto 0) := (others => '0');
signal end_conv_s : std_logic;

--signal start_sync_0    : std_logic := '0';
--signal start_sync_1    : std_logic := '0';

--signal end_sync_0    : std_logic := '0';
--signal end_sync_1    : std_logic := '0';

--signal valid_data_d : std_logic := '0';
--signal valid_data_rise : std_logic := '0';

signal valid_start_d : std_logic := '0';
signal valid_start_rise : std_logic := '0';

begin

process(CLK)
begin
    if rising_edge(CLK) then
        if reset = '0' then
            state <= IDLE;
            counter <= 0;
				idx <= 0;
            DC_WE_OUT <= '0';
            DC_ADR_OUT <= (others => '0');
            DC_DATA_OUT <= (others => '0'); 
            DC_END_CONV_OUT <= '0';
        else
            case state is
                
                when IDLE =>
                    DC_END_CONV_OUT <= '0';
                    DC_WE_OUT <= '0';
                    idx <= 0;
						  
                    
                    if DC_DATA_END_IN = '1' and DC_DATA_VALID_IN = '1' then 
--						  if DC_DATA_END_IN = '1' then 
                        state <= WRITE_DATA;
                    end if;
                    
                when WRITE_DATA =>
                    
                    if DC_DATA_VALID_IN = '1' then
                        DC_WE_OUT   <= '1';
                        DC_DATA_OUT <= DC_DATA_IN;
								DC_ADR_OUT  <= std_logic_vector(to_unsigned(idx, DC_ADR_OUT'length));
--                        DC_ADR_OUT  <= DC_DATA_IDX_IN;
                        
                        
                        if DC_DATA_END_IN = '1' then
                            state <= DONE;
									 idx <= 0;
							   else
									idx <= idx + 1;
									 
                        end if;
                    else
                        
                        DC_WE_OUT <= '0';
								
                    end if;
                                    
                when DONE =>
                    DC_WE_OUT <= '0';
                    DC_END_CONV_OUT <= '1';
                    counter <= 0;
                    if valid_start_rise = '1' then
                        state <= WAIT_PERIOD;
                    end if;
                    
                when WAIT_PERIOD =>
                    DC_END_CONV_OUT <= '0';
                    if counter = 4_000_000 - 1 then
                        state <= IDLE;
                        counter <= 0;
                    else
                        counter <= counter + 1;
                    end if;
					
					 when others =>
						state <= IDLE;
            
            end case;
        end if;
    end if;
end process;

--process(CLK)
--begin
--    if rising_edge(CLK) then
--        valid_data_d <= DC_DATA_VALID_IN;
--        valid_data_rise <= DC_DATA_VALID_IN and not valid_data_d;
--    end if;
--end process;
--
--process(CLK)
--begin
--    if rising_edge(CLK) then
--        start_sync_0 <= DC_START_CONV_IN;
--        start_sync_1 <= start_sync_0;
--    end if;
--end process;

process(CLK)
begin
    if rising_edge(CLK) then
        valid_start_d <= DC_START_CONV_IN;
        valid_start_rise <= DC_START_CONV_IN and not valid_start_d;
    end if;
end process;

--process(CLK)
--begin
--    if rising_edge(CLK) then
--        end_sync_0 <= end_conv_s;
--        end_sync_1 <= end_sync_0;
--    end if;
--end process;
--
--DC_END_CONV_OUT <= end_sync_1;		
						
end Behavioral;

