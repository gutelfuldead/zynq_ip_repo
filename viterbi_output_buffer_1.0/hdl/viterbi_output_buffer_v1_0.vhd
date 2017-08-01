----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 07/17/2017
-- Design Name: 
-- Module Name: viterbi_output_buffer_v1_0
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: 
--  This core connects to the output of the Xilinx Viterbi Decoder Core. In order to use
--  the Viterbi Core after every block of data has passed through it it needs to be primed
--  with 25 bytes of zeros. These zero bytes need to be flushed out from the core. This 
--  core takes those extraneous zero tail bits and flushes them while capturing the actual
--  symbol data and generating output bytes from them. For each block of 255 bytes with a 
--  10 ns clock (100MHz) each block takes ~120 us to process and move to the downstream
--  module (this includes flushing the tail bits). Without the tail bits the core would
--  take ~109.5us to move all of the block data.
--
--  This is done as a method of Trellis Termination (Tail Bits) encoding.
--
--  TLast is generated on the master interface for the last byte in the block.
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

entity viterbi_output_buffer_v1_0 is
    generic (
    WORD_SIZE_OUT  : integer := 8;
    WORD_SIZE_IN   : integer := 8;
    TAIL_SIZE      : integer := 25;
    BLOCK_SIZE     : integer := 255
    );
    port (
    AXIS_ACLK : in std_logic;
    AXIS_ARESETN    : in std_logic;
    
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(WORD_SIZE_IN-1 downto 0);
    S_AXIS_TVALID    : in std_logic;

    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(WORD_SIZE_OUT-1 downto 0);
    M_AXIS_TREADY : in std_logic;
    M_AXIS_TLAST  : out std_logic
    );
end viterbi_output_buffer_v1_0;

architecture behavorial of viterbi_output_buffer_v1_0 is

    -- axi slave signals
    signal s_user_rdy    : std_logic := '0';
    signal s_user_dvalid : std_logic := '0';
    signal s_user_data   : std_logic_vector(WORD_SIZE_IN-1 downto 0) := (others => '0');
    signal s_axis_rdy    : std_logic := '0';
    -- axi master signals
    signal m_user_data   : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');
    signal m_user_dvalid : std_logic := '0';
    signal m_axis_last   : std_logic := '1';
    signal m_user_txdone : std_logic := '0';
    signal m_axis_rdy    : std_logic := '0';

    -- internal buffers
    signal new_word     : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');
    signal word_accessed  : std_logic := '0'; -- 1 when the master interface copies it to it's buffer
    signal new_word_ready : std_logic := '0'; -- 1 when a new word is available for the master interface
    signal last_word_block : std_logic := '0';

    signal dbg_bit_idx   : integer := 0;
    signal dbg_cnt_block : integer := 0;
    signal dbg_cnt_tail  : integer := 0;

