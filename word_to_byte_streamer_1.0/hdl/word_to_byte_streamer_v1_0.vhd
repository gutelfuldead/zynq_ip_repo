----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 07/17/2017
-- Design Name: 
-- Module Name: word_to_byte_streamer_v1_0
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: Converts Words received from an upstream AXI-Stream Module 
--   (size == C_S_AXIS_TDATA_WIDTH) to a series of bytes and transmits them
--   to a downstream module. 
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

library work;
use work.generic_pkg.all;

entity word_to_byte_streamer_v1_0 is
    generic (
    C_M_AXIS_TDATA_WIDTH  : integer := 8;
    C_S_AXIS_TDATA_WIDTH  : integer := 32;
    ENDIAN                : string := "BIG" -- "LITTLE"
    );
    port (
    S_AXIS_ACLK : in std_logic;
    S_AXIS_ARESETN    : in std_logic;
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TSTRB    : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TLAST    : in std_logic;
    S_AXIS_TVALID    : in std_logic;
    
    M_AXIS_ACLK : in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TSTRB  : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST  : out std_logic;
    M_AXIS_TREADY : in std_logic
    );
end word_to_byte_streamer_v1_0;

architecture behav_32b_to_4x_8b of word_to_byte_streamer_v1_0 is

    -- axi slave signals
    signal s_user_rdy    : std_logic := '0';
    signal s_user_dvalid : std_logic := '0';
    signal s_user_data   : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    signal s_axis_rdy    : std_logic := '0';

    -- axi master signals
    signal m_user_data   : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    signal m_user_dvalid : std_logic := '0';
    signal m_user_txdone : std_logic := '0';
    signal m_axis_rdy    : std_logic := '0';

    -- internal buffers
    signal current_word : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0'); 
    signal new_word     : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    signal word_accessed  : std_logic := '0'; -- 1 when the master interface copies it to it's buffer
    signal new_word_ready : std_logic := '0'; -- 1 when a new word is available for the master interface

    constant NUM_BYTES : integer := 4;
    type byte_array_type is array (0 to NUM_BYTES-1) of std_logic_vector(7 downto 0);
    signal byte_array : byte_array_type;

    signal reset : std_logic := '0';
    signal clk   : std_logic;

begin

    reset <= M_AXIS_ARESETN;
    clk   <= M_AXIS_ACLK;

    axi_master_stream_inst : axi_master_stream
    generic map (C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH)
    port map (
        user_din       => m_user_data,
        user_dvalid    => m_user_dvalid,
        user_txdone    => m_user_txdone,
        axis_rdy       => m_axis_rdy,
        M_AXIS_ACLK    => M_AXIS_ACLK,
        M_AXIS_ARESETN => M_AXIS_ARESETN,
        M_AXIS_TVALID  => M_AXIS_TVALID,
        M_AXIS_TDATA   => M_AXIS_TDATA,
        M_AXIS_TSTRB   => M_AXIS_TSTRB,
        M_AXIS_TLAST   => M_AXIS_TLAST,
        M_AXIS_TREADY  => M_AXIS_TREADY
        );

    axi_slave_stream_inst : axi_slave_stream
    generic map (C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH)
    port map (
        user_rdy       => s_user_rdy,
        user_dvalid    => s_user_dvalid,
        user_data      => s_user_data,
        axis_rdy       => s_axis_rdy,
        S_AXIS_ACLK    => S_AXIS_ACLK,
        S_AXIS_ARESETN => S_AXIS_ARESETN,
        S_AXIS_TREADY  => S_AXIS_TREADY,
        S_AXIS_TDATA   => S_AXIS_TDATA,
        S_AXIS_TSTRB   => S_AXIS_TSTRB,
        S_AXIS_TLAST   => S_AXIS_TLAST,
        S_AXIS_TVALID  => S_AXIS_TVALID
        );

    ----------------------------------------------------------------------
    -- Axi-Stream Slave Controller
    -- Takes in a n-byte word and transfers it to the master state machine
    -- Captures the next n-byte word always ready to feed the master state
    -- Machine the next word
    ----------------------------------------------------------------------
    slave_proc : process(clk, reset)
        type fsm_states_slv  is (ST_IDLE, ST_ACTIVE, ST_WAIT);
        variable fsm : fsm_states_slv := ST_IDLE;
    begin
    if(reset = '0') then
        fsm            := ST_IDLE;
        s_user_rdy     <= '0';
        new_word_ready <= '0';
    elsif(rising_edge(clk)) then
        case(fsm) is
        when ST_IDLE =>
            if(s_axis_rdy = '1') then
                s_user_rdy <= '1';
                fsm        := ST_ACTIVE;
            end if;

        when ST_ACTIVE =>
            s_user_rdy <= '0';
            if(s_user_dvalid = '1') then
                new_word       <= s_user_data;
                new_word_ready <= '1';
                fsm            := ST_WAIT;
            end if;

        when ST_WAIT =>
            if(word_accessed = '1') then
                fsm            := ST_IDLE;
                new_word_ready <= '0';
            end if;

        when others =>
            fsm := ST_IDLE;

        end case;
    end if;
    end process slave_proc;

    ----------------------------------------------------------------
    -- Axi-Stream Master Controller
    -- Receives n-byte word from slave controller and parses it up
    -- into an array of bytes. Sends the bytes in order based on 
    -- generic endian selected ("BIG" or "LITTLE"). 
    ----------------------------------------------------------------
    master_proc : process(clk, reset)
        type fsm_states_mstr is (ST_IDLE, ST_BIT_MANIP, ST_ACTIVE, ST_NEW_BYTE);
        variable fsm : fsm_states_mstr := ST_IDLE;
        variable byte_index : integer range 0 to NUM_BYTES-1 := 0;
    begin
    if(reset = '0') then
        byte_index    := 0;
        m_user_data   <= (others => '0');
        m_user_dvalid <= '0';
        word_accessed <= '0';
        fsm := ST_IDLE;
    elsif(rising_edge(clk)) then
        case(fsm) is

        when ST_IDLE =>
            if(new_word_ready = '1') then
                current_word  <= new_word;
                word_accessed <= '1';
                fsm := ST_BIT_MANIP;
            end if;

        when ST_BIT_MANIP =>
            word_accessed <= '0';
            if(ENDIAN = "BIG") then
                byte_array(3) <= current_word(7  downto  0);
                byte_array(2) <= current_word(15 downto  8);
                byte_array(1) <= current_word(23 downto 16);
                byte_array(0) <= current_word(31 downto 24);
            else
                byte_array(3) <= current_word(31 downto 24);
                byte_array(2) <= current_word(23 downto 16);
                byte_array(1) <= current_word(15 downto  8);
                byte_array(0) <= current_word(7  downto  0);
            end if;
            fsm := ST_ACTIVE;

        when ST_ACTIVE =>
            if(m_axis_rdy = '1') then
                m_user_dvalid <= '1';
                m_user_data   <= byte_array(byte_index);
                fsm           := ST_NEW_BYTE;
            end if;

        when ST_NEW_BYTE =>
            m_user_dvalid <= '0';
            if(byte_index = NUM_BYTES-1) then
                byte_index := 0;
                fsm        := ST_IDLE;
            else
                byte_index := byte_index + 1;
                fsm        := ST_ACTIVE;
            end if;

        when others =>
            fsm := ST_IDLE;

        end case;
    end if;
    end process master_proc;

end behav_32b_to_4x_8b;
