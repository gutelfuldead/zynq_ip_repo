----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 07/17/2017
-- Design Name: 
-- Module Name: viterbi_input_buffer_v1_0
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: 
--  Viterbi input buffer primes the Xilinx Viterbi Core by first inserting PRIME_SIZE*4 
--  number of zero vector inputs. After intitialization will simply pass through 2 bits
--  at a time from the received data per the Viterbi Core Specification.
--
--  Priming is being used to prepare for Trellis Termination (Tail Bits) method of 
--  Encoding.
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

entity viterbi_input_buffer_v1_0 is
    generic (
    WORD_SIZE_OUT  : integer := 16;
    WORD_SIZE_IN   : integer := 8;
    PRIME_SIZE      : integer := 25
    );
    port (
    AXIS_ACLK : in std_logic;
    AXIS_ARESETN    : in std_logic;
    
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(WORD_SIZE_IN-1 downto 0);
    S_AXIS_TVALID    : in std_logic;
    
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(WORD_SIZE_OUT-1 downto 0);
    M_AXIS_TREADY : in std_logic
    );
end viterbi_input_buffer_v1_0;

architecture behavorial of viterbi_input_buffer_v1_0 is

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
    signal new_word     : std_logic_vector(WORD_SIZE_IN-1 downto 0) := (others => '0');
    signal current_word     : std_logic_vector(WORD_SIZE_IN-1 downto 0) := (others => '0');
    signal word_accessed  : std_logic := '0'; -- 1 when the master interface copies it to it's buffer
    signal new_word_ready : std_logic := '0'; -- 1 when a new word is available for the master interface

    -- for every byte there are 4 transactions occuring
    constant PRIME_XACTIONS  : integer := PRIME_SIZE*4;

     --signal dbg_cnt_prime  : integer := 0;
     --signal dbg_bit_idx_0  : integer := 0;
     --signal dbg_bit_idx_1  : integer := 0;
     --signal dbg_byte_cnt   : integer := 0;

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
    -- Takes in a n-byte word and transfers it to the master state machine
    -- Captures the next n-byte word always ready to feed the master state
    -- Machine the next word
    ----------------------------------------------------------------------
    slave_proc : process(AXIS_ACLK, AXIS_ARESETN)
        type fsm_states_slv  is (ST_IDLE, ST_ACTIVE, ST_SYNC);
        variable fsm : fsm_states_slv := ST_IDLE;
    begin
    if(AXIS_ARESETN = '0') then
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
                new_word       <= s_user_data;
                new_word_ready <= '1';
                fsm            := ST_SYNC;
            end if;

        when ST_SYNC =>
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
    ----------------------------------------------------------------
    master_proc : process(AXIS_ACLK, AXIS_ARESETN)
        type fsm_states_mstr is (ST_INITIALIZE, ST_BLOCK_GEN, ST_BLOCK_SEND, 
            ST_PRIME, ST_BYTE_IDX_UPD, ST_PRIME_CNT);
        constant WORD_SZ    : integer := 3;
        variable fsm : fsm_states_mstr := ST_INITIALIZE;
        variable cnt_prime  : integer range 0 to PRIME_XACTIONS  := 0;
        variable INITIALIZE : std_logic := '1';
        variable bit_idx_0  : integer range 0 to 6 := 0;
        variable bit_idx_1  : integer range 1 to 7 := 1;
        variable byte_cnt   : integer range 0 to WORD_SZ := 0;
    begin
    if(AXIS_ARESETN = '0') then
        m_user_data   <= (others => '0');
        m_user_dvalid <= '0';
        word_accessed <= '0';
        fsm := ST_INITIALIZE;
        cnt_prime := 0;
        bit_idx_0 := 0;
        bit_idx_1 := 1;
        byte_cnt  := 0;
    elsif(rising_edge(AXIS_ACLK)) then
        case(fsm) is

        when ST_INITIALIZE =>
            if(INITIALIZE = '1') then
                fsm := ST_PRIME;
            else
                fsm := ST_BLOCK_GEN;
            end if;

        when ST_BLOCK_GEN =>
            m_user_dvalid <= '0';
            if(new_word_ready = '1') then
                current_word <= new_word;
                word_accessed <= '1';
                m_user_data <= (others => '0');
                fsm := ST_BLOCK_SEND;
            end if;

        when ST_BLOCK_SEND =>
            word_accessed <= '0';
            if(m_axis_rdy = '1') then
                m_user_data(0) <= current_word(bit_idx_0);
                m_user_data(8) <= current_word(bit_idx_1);
                m_user_dvalid  <= '1';
                fsm := ST_BYTE_IDX_UPD;
            end if;

        when ST_BYTE_IDX_UPD =>
            m_user_dvalid <= '0';
            if(m_user_txdone = '1') then
                if(byte_cnt = WORD_SZ) then
                    byte_cnt  := 0;
                    bit_idx_0 := 0;
                    bit_idx_1 := 1;
                    fsm := ST_BLOCK_GEN;
                else
                    bit_idx_0 := bit_idx_0 + 2;
                    bit_idx_1 := bit_idx_1 + 2;
                    byte_cnt := byte_cnt + 1;
                    fsm := ST_BLOCK_SEND;
                end if;
            end if;

        when ST_PRIME =>
            if(m_axis_rdy = '1') then
                m_user_data <= (others => '0');
                m_user_dvalid <= '1';
                fsm := ST_PRIME_CNT;
            end if;

        WHEN ST_PRIME_CNT =>
            m_user_dvalid <= '0';
            if(m_user_txdone = '1') then
                if(cnt_prime = PRIME_XACTIONS) then
                    cnt_prime := 0;
                    INITIALIZE := '0';
                    fsm := ST_BLOCK_GEN;
                else
                    cnt_prime := cnt_prime + 1;
                    fsm := ST_PRIME;
                end if;
            end if;

        when others =>
            fsm := ST_INITIALIZE;

        end case;

         --dbg_byte_cnt  <= byte_cnt;
         --dbg_cnt_prime <= cnt_prime;
         --dbg_bit_idx_1 <= bit_idx_1;
         --dbg_bit_idx_0 <= bit_idx_0;

    end if;
    end process master_proc;

end behavorial;