begin

    axi_master_stream_inst : axi_master_stream
    generic map (C_M_AXIS_TDATA_WIDTH => WORD_SIZE_OUT)
    port map (
        user_din       => m_user_data,
        user_dvalid    => m_user_dvalid,
        user_txdone    => m_user_txdone,
        axis_rdy       => m_axis_rdy,
        axis_last      => m_axis_last,
        M_AXIS_ACLK    => AXIS_ACLK,
        M_AXIS_ARESETN => AXIS_ARESETN,
        M_AXIS_TVALID  => M_AXIS_TVALID,
        M_AXIS_TDATA   => M_AXIS_TDATA,
        M_AXIS_TSTRB   => open,
        M_AXIS_TLAST   => M_AXIS_TLAST,
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
    -- Takes in a n-byte word and transfers it to the master state machine
    -- Captures the next n-byte word always ready to feed the master state
    -- Machine the next word
    ----------------------------------------------------------------------
    slave_proc : process(AXIS_ACLK, AXIS_ARESETN)
        constant NUM_BITS : integer := 8;
        type fsm_states_slv is (ST_TAIL_BLOCK, ST_BLOCK_CHECK, ST_BLOCK_CAPTURE, ST_BLOCK_ASSEMBLY,
            ST_SYNC_BLOCK, ST_TAIL_CHECK, ST_TAIL_CAPTURE, ST_TAIL_ASSEMBLY);
        variable fsm : fsm_states_slv := ST_TAIL_BLOCK;
        variable bit_idx : integer range 0 to NUM_BITS-1 := 0;
        variable cnt_block : integer range 0 to BLOCK_SIZE := BLOCK_SIZE;
        variable cnt_tail  : integer range 0 to TAIL_SIZE  := 0;
    begin
    if(AXIS_ARESETN = '0') then
        cnt_block := BLOCK_SIZE;
        cnt_tail  := 0;
        bit_idx   := 0;
        fsm       := ST_TAIL_BLOCK;
        s_user_rdy      <= '0';
        new_word_ready  <= '0';
        last_word_block <= '0';
    elsif(rising_edge(AXIS_ACLK)) then
        case(fsm) is

        when ST_TAIL_BLOCK =>
            if(cnt_tail    = TAIL_SIZE) then
                cnt_tail  := 0;
                cnt_block := 0;
                fsm := ST_BLOCK_CHECK;
                last_word_block <= '0';
            elsif(cnt_block = BLOCK_SIZE) then
                fsm := ST_TAIL_CHECK;
            elsif(cnt_block = BLOCK_SIZE-1) then
                fsm := ST_BLOCK_CHECK;
                last_word_block <= '1';
            else
                fsm := ST_BLOCK_CHECK;
                last_word_block <= '0';
            end if;

        when ST_BLOCK_CHECK =>
            if(s_axis_rdy = '1') then
                s_user_rdy <= '1';
                fsm := ST_BLOCK_CAPTURE;
            end if;

        when ST_BLOCK_CAPTURE =>
            s_user_rdy <= '0';
            if(s_user_dvalid = '1') then
                new_word(bit_idx) <= s_user_data(0);
                fsm := ST_BLOCK_ASSEMBLY;
            end if;

        when ST_BLOCK_ASSEMBLY =>
            if(bit_idx = NUM_BITS-1) then
                cnt_block := cnt_block + 1;
                bit_idx   := 0;
                new_word_ready <= '1';
                fsm       := ST_SYNC_BLOCK;
            else
                bit_idx   := bit_idx + 1;
                fsm       := ST_BLOCK_CHECK;
            end if;

        when ST_SYNC_BLOCK =>
            if(word_accessed = '1') then
                fsm            := ST_TAIL_BLOCK;
                new_word_ready <= '0';
            end if;

        when ST_TAIL_CHECK =>
            if(s_axis_rdy = '1') then
                s_user_rdy <= '1';
                fsm := ST_TAIL_CAPTURE; 
            end if;

        when ST_TAIL_CAPTURE =>
            s_user_rdy <= '0';
            if(s_user_dvalid = '1') then
                fsm     := ST_TAIL_ASSEMBLY;
            end if;

        when ST_TAIL_ASSEMBLY =>
            if(bit_idx = NUM_BITS-1) then
                cnt_tail := cnt_tail + 1;
                fsm := ST_TAIL_BLOCK;
                bit_idx := 0;
            else
                bit_idx := bit_idx + 1;
                fsm := ST_TAIL_CHECK;
            end if;


        when others =>
            fsm := ST_TAIL_BLOCK;

        end case;

        dbg_cnt_tail  <= cnt_tail;
        dbg_cnt_block <= cnt_block;
        dbg_bit_idx   <= bit_idx;

    end if;
    end process slave_proc;

       ----------------------------------------------------------------
    -- Axi-Stream Master Controller
    ----------------------------------------------------------------
    master_proc : process(AXIS_ACLK, AXIS_ARESETN)
        type fsm_states_mstr is (ST_IDLE, ST_ACTIVE, ST_WAIT);
        variable fsm : fsm_states_mstr := ST_IDLE;
    begin
    if(AXIS_ARESETN = '0') then
        m_user_data   <= (others => '0');
        m_user_dvalid <= '0';
        m_axis_last  <= '0';
        word_accessed <= '0';
        fsm := ST_IDLE;
    elsif(rising_edge(AXIS_ACLK)) then
        case(fsm) is

        when ST_IDLE =>
            if(new_word_ready = '1') then
                m_user_data  <= new_word;
                m_axis_last <= last_word_block;
                word_accessed <= '1';
                fsm := ST_ACTIVE;
            end if;

        when ST_ACTIVE =>
            word_accessed <= '0';
            if(m_axis_rdy = '1') then
                m_user_dvalid <= '1';
                fsm           := ST_WAIT;
            end if;

        when ST_WAIT =>
            m_user_dvalid <= '0';
            if(m_user_txdone = '1') then
                fsm := ST_IDLE;
            end if;

        when others =>
            fsm := ST_IDLE;

        end case;
    end if;
    end process master_proc;

end behavorial;
