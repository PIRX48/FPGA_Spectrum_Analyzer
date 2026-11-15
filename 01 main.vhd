----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:16:58 03/15/2026 
-- Design Name: 
-- Module Name:    main - Behavioral 
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

entity main is
    Port ( CLK_PIN   : in STD_LOGIC;
			  RESET_PIN : in STD_LOGIC;
			  START_SW  : in STD_LOGIC;
           TX_PIN    : out STD_LOGIC;
			  
			  LED_PIN   : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  AUDIO_SDI       : in  std_logic;
           AUDIO_BIT_CLK   : in  std_logic;
           AUDIO_RESET     : out std_logic;
           AUDIO_SDO       : out std_logic;
           AUDIO_SYNC      : out std_logic);
end main;

architecture Behavioral of main is

-Clock IP core created by Xilinx
--component clk_120
--    Port ( CLK_PIN : in     std_logic;
--           CLK_120 : out    std_logic;
--			  
--           RESET   : in     std_logic;
--           LOCKED  : out    std_logic);
--end component;

component uart_tx
    Port ( CLK      : in  STD_LOGIC;
           RESET    : in  STD_LOGIC;
			  
           UART_TX_START_IN : in  STD_LOGIC;
           UART_TX_DATA_IN  : in  STD_LOGIC_VECTOR (7 downto 0);
			  UART_TX_START_SW_IN : in STD_LOGIC;
			  
           UART_TX_OUT      : out  STD_LOGIC;
           UART_TX_BUSY_OUT : out  STD_LOGIC);
end component;

component fsm is
    Port ( CLK   : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
			  
			  FSM_START_IN   :in  STD_LOGIC;
           FSM_TX_BUSY_IN : in  STD_LOGIC;
			  FSM_DONE_OUT    :out STD_LOGIC;
			  
			  FSM_RAM_DATA_IN : in STD_LOGIC_VECTOR (31 downto 0);
			  FSM_RAM_ADR_OUT : out STD_LOGIC_VECTOR (9 downto 0);
			  
           FSM_TX_START_OUT : out  STD_LOGIC;
           FSM_TX_DATA_OUT  : out  STD_LOGIC_VECTOR (7 downto 0));
end component;

component ram_dual_port is
    Port ( CLK_IN  : in  STD_LOGIC;
	        CLK_OUT : in STD_LOGIC;
			  
			  RAM_WE_IN : in  STD_LOGIC;
           RAM_DATA_IN : in  STD_LOGIC_VECTOR (31 downto 0);
           RAM_ADR_IN : in  STD_LOGIC_VECTOR(9 downto 0);
			  
           RAM_DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0);
           RAM_ADR_OUT : in  STD_LOGIC_VECTOR(9 downto 0));
end component;

component data_collector is
    Port ( CLK   : in  STD_LOGIC;
           RESET : in  STD_LOGIC;
			  
           DC_DATA_VALID_IN : in  STD_LOGIC;
           DC_DATA_IN       : in  STD_LOGIC_VECTOR (31 downto 0);
--			  DC_DATA_IDX_IN   : in  STD_LOGIC_VECTOR (9 downto 0);
			  DC_DATA_END_IN   : in STD_LOGIC;
			  
			  DC_START_CONV_IN : in  STD_LOGIC;
           DC_END_CONV_OUT : out  STD_LOGIC;
			  
           DC_WE_OUT : out  STD_LOGIC;
           DC_ADR_OUT : out  STD_LOGIC_VECTOR(9 downto 0);
           DC_DATA_OUT : out  STD_LOGIC_VECTOR (31 downto 0));
end component;

component mag is
    Port ( CLK        : in  std_logic;
           RESET      : in  std_logic;
			  
			  MAG_DATA_END_IN : in  std_logic; 
           MAG_DATA_IN : in  std_logic_vector(31 downto 0);
--           MAG_IDX_IN  : in  std_logic_vector(9 downto 0);
           MAG_DATA_VALID_IN : in  std_logic;
			  
			  MAG_DATA_END_OUT : out  std_logic; 
           MAG_DATA_OUT : out std_logic_vector(31 downto 0);
--           MAG_IDX_OUT  : out std_logic_vector(9 downto 0);
           MAG_DATA_VALID_OUT : out std_logic);
end component;

component fft is
    Port ( CLK : in  STD_LOGIC;
			  RESET : in STD_LOGIC;
			  
			  LED : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  FFT_DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
			  FFT_DATA_VALID_IN : in STD_LOGIC;
			  
			  FFT_DATA_OUT : out STD_LOGIC_VECTOR (31 downto 0);
			  FFT_DATA_VALID_OUT : out STD_LOGIC;
			  FFT_DATA_LAST_OUT : out STD_LOGIC);
end component;

component AC97 is
    Port ( CLK             : in  std_logic;
           RESET           : in  std_logic;
           AUDIO_SDI       : in  std_logic;
           AUDIO_BIT_CLK   : in  std_logic;
		    
           AUDIO_RESET     : out std_logic;
           AUDIO_SDO       : out std_logic;
           AUDIO_SYNC      : out std_logic;
			  
			  ADC_DATA_VALID_OUT  : out std_logic;
			  ADC_DATA_OUT    : out std_logic_vector(15 downto 0)
			  );
end component;

--sygnay glowne sterowania
signal clk_120_s    : std_logic := '0';
--signal adc_clk_s    : std_logic := '0';

signal rst_s        : std_logic := '0';
--signal rst_pll_s    : std_logic := '0';
--signal locked_s     : std_logic := '0';

