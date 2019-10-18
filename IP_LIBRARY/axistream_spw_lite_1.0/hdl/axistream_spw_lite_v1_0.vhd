library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.spwpkg.all;

package axistream_spw_lite_v1_0_pkg is

    component axistream_spw_lite_v1_0 is
    generic (
        sysfreq         : real                         := 100000000.0;
        txclkfreq       : real                         := 0.0;
        rximpl_fast     : boolean                      := false; -- true to use rx_clk
        tximpl_fast     : boolean                      := false; -- true to use tx_clk
        rxchunk_fast    : integer range 1 to 4         := 1;
        rxfifosize_bits : integer range 6 to 14        := 11; -- 11 (2 kByte)
        txfifosize_bits : integer range 2 to 14        := 11; -- 11 (2 kByte)
        txdivcnt        : std_logic_vector(7 downto 0) := x"04"
    );
    port (
        aclk          : in    std_logic;
        aresetn       : in    std_logic;
        rx_clk        : in    std_logic;
        tx_clk        : in    std_logic;

        spw_di        : in    std_logic;
        spw_si        : in    std_logic;
        spw_do        :   out std_logic;
        spw_so        :   out std_logic;

        s_axis_tdata  : in    std_logic_vector(7 downto 0);
        s_axis_tvalid : in    std_logic;
        s_axis_tlast  : in    std_logic;
        s_axis_tready :   out std_logic;

        m_axis_tready : in    std_logic;
        m_axis_tdata  :   out std_logic_vector(7 downto 0);
        m_axis_tvalid :   out std_logic;
        m_axis_tlast  :   out std_logic;

        rx_error      :   out std_logic
    );
    end component axistream_spw_lite_v1_0;

end package axistream_spw_lite_v1_0_pkg;

-------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.spwpkg.all;
use work.axistream_spw_lite_v1_0_pkg.all;

entity axistream_spw_lite_v1_0 is
    generic (
        -- System clock frequency in    Hz.
        -- This must be set to the frequency of "clk". It is used to setup
        -- counters for reset timing, disconnect timeout and to transmit
        -- at 10 Mbit/s during the link handshake.
        sysfreq         : real   := 100000000.0;
        -- Transmit clock frequency in    Hz (only if tximpl = impl_fast).
        -- This must be set to the frequency of "txclk". It is used to
        -- transmit at 10 Mbit/s during the link handshake.
        txclkfreq       : real := 0.0;
        -- Maximum number of bits received per system clock
        -- (must be 1 in    case of impl_generic).
        rxchunk_fast    : integer range 1 to 4 := 1;
        -- Size of the receive FIFO as the 2-logarithm of the number of bytes.
        -- Must be at least 6 (64 bytes).
        rxfifosize_bits : integer range 6 to 14 := 11; -- 11 (2 kByte)
        -- Size of the transmit FIFO as the 2-logarithm of the number of bytes.
        txfifosize_bits : integer range 2 to 14 := 11; -- 11 (2 kByte)
        -- Scaling factor minus 1, used to scale the transmit base clock into
        -- the transmission bit rate. The system clock (for impl_generic) or
        -- the txclk (for impl_fast) is divided by (unsigned(txdivcnt) + 1).
        -- Changing this signal will immediately change the transmission rate.
        -- During link setup, the transmission rate is always 10 Mbit/s.
        txdivcnt        : std_logic_vector(7 downto 0) := x"04";
        rximpl_fast     : boolean := false; -- true to use rx_clk
        tximpl_fast     : boolean := false  -- true to use tx_clk
    );
    port (
        aclk          : in    std_logic;
        aresetn       : in    std_logic;
        rx_clk        : in    std_logic;
        tx_clk        : in    std_logic;

        spw_di        : in    std_logic;
        spw_si        : in    std_logic;
        spw_do        :   out std_logic;
        spw_so        :   out std_logic;

        s_axis_tdata  : in    std_logic_vector(7 downto 0);
        s_axis_tvalid : in    std_logic;
        s_axis_tlast  : in    std_logic;
        s_axis_tready :   out std_logic;

        m_axis_tready : in    std_logic;
        m_axis_tdata  :   out std_logic_vector(7 downto 0);
        m_axis_tvalid :   out std_logic;
        m_axis_tlast  :   out std_logic;

        rx_error      :   out std_logic
    );
end axistream_spw_lite_v1_0;

