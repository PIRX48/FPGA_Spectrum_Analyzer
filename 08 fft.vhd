----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:53:32 06/03/2026 
-- Design Name: 
-- Module Name:    please - Behavioral 
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

entity fft is
    Port ( CLK : in  STD_LOGIC;
			  RESET : in STD_LOGIC;
			  
			  LED : out STD_LOGIC_VECTOR (7 downto 0);
			  
			  FFT_DATA_IN : in STD_LOGIC_VECTOR (15 downto 0);
			  FFT_DATA_VALID_IN : in STD_LOGIC;
			  
			  FFT_DATA_OUT : out STD_LOGIC_VECTOR (31 downto 0);
			  FFT_DATA_VALID_OUT : out STD_LOGIC;
			  FFT_DATA_LAST_OUT : out STD_LOGIC);
end fft;

architecture Behavioral of fft is

type rom_type is array (0 to 1023) of std_logic_vector(15 downto 0);

    constant HAMMING_ROM : rom_type := (
        x"0A3D", x"0A3E", x"0A3E", x"0A40", x"0A42", x"0A44", x"0A48", x"0A4B",
        x"0A50", x"0A54", x"0A5A", x"0A60", x"0A66", x"0A6D", x"0A75", x"0A7D",
        x"0A86", x"0A8F", x"0A99", x"0AA4", x"0AAF", x"0ABB", x"0AC7", x"0AD4",
        x"0AE1", x"0AEF", x"0AFD", x"0B0C", x"0B1C", x"0B2C", x"0B3D", x"0B4E",
        x"0B60", x"0B72", x"0B85", x"0B98", x"0BAC", x"0BC1", x"0BD6", x"0BEC",
        x"0C02", x"0C19", x"0C30", x"0C48", x"0C60", x"0C79", x"0C93", x"0CAD",
        x"0CC8", x"0CE3", x"0CFF", x"0D1B", x"0D38", x"0D55", x"0D73", x"0D91",
        x"0DB0", x"0DD0", x"0DF0", x"0E10", x"0E31", x"0E53", x"0E75", x"0E98",
        x"0EBB", x"0EDF", x"0F03", x"0F28", x"0F4D", x"0F73", x"0F99", x"0FC0",
        x"0FE7", x"100F", x"1038", x"1060", x"108A", x"10B4", x"10DE", x"1109",
        x"1135", x"1160", x"118D", x"11BA", x"11E7", x"1215", x"1244", x"1272",
        x"12A2", x"12D2", x"1302", x"1333", x"1364", x"1396", x"13C8", x"13FB",
        x"142E", x"1462", x"1496", x"14CB", x"1500", x"1536", x"156C", x"15A2",
        x"15D9", x"1611", x"1648", x"1681", x"16BA", x"16F3", x"172C", x"1767",
        x"17A1", x"17DC", x"1818", x"1853", x"1890", x"18CC", x"190A", x"1947",
        x"1985", x"19C4", x"1A03", x"1A42", x"1A81", x"1AC2", x"1B02", x"1B43",
        x"1B84", x"1BC6", x"1C08", x"1C4B", x"1C8E", x"1CD1", x"1D14", x"1D59",
        x"1D9D", x"1DE2", x"1E27", x"1E6D", x"1EB3", x"1EF9", x"1F40", x"1F87",
        x"1FCE", x"2016", x"205E", x"20A7", x"20EF", x"2139", x"2182", x"21CC",
        x"2216", x"2261", x"22AC", x"22F7", x"2343", x"238F", x"23DB", x"2427",
        x"2474", x"24C1", x"250F", x"255D", x"25AB", x"25F9", x"2648", x"2697",
        x"26E6", x"2736", x"2786", x"27D6", x"2826", x"2877", x"28C8", x"2919",
        x"296B", x"29BD", x"2A0F", x"2A61", x"2AB4", x"2B07", x"2B5A", x"2BAD",
        x"2C01", x"2C55", x"2CA9", x"2CFD", x"2D52", x"2DA6", x"2DFB", x"2E51",
        x"2EA6", x"2EFC", x"2F52", x"2FA8", x"2FFE", x"3055", x"30AB", x"3102",
        x"3159", x"31B1", x"3208", x"3260", x"32B8", x"3310", x"3368", x"33C0",
        x"3419", x"3471", x"34CA", x"3523", x"357D", x"35D6", x"362F", x"3689",
        x"36E3", x"373D", x"3797", x"37F1", x"384B", x"38A6", x"3900", x"395B",
        x"39B5", x"3A10", x"3A6B", x"3AC6", x"3B22", x"3B7D", x"3BD8", x"3C34",
        x"3C8F", x"3CEB", x"3D47", x"3DA2", x"3DFE", x"3E5A", x"3EB6", x"3F12",
        x"3F6E", x"3FCB", x"4027", x"4083", x"40DF", x"413C", x"4198", x"41F5",
        x"4251", x"42AD", x"430A", x"4367", x"43C3", x"4420", x"447C", x"44D9",
        x"4535", x"4592", x"45EE", x"464B", x"46A8", x"4704", x"4761", x"47BD",
        x"481A", x"4876", x"48D2", x"492F", x"498B", x"49E7", x"4A44", x"4AA0",
        x"4AFC", x"4B58", x"4BB4", x"4C10", x"4C6C", x"4CC8", x"4D24", x"4D7F",
        x"4DDB", x"4E36", x"4E92", x"4EED", x"4F48", x"4FA3", x"4FFF", x"5059",
        x"50B4", x"510F", x"516A", x"51C4", x"521E", x"5279", x"52D3", x"532D",
        x"5387", x"53E0", x"543A", x"5493", x"54EC", x"5546", x"559E", x"55F7",
        x"5650", x"56A8", x"5701", x"5759", x"57B1", x"5808", x"5860", x"58B7",
        x"590F", x"5966", x"59BC", x"5A13", x"5A69", x"5AC0", x"5B16", x"5B6B",
        x"5BC1", x"5C16", x"5C6B", x"5CC0", x"5D15", x"5D6A", x"5DBE", x"5E12",
        x"5E65", x"5EB9", x"5F0C", x"5F5F", x"5FB2", x"6004", x"6057", x"60A9",
        x"60FA", x"614C", x"619D", x"61EE", x"623E", x"628F", x"62DF", x"632E",
        x"637E", x"63CD", x"641C", x"646A", x"64B9", x"6507", x"6554", x"65A2",
        x"65EF", x"663B", x"6688", x"66D4", x"6720", x"676B", x"67B6", x"6801",
        x"684B", x"6895", x"68DF", x"6928", x"6971", x"69BA", x"6A02", x"6A4A",
        x"6A92", x"6AD9", x"6B20", x"6B67", x"6BAD", x"6BF3", x"6C38", x"6C7D",
        x"6CC2", x"6D06", x"6D4A", x"6D8D", x"6DD0", x"6E13", x"6E55", x"6E97",
        x"6ED9", x"6F1A", x"6F5B", x"6F9B", x"6FDB", x"701A", x"7059", x"7098",
        x"70D6", x"7114", x"7151", x"718E", x"71CB", x"7207", x"7243", x"727E",
        x"72B9", x"72F3", x"732D", x"7366", x"739F", x"73D8", x"7410", x"7448",
        x"747F", x"74B5", x"74EC", x"7522", x"7557", x"758C", x"75C0", x"75F4",
        x"7628", x"765B", x"768D", x"76BF", x"76F1", x"7722", x"7752", x"7783",
        x"77B2", x"77E1", x"7810", x"783E", x"786C", x"7899", x"78C6", x"78F2",
        x"791E", x"7949", x"7973", x"799E", x"79C7", x"79F0", x"7A19", x"7A41",
        x"7A69", x"7A90", x"7AB6", x"7ADD", x"7B02", x"7B27", x"7B4C", x"7B70",
        x"7B93", x"7BB6", x"7BD8", x"7BFA", x"7C1C", x"7C3C", x"7C5D", x"7C7D",
        x"7C9C", x"7CBA", x"7CD9", x"7CF6", x"7D13", x"7D30", x"7D4C", x"7D67",
        x"7D82", x"7D9C", x"7DB6", x"7DD0", x"7DE8", x"7E00", x"7E18", x"7E2F",
        x"7E46", x"7E5C", x"7E71", x"7E86", x"7E9A", x"7EAE", x"7EC1", x"7ED4",
        x"7EE6", x"7EF7", x"7F08", x"7F19", x"7F29", x"7F38", x"7F47", x"7F55",
        x"7F62", x"7F6F", x"7F7C", x"7F88", x"7F93", x"7F9E", x"7FA8", x"7FB2",
        x"7FBB", x"7FC3", x"7FCB", x"7FD3", x"7FD9", x"7FE0", x"7FE5", x"7FEA",
        x"7FEF", x"7FF3", x"7FF6", x"7FF9", x"7FFC", x"7FFD", x"7FFE", x"7FFF",
        x"7FFF", x"7FFE", x"7FFD", x"7FFC", x"7FF9", x"7FF6", x"7FF3", x"7FEF",
        x"7FEA", x"7FE5", x"7FE0", x"7FD9", x"7FD3", x"7FCB", x"7FC3", x"7FBB",
        x"7FB2", x"7FA8", x"7F9E", x"7F93", x"7F88", x"7F7C", x"7F6F", x"7F62",
        x"7F55", x"7F47", x"7F38", x"7F29", x"7F19", x"7F08", x"7EF7", x"7EE6",
        x"7ED4", x"7EC1", x"7EAE", x"7E9A", x"7E86", x"7E71", x"7E5C", x"7E46",
        x"7E2F", x"7E18", x"7E00", x"7DE8", x"7DD0", x"7DB6", x"7D9C", x"7D82",
        x"7D67", x"7D4C", x"7D30", x"7D13", x"7CF6", x"7CD9", x"7CBA", x"7C9C",
        x"7C7D", x"7C5D", x"7C3C", x"7C1C", x"7BFA", x"7BD8", x"7BB6", x"7B93",
        x"7B70", x"7B4C", x"7B27", x"7B02", x"7ADD", x"7AB6", x"7A90", x"7A69",
        x"7A41", x"7A19", x"79F0", x"79C7", x"799E", x"7973", x"7949", x"791E",
        x"78F2", x"78C6", x"7899", x"786C", x"783E", x"7810", x"77E1", x"77B2",
        x"7783", x"7752", x"7722", x"76F1", x"76BF", x"768D", x"765B", x"7628",
        x"75F4", x"75C0", x"758C", x"7557", x"7522", x"74EC", x"74B5", x"747F",
        x"7448", x"7410", x"73D8", x"739F", x"7366", x"732D", x"72F3", x"72B9",
        x"727E", x"7243", x"7207", x"71CB", x"718E", x"7151", x"7114", x"70D6",
        x"7098", x"7059", x"701A", x"6FDB", x"6F9B", x"6F5B", x"6F1A", x"6ED9",
        x"6E97", x"6E55", x"6E13", x"6DD0", x"6D8D", x"6D4A", x"6D06", x"6CC2",
        x"6C7D", x"6C38", x"6BF3", x"6BAD", x"6B67", x"6B20", x"6AD9", x"6A92",
        x"6A4A", x"6A02", x"69BA", x"6971", x"6928", x"68DF", x"6895", x"684B",
        x"6801", x"67B6", x"676B", x"6720", x"66D4", x"6688", x"663B", x"65EF",
        x"65A2", x"6554", x"6507", x"64B9", x"646A", x"641C", x"63CD", x"637E",
        x"632E", x"62DF", x"628F", x"623E", x"61EE", x"619D", x"614C", x"60FA",
        x"60A9", x"6057", x"6004", x"5FB2", x"5F5F", x"5F0C", x"5EB9", x"5E65",
        x"5E12", x"5DBE", x"5D6A", x"5D15", x"5CC0", x"5C6B", x"5C16", x"5BC1",
        x"5B6B", x"5B16", x"5AC0", x"5A69", x"5A13", x"59BC", x"5966", x"590F",
        x"58B7", x"5860", x"5808", x"57B1", x"5759", x"5701", x"56A8", x"5650",
        x"55F7", x"559E", x"5546", x"54EC", x"5493", x"543A", x"53E0", x"5387",
        x"532D", x"52D3", x"5279", x"521E", x"51C4", x"516A", x"510F", x"50B4",
        x"5059", x"4FFF", x"4FA3", x"4F48", x"4EED", x"4E92", x"4E36", x"4DDB",
        x"4D7F", x"4D24", x"4CC8", x"4C6C", x"4C10", x"4BB4", x"4B58", x"4AFC",
        x"4AA0", x"4A44", x"49E7", x"498B", x"492F", x"48D2", x"4876", x"481A",
        x"47BD", x"4761", x"4704", x"46A8", x"464B", x"45EE", x"4592", x"4535",
        x"44D9", x"447C", x"4420", x"43C3", x"4367", x"430A", x"42AD", x"4251",
        x"41F5", x"4198", x"413C", x"40DF", x"4083", x"4027", x"3FCB", x"3F6E",
        x"3F12", x"3EB6", x"3E5A", x"3DFE", x"3DA2", x"3D47", x"3CEB", x"3C8F",
        x"3C34", x"3BD8", x"3B7D", x"3B22", x"3AC6", x"3A6B", x"3A10", x"39B5",
        x"395B", x"3900", x"38A6", x"384B", x"37F1", x"3797", x"373D", x"36E3",
        x"3689", x"362F", x"35D6", x"357D", x"3523", x"34CA", x"3471", x"3419",
        x"33C0", x"3368", x"3310", x"32B8", x"3260", x"3208", x"31B1", x"3159",
        x"3102", x"30AB", x"3055", x"2FFE", x"2FA8", x"2F52", x"2EFC", x"2EA6",
        x"2E51", x"2DFB", x"2DA6", x"2D52", x"2CFD", x"2CA9", x"2C55", x"2C01",
        x"2BAD", x"2B5A", x"2B07", x"2AB4", x"2A61", x"2A0F", x"29BD", x"296B",
        x"2919", x"28C8", x"2877", x"2826", x"27D6", x"2786", x"2736", x"26E6",
        x"2697", x"2648", x"25F9", x"25AB", x"255D", x"250F", x"24C1", x"2474",
        x"2427", x"23DB", x"238F", x"2343", x"22F7", x"22AC", x"2261", x"2216",
        x"21CC", x"2182", x"2139", x"20EF", x"20A7", x"205E", x"2016", x"1FCE",
        x"1F87", x"1F40", x"1EF9", x"1EB3", x"1E6D", x"1E27", x"1DE2", x"1D9D",
        x"1D59", x"1D14", x"1CD1", x"1C8E", x"1C4B", x"1C08", x"1BC6", x"1B84",
        x"1B43", x"1B02", x"1AC2", x"1A81", x"1A42", x"1A03", x"19C4", x"1985",
        x"1947", x"190A", x"18CC", x"1890", x"1853", x"1818", x"17DC", x"17A1",
        x"1767", x"172C", x"16F3", x"16BA", x"1681", x"1648", x"1611", x"15D9",
        x"15A2", x"156C", x"1536", x"1500", x"14CB", x"1496", x"1462", x"142E",
        x"13FB", x"13C8", x"1396", x"1364", x"1333", x"1302", x"12D2", x"12A2",
        x"1272", x"1244", x"1215", x"11E7", x"11BA", x"118D", x"1160", x"1135",
        x"1109", x"10DE", x"10B4", x"108A", x"1060", x"1038", x"100F", x"0FE7",
        x"0FC0", x"0F99", x"0F73", x"0F4D", x"0F28", x"0F03", x"0EDF", x"0EBB",
        x"0E98", x"0E75", x"0E53", x"0E31", x"0E10", x"0DF0", x"0DD0", x"0DB0",
        x"0D91", x"0D73", x"0D55", x"0D38", x"0D1B", x"0CFF", x"0CE3", x"0CC8",
        x"0CAD", x"0C93", x"0C79", x"0C60", x"0C48", x"0C30", x"0C19", x"0C02",
        x"0BEC", x"0BD6", x"0BC1", x"0BAC", x"0B98", x"0B85", x"0B72", x"0B60",
        x"0B4E", x"0B3D", x"0B2C", x"0B1C", x"0B0C", x"0AFD", x"0AEF", x"0AE1",
        x"0AD4", x"0AC7", x"0ABB", x"0AAF", x"0AA4", x"0A99", x"0A8F", x"0A86",
        x"0A7D", x"0A75", x"0A6D", x"0A66", x"0A60", x"0A5A", x"0A54", x"0A50",
        x"0A4B", x"0A48", x"0A44", x"0A42", x"0A40", x"0A3E", x"0A3E", x"0A3D"
    );

