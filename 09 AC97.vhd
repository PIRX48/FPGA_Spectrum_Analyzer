Code based on Viridiana Rubi Calzada Navarrete and Jose Juan Garcia Hernandez AC97 code

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity AC97 is
    Port ( 
        CLK             : in  std_logic;
        RESET           : in  std_logic;
        AUDIO_SDI       : in  std_logic;                           -- ADC audio input
        AUDIO_BIT_CLK   : in  std_logic;                           -- 12 MHz audio bit clock from codec
		  
        AUDIO_RESET     : out std_logic;                           -- Internal codec reset signal
        AUDIO_SDO       : out std_logic;                           -- DAC serial audio output
        AUDIO_SYNC      : out std_logic;                            -- Frame sync (SYNC) signal
		  
		  ADC_DATA_VALID_OUT  : out std_logic;
		  ADC_DATA_OUT    : out std_logic_vector(15 downto 0)
		  );
end AC97;

architecture Behavioral of AC97 is

--signal clk_reg   : std_logic := '0';
signal cnt_1 : unsigned(15 downto 0) := (others => '0');
signal cnt_2 : unsigned(9 downto 0) := (others => '0');
signal data  : std_logic_vector(15 downto 0) := (others => '0');

-- Internal audio sample registers (18‑bit left and right channels)
signal input_left        : std_logic_vector(17 downto 0);
signal input_right       : std_logic_vector(17 downto 0);
signal output_left       : std_logic_vector(17 downto 0);
signal output_right      : std_logic_vector(17 downto 0);

-- Internal data‑ready flag
signal data_ready_int    : std_logic := '0';

-- Counters for frame and bit timing
signal bit_count         : integer range 0 to 255;     -- Counts each bit in the AC97 frame (256 bits)
signal frame_count       : integer range 0 to 15;      -- Counts frames to schedule configuration tasks
signal reset_counter     : integer range 0 to 1027;    -- Used to generate periodic codec reset pulses 1027 1233

-- Control word fields for AC97 configuration registers
signal control_word      : std_logic_vector(23 downto 0);
signal control_data      : std_logic_vector(19 downto 0);
signal control_address   : std_logic_vector(19 downto 0);

signal valid_start_d     : std_logic := '0';
signal valid_start_rise  : std_logic := '0';

signal start_sync_0      : std_logic := '0';
signal start_sync_1      : std_logic := '0';

begin
-- Extract address and data fields from control word
control_address <= control_word(23 downto 16) & x"000";   -- Register address
control_data    <= control_word(15 downto 0) & x"0";      -- Register data

--ADC_CLK_OUT    <= AUDIO_BIT_CLK;

--------------------------------------------------------------------
-- DATA PASSTROUGHT
--------------------------------------------------------------------	 
process(data_ready_int)
begin
    if rising_edge(data_ready_int) then
					 output_left  <= input_left;
					 output_right <= input_right;
					 
					 data <= '0' & input_left(17) & input_left(13 downto 0);
    end if;
end process;

process(CLK)
begin
    if rising_edge(CLK) then
        start_sync_0 <= data_ready_int;
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

ADC_DATA_VALID_OUT <= valid_start_rise;
ADC_DATA_OUT <= data;

--ADC_DATA_OUT <= std_logic_vector(cnt_1);
--ADC_DATA_IDX_OUT <= std_logic_vector(cnt_2);
--ADC_END <= '1' when (cnt_2 = 1023) else '0';

--ADC_DATA_IDX_OUT <= std_logic_vector(cnt(9 downto 0));
--------------------------------------------------------------------
-- RESET GENERATION PROCESS
-- AC97 requires a reset after initialization.
--------------------------------------------------------------------
process(CLK)
begin
    if rising_edge(CLK) then
        if reset = '0' then                     -- Active‑low reset
            AUDIO_RESET <= '0';
            reset_counter <= 0;

        elsif reset_counter = 1027 then         -- End of reset interval 1027-100MHz 1233-120MHz
            AUDIO_RESET <= '1';                 -- Release codec reset

        else
            reset_counter <= reset_counter + 1; -- Continue counting
        end if;
    end if;
end process;