architecture arch_imp of axistream_spw_lite_v1_0 is

    constant SPW_EOP : std_logic_vector(7 downto 0) := x"00";
    constant SPW_EEP : std_logic_vector(7 downto 0) := x"01";

    signal reset : std_logic := '0'; -- active high

    -- spacewire tx signals
    signal spw_txwrite : std_logic := '0';
    signal spw_txflag  : std_logic := '0';
    signal spw_txready : std_logic := '0';
    signal spw_txdata  : std_logic_vector(7 downto 0) := (others => '0');

    -- spacewire rx signals
    signal spw_rxvalid  : std_logic                    := '0';
    signal spw_txhalff  : std_logic                    := '0';
    signal spw_tick_out : std_logic                    := '0';
    signal spw_rxhalff  : std_logic                    := '0';
    signal spw_rxflag   : std_logic                    := '0';
    signal spw_rxdata   : std_logic_vector(7 downto 0) := (others => '0');
    signal spw_rxread   : std_logic                    := '0';

    -- spacewire status signals
    signal spw_linkstart  : std_logic := '0';
    signal spw_started    : std_logic := '0';
    signal spw_connecting : std_logic := '0';
    signal spw_running    : std_logic := '0';
    signal spw_errdisc    : std_logic := '0';
    signal spw_errpar     : std_logic := '0';
    signal spw_erresc     : std_logic := '0';
    signal spw_errcred    : std_logic := '0';

    -- AXIS Slave signals
    type s_axis_proc_states is (ST_ACTIVE, ST_SYNC, ST_EOP);
    signal fsm_s_axis_proc_states : s_axis_proc_states;
    signal tx_eop : boolean := false;

    -- AXIS Master signals and functions
    type SPW_RXBUF_T is record
        byte  : std_logic_vector(7 downto 0) := (others => '0');
        eep   : boolean;
        eop   : boolean;
        valid : boolean;
    end record;

    signal rxbuf_0 : SPW_RXBUF_T;
    signal rxbuf_1 : SPW_RXBUF_T;

    type m_axis_proc_states is (ST_READ_SPW_WORDS, ST_SPW_WORD_SYNC, ST_SEND_AXIS);
    signal fsm_m_axis_proc_states : m_axis_proc_states := ST_READ_SPW_WORDS;

    function reset_spw_buf_t(noop : std_logic) return SPW_RXBUF_T is
        variable a : SPW_RXBUF_T;
    begin
        a.byte  := (others => '0');
        a.eep   := false;
        a.eop   := false;
        a.valid := false;
        return a;
    end function;

    function copy_spw_buf_t(BUF_IN : SPW_RXBUF_T) return SPW_RXBUF_T is
        variable a : SPW_RXBUF_T;
    begin
        a.byte  := BUF_IN.byte;
        a.eep   := BUF_IN.eep;
        a.eop   := BUF_IN.eop;
        a.valid := BUF_IN.valid;
        return a;
    end function;

begin

-----------------------------------------------------------------------------------------------

    reset         <= (not aresetn) or spw_errdisc or spw_errpar or spw_erresc or spw_errcred;
    rx_error      <= '1' when (spw_running = '0' or rxbuf_0.eep or rxbuf_1.eep) else '0';
    spw_linkstart <= '0' when reset = '1' else '1';

-----------------------------------------------------------------------------------------------

    s_axis_proc : process(aclk)
        variable fsm : s_axis_proc_states := ST_ACTIVE;
    begin
    if (reset = '1') then
        s_axis_tready <= '0';
        spw_txwrite   <= '0';
        spw_txflag    <= '0';
        spw_txdata    <= (others => '0');
        tx_eop        <= false;
        fsm           := ST_ACTIVE;
    elsif (rising_edge(aclk)) then
    if (spw_running = '1') then
        case (fsm) is

            when ST_ACTIVE =>
                if (spw_txready = '1' and s_axis_tvalid = '1') then
                    fsm := ST_SYNC;
                    if (s_axis_tlast = '1') then
                        tx_eop <= true;
                    end if;
                    spw_txdata    <= s_axis_tdata;
                    spw_txwrite   <= '1';
                    spw_txflag    <= '0';
                    s_axis_tready <= '1';
                end if;

            when ST_SYNC =>
                s_axis_tready <= '0';
                spw_txwrite   <= '0';
                spw_txflag    <= '0';
                spw_txdata    <= (others => '0');
                if (tx_eop) then
                    fsm := ST_EOP;
                else
                    fsm := ST_ACTIVE;
                end if;

            when ST_EOP =>
                tx_eop <= false;
                if (spw_txready = '1') then
                    fsm         := ST_SYNC;
                    spw_txdata  <= SPW_EOP;
                    spw_txwrite <= '1';
                    spw_txflag  <= '1';
                end if;

            when others =>
                fsm           := ST_ACTIVE;
                s_axis_tready <= '0';
                spw_txwrite   <= '0';
                spw_txflag    <= '0';
                spw_txdata    <= (others => '0');
                tx_eop        <= false;

        end case;
        fsm_s_axis_proc_states <= fsm;
    else
        s_axis_tready <= '0';
        spw_txwrite   <= '0';
        spw_txflag    <= '0';
        spw_txdata    <= (others => '0');
        tx_eop        <= false;
        fsm           := ST_ACTIVE;
    end if;
    end if;
    end process s_axis_proc;