--FFT IP core created by Xilinx
COMPONENT fft_core_scaled
  PORT (
    aclk : IN STD_LOGIC;
    aresetn : IN STD_LOGIC;
    s_axis_config_tdata : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    s_axis_config_tvalid : IN STD_LOGIC;
    s_axis_config_tready : OUT STD_LOGIC;
    s_axis_data_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    s_axis_data_tvalid : IN STD_LOGIC;
    s_axis_data_tready : OUT STD_LOGIC;
    s_axis_data_tlast : IN STD_LOGIC;
    m_axis_data_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axis_data_tvalid : OUT STD_LOGIC;
    m_axis_data_tready : IN STD_LOGIC;
    m_axis_data_tlast : OUT STD_LOGIC;
    event_frame_started : OUT STD_LOGIC;
    event_tlast_unexpected : OUT STD_LOGIC;
    event_tlast_missing : OUT STD_LOGIC;
    event_status_channel_halt : OUT STD_LOGIC;
    event_data_in_channel_halt : OUT STD_LOGIC;
    event_data_out_channel_halt : OUT STD_LOGIC
  );
END COMPONENT;

-- Sygnały konfiguracji scaled
signal cfg_data_scaled      : std_logic_vector(15 downto 0) := "0000101010101001";
signal cfg_valid_scaled     : std_logic := '0';
signal cfg_ready_scaled     : std_logic;

