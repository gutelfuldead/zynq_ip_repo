----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 07/17/2017
-- Design Name: 
-- Module Name: convolution_to_viterbi_converter_stream_v1_0
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: Interface to test connections directly from the Xilinx Convolutional
--   Encoder IP Core to the Xilinx Viterbi Decoder IP Core. Convolution core outputs
--   on a bus width of 8 with only the bottom two LSBs being significant. "bit_1" 
--   takes position '1' and "bit_0" takes on position '0' with type uint. Convolution
--   core must have the following modes set to use this core : Output Rate = 2 and 
--   TREADY enabled.
--
--   The Viterbi Core takes in two bits of type uint on a bus width of 16 bits. With "bit_1" 
--   occupying position '8' and "bit_0" occupying position '0'. Viterbi must have the
--   following modes set to use this core: "Standard", "Hard Coding", Output Rate 0 = '2', 
--   TREADY enabled.
--
--   This core makes that conversion so the two cores can communicate.
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

entity convolution_to_viterbi_converter_stream_v1_0 is
    generic (
    WORD_SIZE_OUT  : integer := 16;
    WORD_SIZE_IN  : integer := 8
    );
    port (
    NUM_IN  : out std_logic_vector(31 downto 0);
    NUM_OUT : out std_logic_vector(31 downto 0);
    
    AXIS_ACLK : in std_logic;
    AXIS_ARESETN    : in std_logic;
    
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(7 downto 0);
    S_AXIS_TVALID    : in std_logic;
    
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(15 downto 0);
    M_AXIS_TREADY : in std_logic
    );
end convolution_to_viterbi_converter_stream_v1_0;

architecture behavorial of convolution_to_viterbi_converter_stream_v1_0 is

    constant viterbi_bit_0_idx : integer := 0;
    constant viterbi_bit_1_idx : integer := 8;
    constant conv_bit_0_idx    : integer := 0;
    constant conv_bit_1_idx    : integer := 1;

    -- axi slave signals
    signal s_user_rdy    : std_logic := '0';
    signal s_user_dvalid : std_logic := '0';
    signal s_user_data   : std_logic_vector(WORD_SIZE_IN-1 downto 0) := (others => '0');
    signal s_axis_rdy    : std_logic := '0';

    -- axi master signals
    signal m_user_data   : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');
    signal m_user_dvalid : std_logic := '0';
    signal m_user_txdone : std_logic := '0';
    signal m_axis_rdy    : std_logic := '0';

    -- internal buffers
    signal new_word       : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');
    signal current_word   : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');
    signal word_accessed  : std_logic := '0'; -- 1 when the master interface copies it to it's buffer
    signal new_word_ready : std_logic := '0'; -- 1 when a new word is available for the master interface

    signal cnt_in : integer := 0;
    signal cnt_out : integer := 0;
    
begin

    axi_master_stream_inst : axi_master_stream
    generic map (C_M_AXIS_TDATA_WIDTH => WORD_SIZE_OUT)
    port map (
        user_din       => m_user_data,
        user_dvalid    => m_user_dvalid,
        user_txdone    => m_user_txdone,
        axis_rdy       => m_axis_rdy,
        axis_last      => '0',
        M_AXIS_ACLK    => AXIS_ACLK,
        M_AXIS_ARESETN => AXIS_ARESETN,
        M_AXIS_TVALID  => M_AXIS_TVALID,
        M_AXIS_TDATA   => M_AXIS_TDATA,
        M_AXIS_TSTRB   => open,
        M_AXIS_TLAST   => open,
        M_AXIS_TREADY  => M_AXIS_TREADY
        );

    axi_slave_stream_inst : axi_slave_stream
    generic map (C_S_AXIS_TDATA_WIDTH => WORD_SIZE_IN)
    port map (
        user_rdy       => s_user_rdy,
        user_dvalid    => s_user_dvalid,
        user_data      => s_user_data,
        axis_rdy       => s_axis_rdy,
        axis_last      => open,
        S_AXIS_ACLK    => AXIS_ACLK,
        S_AXIS_ARESETN => AXIS_ARESETN,
        S_AXIS_TREADY  => S_AXIS_TREADY,
        S_AXIS_TDATA   => S_AXIS_TDATA,
        S_AXIS_TSTRB   => (others => '0'),
        S_AXIS_TLAST   => '0',
        S_AXIS_TVALID  => S_AXIS_TVALID
        );

    ----------------------------------------------------------------------
    -- Axi-Stream Slave Controller
    ----------------------------------------------------------------------
    NUM_IN <= std_logic_vector(to_unsigned(cnt_in, 32));
    slave_proc : process(AXIS_ACLK, AXIS_ARESETN)
        type fsm_states_slv  is (ST_IDLE, ST_ACTIVE, ST_SYNC);
        variable fsm : fsm_states_slv := ST_IDLE;
    begin
    if(AXIS_ARESETN = '0') then
        cnt_in <= 0;
        fsm            := ST_IDLE;
        s_user_rdy     <= '0';
        new_word_ready <= '0';
    elsif(rising_edge(AXIS_ACLK)) then
        case(fsm) is
        when ST_IDLE =>
            if(s_axis_rdy = '1') then
                s_user_rdy <= '1';
                fsm        := ST_ACTIVE;
            end if;

        when ST_ACTIVE =>
            s_user_rdy <= '0';
            if(s_user_dvalid = '1') then
                new_word(viterbi_bit_1_idx) <= s_user_data(conv_bit_1_idx);
                new_word(viterbi_bit_0_idx) <= s_user_data(conv_bit_0_idx);                
                fsm            := ST_SYNC;
                new_word_ready <= '1';
                cnt_in <= cnt_in + 1;
            end if;
            
        when ST_SYNC =>
            if(word_accessed = '1') then
                new_word_ready <= '0';
                fsm := ST_IDLE;
            end if;
            
        when others =>
            fsm := ST_IDLE;

        end case;
    end if;
    end process slave_proc;

    ----------------------------------------------------------------
    -- Axi-Stream Master Controller 
    ----------------------------------------------------------------
    NUM_OUT <= std_logic_vector(to_unsigned(cnt_out, 32));
    master_proc : process(AXIS_ACLK, AXIS_ARESETN)
        type fsm_states_mstr is (ST_IDLE, ST_ACTIVE);
        variable fsm : fsm_states_mstr := ST_IDLE;
    begin
    if(AXIS_ARESETN = '0') then
        cnt_out <= 0;
        m_user_data   <= (others => '0');
        m_user_dvalid <= '0';
        word_accessed <= '0';
        fsm := ST_IDLE;
    elsif(rising_edge(AXIS_ACLK)) then
        case(fsm) is

        when ST_IDLE =>
            m_user_dvalid <= '0';
            if(new_word_ready = '1') then
                current_word  <= new_word;
                word_accessed <= '1';
                fsm := ST_ACTIVE;
            end if;

        when ST_ACTIVE =>
            word_accessed <= '0';
            if(m_axis_rdy = '1') then
                m_user_dvalid <= '1';
                m_user_data   <= current_word;
                fsm           := ST_IDLE;
                cnt_out <= cnt_out + 1;
            end if;

        when others =>
            fsm := ST_IDLE;

        end case;
    end if;
    end process master_proc;

end behavorial;