-----------------------------------------------------------------------------------------------
-- buffer two bytes so the EOP can be captured to generate the TLAST flag on
-- the correct byte
-----------------------------------------------------------------------------------------------

    m_axis_proc : process(aclk)
        variable fsm : m_axis_proc_states := ST_READ_SPW_WORDS;
    begin
    if (reset = '1') then
        m_axis_tdata     <= (others => '0');
        m_axis_tvalid    <= '0';
        m_axis_tlast     <= '0';
        rxbuf_0          <= reset_spw_buf_t('0');
        rxbuf_1          <= reset_spw_buf_t('0');
        spw_rxread       <= '0';
        fsm              := ST_READ_SPW_WORDS;
    elsif (rising_edge(aclk)) then
    if (spw_running = '1') then
        case (fsm) is

            when ST_READ_SPW_WORDS =>
                if (spw_rxvalid = '1') then
                    spw_rxread <= '1';
                    fsm        := ST_SPW_WORD_SYNC;

                    if (rxbuf_0.valid = false) then
                        rxbuf_0.valid <= true;
                        if (spw_rxflag = '1') then
                            if (spw_rxdata = SPW_EOP) then
                                rxbuf_0.eop <= true;
                            else
                                rxbuf_0.eep <= true;
                            end if;
                        else
                            rxbuf_0.byte <= spw_rxdata;
                        end if;

                    else

                        rxbuf_1.valid <= true;
                        if (spw_rxflag = '1') then
                            if (spw_rxdata = SPW_EOP) then
                                rxbuf_1.eop <= true;
                            else
                                rxbuf_1.eep <= true;
                            end if;
                        else
                            rxbuf_1.byte <= spw_rxdata;
                        end if;

                    end if;

                end if;

            when ST_SPW_WORD_SYNC =>
                spw_rxread    <= '0';
                if (rxbuf_1.valid = false) then
                    fsm := ST_READ_SPW_WORDS;
                else
                    fsm           := ST_SEND_AXIS;
                    m_axis_tdata  <= rxbuf_0.byte;
                    m_axis_tvalid <= '1';
                    if (rxbuf_1.eop) then
                        m_axis_tlast  <= '1';
                        rxbuf_0       <= reset_spw_buf_t('0');
                        rxbuf_1       <= reset_spw_buf_t('0');
                    else
                        m_axis_tlast  <= '0';
                        rxbuf_0       <= copy_spw_buf_t(rxbuf_1);
                    end if;
                end if;

            when ST_SEND_AXIS =>
                if (m_axis_tready = '1') then
                    fsm           := ST_READ_SPW_WORDS;
                    m_axis_tdata  <= (others => '0');
                    m_axis_tvalid <= '0';
                    m_axis_tlast  <= '0';
                end if;

            when others =>
                fsm           := ST_READ_SPW_WORDS;
                rxbuf_0       <= reset_spw_buf_t('0');
                rxbuf_1       <= reset_spw_buf_t('0');
                m_axis_tdata  <= (others => '0');
                m_axis_tvalid <= '0';
                m_axis_tlast  <= '0';

        end case;
        fsm_m_axis_proc_states <= fsm;
    else
        fsm           := ST_READ_SPW_WORDS;
        rxbuf_0       <= reset_spw_buf_t('0');
        rxbuf_1       <= reset_spw_buf_t('0');
        m_axis_tdata  <= (others => '0');
        m_axis_tvalid <= '0';
        m_axis_tlast  <= '0';
    end if;
    end if;
    end process m_axis_proc;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Generate Proper Instantiation of spwstream interface
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