--fsm to uart
signal tx_start_s : std_logic := '0';
signal tx_data_s  : std_logic_vector(7 downto 0) := (others => '0');

--fsm to ram
signal ram_adr_out_s : std_logic_vector(9 downto 0) := (others => '0');

--fsm to data_collector
signal start_conv_s : std_logic := '0';

--uart to fsm
signal tx_busy_s : std_logic :='0';

--ram to fsm
signal ram_data_out_s : std_logic_vector(31 downto 0) := (others => '0');

--data collector to ram
signal we_s          : std_logic :='0'; 
signal ram_adr_in_s  : std_logic_vector(9 downto 0) := (others => '0');
signal ram_data_in_s : std_logic_vector(31 downto 0) := (others => '0');

--data collector to fsm
signal end_conv_s : std_logic := '0';

--mag to data collector
signal mag_data_valid_s : std_logic := '0';
--signal mag_data_idx_s   : std_logic_vector(9 downto 0) := (others => '0');
signal mag_data_s       : std_logic_vector(31 downto 0) := (others => '0');
signal mag_end_s        : std_logic := '0';

--fft to mag
signal fft_data_valid_s : std_logic := '0';
signal fft_data_s       : std_logic_vector(31 downto 0) := (others => '0');
signal fft_end_s        : std_logic := '0';

--adc to fft
signal adc_data_valid_s : std_logic := '0';
signal adc_data_s       : std_logic_vector(15 downto 0) := (others => '0');

begin

--rst_pll_s <= not RESET_PIN;
--rst_s <= locked_s or RESET_PIN;

rst_s <= RESET_PIN;
clk_120_s <= CLK_PIN;

--u1 : clk_120
--	  port map
--		(CLK_PIN => CLK_PIN,
--		 RESET   => rst_pll_s,		
--		
--		 CLK_120 => clk_120_s,
--		 LOCKED  => locked_s);
		 
u2 : uart_tx
	  port map
		(CLK   => clk_120_s,
		 RESET => rst_s,
		 
		 UART_TX_START_IN => tx_start_s,
		 UART_TX_DATA_IN  => tx_data_s,
		 UART_TX_START_SW_IN => START_SW,
		 
		 UART_TX_OUT      => TX_PIN,
		 UART_TX_BUSY_OUT => tx_busy_s);
		 
u3 : fsm
	  port map
		(CLK   => clk_120_s,
		 RESET => rst_s,
		 
		 FSM_RAM_DATA_IN => ram_data_out_s,
		 FSM_RAM_ADR_OUT => ram_adr_out_s,
		 
		 FSM_START_IN   => end_conv_s,
		 FSM_TX_BUSY_IN => tx_busy_s,
		 FSM_DONE_OUT   => start_conv_s,
		 
		 FSM_TX_START_OUT => tx_start_s,
		 FSM_TX_DATA_OUT  => tx_data_s);
		 
u4 : ram_dual_port
	  port map
		(CLK_IN   => clk_120_s,
		 CLK_OUT  => clk_120_s,

		 RAM_WE_IN   => we_s,
		 RAM_DATA_IN => ram_data_in_s,
		 RAM_ADR_IN  => ram_adr_in_s,
		 
		 RAM_DATA_OUT => ram_data_out_s,
		 RAM_ADR_OUT  => ram_adr_out_s);
		 
u5 : data_collector
port map
		(CLK   => clk_120_s,
		 RESET => rst_s,
		 
		 DC_DATA_VALID_IN => mag_data_valid_s,
		 DC_DATA_IN       => mag_data_s,
--		 DC_DATA_IDX_IN   => mag_data_idx_s,
		 DC_DATA_END_IN   => mag_end_s,
		 
		 DC_START_CONV_IN => start_conv_s,
		 DC_END_CONV_OUT   => end_conv_s,
		 
		 DC_WE_OUT   => we_s,
		 DC_ADR_OUT  => ram_adr_in_s,
		 DC_DATA_OUT => ram_data_in_s);
		 
u6 : mag
	  port map
		(CLK   => clk_120_s,
		 RESET => rst_s,
		 
		 MAG_DATA_IN       => fft_data_s,
--		 MAG_IDX_IN        => adc_data_idx_s,
		 MAG_DATA_VALID_IN => fft_data_valid_s,
		 MAG_DATA_END_IN   => fft_end_s,
		 
		 MAG_DATA_OUT       => mag_data_s,
--		 MAG_IDX_OUT        => mag_data_idx_s,
		 MAG_DATA_VALID_OUT => mag_data_valid_s,
		 MAG_DATA_END_OUT   => mag_end_s);
		 
u7 : fft
	  port map
		(CLK   => clk_120_s,
		 RESET => rst_s,
   	 LED   => LED_PIN,
		 
		 FFT_DATA_IN       => adc_data_s,
		 FFT_DATA_VALID_IN => adc_data_valid_s,
		 
		 FFT_DATA_OUT       => fft_data_s,
		 FFT_DATA_VALID_OUT => fft_data_valid_s,
		 FFT_DATA_LAST_OUT  => fft_end_s);
		 		 	
u8 : AC97		
    port map
	  (CLK             => clk_120_s,
      RESET           => rst_s,
      AUDIO_SDI       => AUDIO_SDI,
      AUDIO_BIT_CLK   => AUDIO_BIT_CLK,
		    
      AUDIO_RESET     => AUDIO_RESET,
      AUDIO_SDO       => AUDIO_SDO,
      AUDIO_SYNC      => AUDIO_SYNC,
		
		ADC_DATA_VALID_OUT  => adc_data_valid_s,
	   ADC_DATA_OUT        => adc_data_s
		);
		 
end Behavioral;