signal m_axis_tdata_32 : STD_LOGIC_VECTOR(31 downto 0);
signal m_axis_tdata  : STD_LOGIC_VECTOR(15 downto 0);
signal m_axis_tvalid : STD_LOGIC;
signal m_axis_tready : STD_LOGIC;
signal m_axis_tlast  : STD_LOGIC;

-- Sygnały interfejsu AXI-Stream do FIFO
signal s_axis_tvalid : std_logic := '0';
signal s_axis_tdata  : std_logic_vector(15 downto 0) := (others => '0');

signal fft_data_valid_out_s : std_logic := '0';

-- FIFO
type ram_type is array (0 to 1023) of STD_LOGIC_VECTOR(15 downto 0);
signal bram : ram_type := (others => (others => '0'));

-- Maszyna stanów
type state_type is (ST_COLLECT, ST_TRANSMIT);
signal state : state_type := ST_COLLECT;

-- Liczniki adresów
signal wr_ptr : unsigned(9 downto 0) := (others => '0');
signal rd_ptr : unsigned(9 downto 0) := (others => '0');

signal bram_data_reg : std_logic_vector(s_axis_tdata'range) := (others => '0');
signal ham_data_reg  : std_logic_vector(15 downto 0) := (others => '0');

signal valid_pipeline : std_logic_vector(1 downto 0) := (others => '0');
signal last_pipeline  : std_logic_vector(1 downto 0) := (others => '0');

signal internal_tvalid : std_logic;
signal internal_tlast  : std_logic;

begin

s_axis_tvalid <= FFT_DATA_VALID_IN;
s_axis_tdata  <= FFT_DATA_IN;


	 -- Pamięć BRAM
    process(CLK)
    begin
        if rising_edge(CLK) then
        
            if state = ST_COLLECT and s_axis_tvalid = '1' then
					 bram(to_integer(wr_ptr)) <= s_axis_tdata;
            end if;
            
            
            bram_data_reg <= bram(to_integer(rd_ptr));
				
				
				ham_data_reg <= HAMMING_ROM(to_integer(rd_ptr));
        end if;
    end process;
	 
	 
    process(CLK)
        
        variable prod : signed(bram_data_reg'length + ham_data_reg'length - 1 downto 0);
    begin
        if rising_edge(CLK) then
            if RESET = '0' then
                m_axis_tdata <= (others => '0');
            elsif m_axis_tready = '1' or state = ST_COLLECT then 
                
                prod := signed(bram_data_reg) * signed(ham_data_reg);
                
                
                m_axis_tdata <= std_logic_vector(prod(prod'high downto prod'high - m_axis_tdata'length + 1));
            end if;
        end if;
    end process;
	 
	 
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '0' then
                valid_pipeline <= (others => '0');
                last_pipeline  <= (others => '0');
            elsif m_axis_tready = '1' or state = ST_COLLECT then
                -- Przesuwamy sygnały o 2 cykle (indeks 0 to krok po RAM, indeks 1 to krok po mnożeniu)
                valid_pipeline <= valid_pipeline(0) & internal_tvalid;
                last_pipeline  <= last_pipeline(0)  & internal_tlast;
            end if;
        end if;
    end process;

    
    m_axis_tvalid <= valid_pipeline(1);
    m_axis_tlast  <= last_pipeline(1);
    
    process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '0' then
                state         <= ST_COLLECT;
                wr_ptr        <= (others => '0');
                rd_ptr        <= (others => '0');
                internal_tvalid <= '0';
                internal_tlast  <= '0';
            else
                case state is
                
                    
                    when ST_COLLECT =>
                        internal_tvalid <= '0';
                        internal_tlast  <= '0';
                        rd_ptr        <= (others => '0');
								LED(7)        <= '0';
                        if s_axis_tvalid = '1' then
                            if wr_ptr = 1023 then
                                wr_ptr        <= (others => '0');
                                internal_tvalid <= '1';
                                state         <= ST_TRANSMIT;
                            else
                                wr_ptr <= wr_ptr + 1;
                            end if;
                        end if;

                    
                    when ST_TRANSMIT =>
								LED(7) <= '1';
                        
                        if m_axis_tready = '1' then
                            
                            
                            if rd_ptr = 1022 then
                                internal_tlast <= '1';
                            end if;

                            if rd_ptr = 1023 then
                                internal_tvalid <= '0';
                                internal_tlast  <= '0';
                                rd_ptr        <= (others => '0');
                                state         <= ST_COLLECT;
                            else
                                rd_ptr <= rd_ptr + 1;
                            end if;
                        end if;

                    when others =>
                        state <= ST_COLLECT;
                end case;
            end if;
        end if;
    end process;
	 
	 
	 process(CLK)
    begin
        if rising_edge(CLK) then
            if RESET = '0' then
                
                cfg_valid_scaled <= '1';
            else
                
                if cfg_valid_scaled = '1' and cfg_ready_scaled = '1' then
                    
                    cfg_valid_scaled <= '0';
                end if;
            end if;
        end if;
    end process;
	 

m_axis_tdata_32 <= x"0000" & m_axis_tdata;
FFT_DATA_VALID_OUT <= fft_data_valid_out_s;
LED(6) <= fft_data_valid_out_s;

	 
--fft scaled
f2 : fft_core_scaled
  PORT MAP (
    aclk => CLK,
    aresetn => RESET,
	 
    s_axis_config_tdata => cfg_data_scaled,
    s_axis_config_tvalid => cfg_valid_scaled,
    s_axis_config_tready => cfg_ready_scaled,
	 
    s_axis_data_tdata => m_axis_tdata_32,
    s_axis_data_tvalid => m_axis_tvalid,
    s_axis_data_tready => m_axis_tready,
    s_axis_data_tlast => m_axis_tlast,
	 
    m_axis_data_tdata => FFT_DATA_OUT,
    m_axis_data_tvalid => fft_data_valid_out_s,
    m_axis_data_tready => '1',
    m_axis_data_tlast => FFT_DATA_LAST_OUT,
	 
    event_frame_started => LED(0),
    event_tlast_unexpected => LED(1),
    event_tlast_missing => LED(2),
    event_status_channel_halt => LED(3),
    event_data_in_channel_halt => LED(4),
    event_data_out_channel_halt => LED(5)
  );


end Behavioral;