txrx_fast_gen : if rximpl_fast and tximpl_fast generate
    spwstream_inst_txrx_fast : spwstream
    generic map (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_fast,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_fast,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    port map (
        clk        => aclk,
        rxclk      => rx_clk,
        txclk      => tx_clk,
        rst        => reset,
        autostart  => '0',
        linkstart  => spw_linkstart,
        linkdis    => '0',
        txdivcnt   => txdivcnt,
        tick_in    => '0',
        ctrl_in    => "00",
        time_in    => "000000",
        txwrite    => spw_txwrite,
        txflag     => spw_txflag,
        txdata     => spw_txdata,
        txrdy      => spw_txready, -- out
        txhalff    => spw_txhalff, -- out
        tick_out   => spw_tick_out,
        ctrl_out   => open,
        time_out   => open,
        rxvalid    => spw_rxvalid,
        rxhalff    => spw_rxhalff,
        rxflag     => spw_rxflag,
        rxdata     => spw_rxdata,
        rxread     => spw_rxread,
        started    => spw_started,
        connecting => spw_connecting,
        running    => spw_running,
        errdisc    => spw_errdisc,
        errpar     => spw_errpar,
        erresc     => spw_erresc,
        errcred    => spw_errcred,
        spw_di     => spw_di,
        spw_si     => spw_si,
        spw_do     => spw_do,
        spw_so     => spw_so
    );
end generate txrx_fast_gen;

-----------------------------------------------------------------------------------------------

rx_fast_gen   : if rximpl_fast and not tximpl_fast generate
    spwstream_inst_rx_fast : spwstream
    generic map (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_fast,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_generic,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    port map (
        clk        => aclk,
        rxclk      => rx_clk,
        txclk      => '0',
        rst        => reset,
        autostart  => '0',
        linkstart  => spw_linkstart,
        linkdis    => '0',
        txdivcnt   => txdivcnt,
        tick_in    => '0',
        ctrl_in    => "00",
        time_in    => "000000",
        txwrite    => spw_txwrite,
        txflag     => spw_txflag,
        txdata     => spw_txdata,
        txrdy      => spw_txready, -- out
        txhalff    => spw_txhalff, -- out
        tick_out   => spw_tick_out,
        ctrl_out   => open,
        time_out   => open,
        rxvalid    => spw_rxvalid,
        rxhalff    => spw_rxhalff,
        rxflag     => spw_rxflag,
        rxdata     => spw_rxdata,
        rxread     => spw_rxread,
        started    => spw_started,
        connecting => spw_connecting,
        running    => spw_running,
        errdisc    => spw_errdisc,
        errpar     => spw_errpar,
        erresc     => spw_erresc,
        errcred    => spw_errcred,
        spw_di     => spw_di,
        spw_si     => spw_si,
        spw_do     => spw_do,
        spw_so     => spw_so
    );
end generate rx_fast_gen;

-----------------------------------------------------------------------------------------------

tx_fast_gen   : if not rximpl_fast and tximpl_fast generate
    spwstream_inst_tx_fast : spwstream
    generic map (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_generic,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_fast,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    port map (
        clk        => aclk,
        rxclk      => '0',
        txclk      => tx_clk,
        rst        => reset,
        autostart  => '0',
        linkstart  => spw_linkstart,
        linkdis    => '0',
        txdivcnt   => txdivcnt,
        tick_in    => '0',
        ctrl_in    => "00",
        time_in    => "000000",
        txwrite    => spw_txwrite,
        txflag     => spw_txflag,
        txdata     => spw_txdata,
        txrdy      => spw_txready, -- out
        txhalff    => spw_txhalff, -- out
        tick_out   => spw_tick_out,
        ctrl_out   => open,
        time_out   => open,
        rxvalid    => spw_rxvalid,
        rxhalff    => spw_rxhalff,
        rxflag     => spw_rxflag,
        rxdata     => spw_rxdata,
        rxread     => spw_rxread,
        started    => spw_started,
        connecting => spw_connecting,
        running    => spw_running,
        errdisc    => spw_errdisc,
        errpar     => spw_errpar,
        erresc     => spw_erresc,
        errcred    => spw_errcred,
        spw_di     => spw_di,
        spw_si     => spw_si,
        spw_do     => spw_do,
        spw_so     => spw_so
    );
end generate tx_fast_gen;

-----------------------------------------------------------------------------------------------

generic_gen   : if not rximpl_fast and not tximpl_fast generate
    spwstream_inst_generic : spwstream
    generic map (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_generic,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_generic,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    port map (
        clk        => aclk,
        rxclk      => '0',
        txclk      => '0',
        rst        => reset,
        autostart  => '0',
        linkstart  => spw_linkstart,
        linkdis    => '0',
        txdivcnt   => txdivcnt,
        tick_in    => '0',
        ctrl_in    => "00",
        time_in    => "000000",
        txwrite    => spw_txwrite,
        txflag     => spw_txflag,
        txdata     => spw_txdata,
        txrdy      => spw_txready, -- out
        txhalff    => spw_txhalff, -- out
        tick_out   => spw_tick_out,
        ctrl_out   => open,
        time_out   => open,
        rxvalid    => spw_rxvalid,
        rxhalff    => spw_rxhalff,
        rxflag     => spw_rxflag,
        rxdata     => spw_rxdata,
        rxread     => spw_rxread,
        started    => spw_started,
        connecting => spw_connecting,
        running    => spw_running,
        errdisc    => spw_errdisc,
        errpar     => spw_errpar,
        erresc     => spw_erresc,
        errcred    => spw_errcred,
        spw_di     => spw_di,
        spw_si     => spw_si,
        spw_do     => spw_do,
        spw_so     => spw_so
    );
end generate generic_gen;

end arch_imp;