--------------------------------------------------------------------
-- FRAME GENERATION AND DAC OUTPUT PROCESS
-- Drives the AC97 serial output (SDO) and SYNC signals.
-- Implements the AC97 frame structure:
--   Slot 0: TAG
--   Slot 1: Register address
--   Slot 2: Register data
--   Slot 3: PCM left sample
--   Slot 4: PCM right sample
-- Remaining slots unused → output zeros.
--------------------------------------------------------------------
process(AUDIO_BIT_CLK)
begin
    if rising_edge(AUDIO_BIT_CLK) then

        -- Start of new frame
        if bit_count = 255 then
            AUDIO_SYNC <= '1';
            bit_count <= 0;
        end if;

        -- Frame counter cycles through configuration tasks
        if frame_count = 15 then
            frame_count <= 0;
        end if;

        -- SYNC is only active during Slot 0 (first 16 bits)
        if bit_count = 15 then
            AUDIO_SYNC <= '0';
        end if;

        ----------------------------------------------------------------
        -- SLOT 0: TAG (first 16 bits)
        -- Indicates which slots contain valid data.
        ----------------------------------------------------------------
        if bit_count <= 15 then
            case bit_count is
                when 0 => AUDIO_SDO <= '1';  -- Frame valid
                when 1 => AUDIO_SDO <= '1';  -- Slot 1 valid
                when 2 => AUDIO_SDO <= '1';  -- Slot 2 valid
                when 3 => AUDIO_SDO <= '1';  -- Left PCM valid
                when 4 => AUDIO_SDO <= '1';  -- Right PCM valid
                when others => AUDIO_SDO <= '0';
            end case;

        ----------------------------------------------------------------
        -- SLOT 1: CONTROL REGISTER ADDRESS (20 bits)
        ----------------------------------------------------------------
        elsif bit_count <= 35 then
            AUDIO_SDO <= control_address(35 - bit_count);

        ----------------------------------------------------------------
        -- SLOT 2: CONTROL REGISTER DATA (20 bits)
        ----------------------------------------------------------------
        elsif bit_count <= 55 then
            AUDIO_SDO <= control_data(55 - bit_count);

        ----------------------------------------------------------------
        -- SLOT 3: PCM LEFT CHANNEL (18 bits)
        ----------------------------------------------------------------
        elsif bit_count <= 73 then
            AUDIO_SDO <= output_left(73 - bit_count);
            data_ready_int <= '0';

        -- Delay before right channel
        elsif bit_count <= 75 then
            data_ready_int <= '0';

        ----------------------------------------------------------------
        -- SLOT 4: PCM RIGHT CHANNEL (18 bits)
        ----------------------------------------------------------------
        elsif bit_count <= 93 then
            AUDIO_SDO <= output_right(93 - bit_count);
            data_ready_int <= '0';

        ----------------------------------------------------------------
        -- REMAINING SLOTS UNUSED → OUTPUT ZERO
        ----------------------------------------------------------------
        else
            AUDIO_SDO <= '0';
            data_ready_int <= '1';  -- Full frame processed
        end if;

        -- Increment frame counter at end of frame
        if bit_count = 255 then
            frame_count <= frame_count + 1;
        end if;

        -- Advance bit counter
        bit_count <= bit_count + 1;

    end if;
end process;

--------------------------------------------------------------------
-- ADC INPUT CAPTURE PROCESS
-- Reads incoming serial audio data (SDI) from the codec.
-- Must be sampled on the *falling* edge of BITCLK.
-- Slot 3 → left channel
-- Slot 4 → right channel
--------------------------------------------------------------------
process(AUDIO_BIT_CLK)
begin
    if falling_edge(AUDIO_BIT_CLK) then

        -- Capture left channel sample
        if bit_count >= 57 and bit_count <= 74 then
            input_left <= input_left(16 downto 0) & AUDIO_SDI;

        -- Capture right channel sample
        elsif bit_count >= 77 and bit_count <= 94 then
            input_right <= input_right(16 downto 0) & AUDIO_SDI;

        end if;

    end if;
end process;

--------------------------------------------------------------------
-- CONTROL WORD SCHEDULER
-- Assigns AC97 configuration commands depending on frame number.
-- This sequence initializes:
--   - Line out
--   - PCM output gain
--   - Input selection
--   - ADC gain
--   - Sample rate registers
--------------------------------------------------------------------
process(frame_count)
begin
    case frame_count is
        when 1 =>
            control_word <= x"800000";      -- Codec ready

        when 2 =>
            control_word <= x"800000";      -- Codec ready

        when 3 =>
            control_word <= x"020000";      -- Line out enabled (no attenuation)

        when 4 =>
            control_word <= x"180000";      -- PCM out gain +12 dB

        when 5 =>
            control_word <= x"1A0404";      -- Input selection: line in

        when 6 =>
            control_word <= x"1C0000";      -- ADC gain control (left + right)
                                             
        when 7 =>
            control_word <= x"2A0001";      -- Enable variable sample rate

        when 8 =>
            control_word <= x"2CBB80";      -- DAC sample rate

        when 9 =>
            control_word <= x"32BB80";      -- ADC sample rate

        when others =>
            control_word <= x"800000";      -- Default
    end case;
end process;

end Behavioral;
