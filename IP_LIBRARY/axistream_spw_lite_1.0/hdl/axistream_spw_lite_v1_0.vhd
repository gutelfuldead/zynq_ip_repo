LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.spwpkg.ALL;

PACKAGE axistream_spw_lite_v1_0_pkg IS

    COMPONENT axistream_spw_lite_v1_0 IS
    GENERIC (
        sysfreq         : real                         := 100000000.0;
        txclkfreq       : real                         := 0.0;
        rximpl_fast     : boolean                      := FALSE; -- TRUE to USE rx_clk
        tximpl_fast     : boolean                      := FALSE; -- TRUE to USE tx_clk
        rxchunk_fast    : integer range 1 to 4         := 1;
        rxfifosize_bits : integer range 6 to 14        := 11; -- 11 (2 kByte)
        txfifosize_bits : integer range 2 to 14        := 11; -- 11 (2 kByte)
        txdivcnt        : std_logic_vector(7 DOWNTO 0) := x"04"
    );
    PORT (
        aclk          : IN std_logic;
        aresetn       : IN std_logic;
        rx_clk        : IN std_logic;
        tx_clk        : IN std_logic;

        spw_di        : IN std_logic;
        spw_si        : IN std_logic;
        spw_do        :   OUT std_logic;
        spw_so        :   OUT std_logic;

        s_axis_tdata  : IN std_logic_vector(7 DOWNTO 0);
        s_axis_tvalid : IN std_logic;
        s_axis_tlast  : IN std_logic;
        s_axis_tready :   OUT std_logic;

        m_axis_tready : IN std_logic;
        m_axis_tdata  :   OUT std_logic_vector(7 DOWNTO 0);
        m_axis_tvalid :   OUT std_logic;
        m_axis_tlast  :   OUT std_logic;

        rx_error      :   OUT std_logic
    );
    END COMPONENT axistream_spw_lite_v1_0;

END PACKAGE axistream_spw_lite_v1_0_pkg;

-------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

LIBRARY work;
USE work.spwpkg.ALL;
USE work.axistream_spw_lite_v1_0_pkg.ALL;

entity axistream_spw_lite_v1_0 IS
    GENERIC (
        -- System clock frequency IN Hz.
        -- This must be set to the frequency OF "clk". It IS used to setup
        -- counters for reset timing, disconnect timeout AND to transmit
        -- at 10 Mbit/s during the link handshake.
        sysfreq         : real   := 100000000.0;
        -- Transmit clock frequency IN Hz (only IF tximpl = impl_fast).
        -- This must be set to the frequency OF "txclk". It IS used to
        -- transmit at 10 Mbit/s during the link handshake.
        txclkfreq       : real := 0.0;
        -- Maximum number OF bits received per system clock
        -- (must be 1 IN CASE OF impl_generic).
        rxchunk_fast    : integer range 1 to 4 := 1;
        -- Size OF the receive FIFO as the 2-logarithm OF the number OF bytes.
        -- Must be at least 6 (64 bytes).
        rxfifosize_bits : integer range 6 to 14 := 11; -- 11 (2 kByte)
        -- Size OF the transmit FIFO as the 2-logarithm OF the number OF bytes.
        txfifosize_bits : integer range 2 to 14 := 11; -- 11 (2 kByte)
        -- Scaling factor minus 1, used to scale the transmit base clock into
        -- the transmission bit rate. The system clock (for impl_generic) OR
        -- the txclk (for impl_fast) IS divided by (unsigned(txdivcnt) + 1).
        -- Changing this SIGNAL will immediately change the transmission rate.
        -- During link setup, the transmission rate IS always 10 Mbit/s.
        txdivcnt        : std_logic_vector(7 DOWNTO 0) := x"04";
        rximpl_fast     : boolean := FALSE; -- TRUE to USE rx_clk
        tximpl_fast     : boolean := FALSE  -- TRUE to USE tx_clk
    );
    PORT (
        aclk          : IN std_logic;
        aresetn       : IN std_logic;
        rx_clk        : IN std_logic;
        tx_clk        : IN std_logic;

        spw_di        : IN std_logic;
        spw_si        : IN std_logic;
        spw_do        :   OUT std_logic;
        spw_so        :   OUT std_logic;

        s_axis_tdata  : IN std_logic_vector(7 DOWNTO 0);
        s_axis_tvalid : IN std_logic;
        s_axis_tlast  : IN std_logic;
        s_axis_tready :   OUT std_logic;

        m_axis_tready : IN std_logic;
        m_axis_tdata  :   OUT std_logic_vector(7 DOWNTO 0);
        m_axis_tvalid :   OUT std_logic;
        m_axis_tlast  :   OUT std_logic;

        rx_error      :   OUT std_logic
    );
END axistream_spw_lite_v1_0;

ARCHITECTURE arch_imp OF axistream_spw_lite_v1_0 IS

    CONSTANT SPW_EOP : std_logic_vector(7 DOWNTO 0) := x"00";
    CONSTANT SPW_EEP : std_logic_vector(7 DOWNTO 0) := x"01";

    SIGNAL reset : std_logic := '0'; -- active high

    -- spacewire tx signals
    SIGNAL spw_txwrite : std_logic := '0';
    SIGNAL spw_txflag  : std_logic := '0';
    SIGNAL spw_txready : std_logic := '0';
    SIGNAL spw_txdata  : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');

    -- spacewire rx signals
    SIGNAL spw_rxvalid  : std_logic                    := '0';
    SIGNAL spw_txhalff  : std_logic                    := '0';
    SIGNAL spw_tick_out : std_logic                    := '0';
    SIGNAL spw_rxhalff  : std_logic                    := '0';
    SIGNAL spw_rxflag   : std_logic                    := '0';
    SIGNAL spw_rxdata   : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');
    SIGNAL spw_rxread   : std_logic                    := '0';

    -- spacewire status signals
    SIGNAL spw_linkstart  : std_logic := '0';
    SIGNAL spw_started    : std_logic := '0';
    SIGNAL spw_connecting : std_logic := '0';
    SIGNAL spw_running    : std_logic := '0';
    SIGNAL spw_errdisc    : std_logic := '0';
    SIGNAL spw_errpar     : std_logic := '0';
    SIGNAL spw_erresc     : std_logic := '0';
    SIGNAL spw_errcred    : std_logic := '0';

    -- AXIS Slave signals
    TYPE s_axis_proc_states IS (ST_ACTIVE, ST_SYNC, ST_EOP);
    SIGNAL fsm_s_axis_proc_states : s_axis_proc_states;
    SIGNAL tx_eop : boolean := FALSE;

    -- AXIS Master signals AND functions
    TYPE SPW_RXBUF_T IS RECORD
        byte  : std_logic_vector(7 DOWNTO 0);
        eep   : boolean;
        eop   : boolean;
        valid : boolean;
    END RECORD;

    SIGNAL rxbuf_0 : SPW_RXBUF_T;
    SIGNAL rxbuf_1 : SPW_RXBUF_T;

    TYPE m_axis_proc_states IS (ST_READ_SPW_WORDS, ST_SPW_WORD_SYNC, ST_SEND_AXIS);
    SIGNAL fsm_m_axis_proc_states : m_axis_proc_states := ST_READ_SPW_WORDS;

    FUNCTION reset_spw_buf_t(noop : std_logic) RETURN SPW_RXBUF_T IS
        VARIABLE a : SPW_RXBUF_T;
    BEGIN
        a.byte  := (OTHERS => '0');
        a.eep   := FALSE;
        a.eop   := FALSE;
        a.valid := FALSE;
        RETURN a;
    END FUNCTION;

    FUNCTION copy_spw_buf_t(BUF_IN : SPW_RXBUF_T) RETURN SPW_RXBUF_T IS
        VARIABLE a : SPW_RXBUF_T;
    BEGIN
        a.byte  := BUF_IN.byte;
        a.eep   := BUF_IN.eep;
        a.eop   := BUF_IN.eop;
        a.valid := BUF_IN.valid;
        RETURN a;
    END FUNCTION;

BEGIN

-----------------------------------------------------------------------------------------------

    reset         <= (NOT aresetn) OR spw_errdisc OR spw_errpar OR spw_erresc OR spw_errcred;
    rx_error      <= '1' WHEN (spw_running = '0' OR rxbuf_0.eep OR rxbuf_1.eep) ELSE '0';
    spw_linkstart <= '0' WHEN reset = '1' ELSE '1';

-----------------------------------------------------------------------------------------------

    s_axis_proc : PROCESS(aclk)
        VARIABLE fsm : s_axis_proc_states := ST_ACTIVE;
    BEGIN
    IF (reset = '1') THEN
        s_axis_tready <= '0';
        spw_txwrite   <= '0';
        spw_txflag    <= '0';
        spw_txdata    <= (OTHERS => '0');
        tx_eop        <= FALSE;
        fsm           := ST_ACTIVE;
    ELSIF (rising_edge(aclk)) THEN
    IF (spw_running = '1') THEN
        CASE (fsm) IS

            WHEN ST_ACTIVE =>
                IF (spw_txready = '1' AND s_axis_tvalid = '1') THEN
                    fsm := ST_SYNC;
                    IF (s_axis_tlast = '1') THEN
                        tx_eop <= TRUE;
                    END IF;
                    spw_txdata    <= s_axis_tdata;
                    spw_txwrite   <= '1';
                    spw_txflag    <= '0';
                    s_axis_tready <= '1';
                END IF;

            WHEN ST_SYNC =>
                s_axis_tready <= '0';
                spw_txwrite   <= '0';
                spw_txflag    <= '0';
                spw_txdata    <= (OTHERS => '0');
                IF (tx_eop) THEN
                    fsm := ST_EOP;
                ELSE
                    fsm := ST_ACTIVE;
                END IF;

            WHEN ST_EOP =>
                tx_eop <= FALSE;
                IF (spw_txready = '1') THEN
                    fsm         := ST_SYNC;
                    spw_txdata  <= SPW_EOP;
                    spw_txwrite <= '1';
                    spw_txflag  <= '1';
                END IF;

            WHEN OTHERS =>
                fsm           := ST_ACTIVE;
                s_axis_tready <= '0';
                spw_txwrite   <= '0';
                spw_txflag    <= '0';
                spw_txdata    <= (OTHERS => '0');
                tx_eop        <= FALSE;

        END CASE;
        fsm_s_axis_proc_states <= fsm;
    ELSE
        s_axis_tready <= '0';
        spw_txwrite   <= '0';
        spw_txflag    <= '0';
        spw_txdata    <= (OTHERS => '0');
        tx_eop        <= FALSE;
        fsm           := ST_ACTIVE;
    END IF;
    END IF;
    END PROCESS s_axis_proc;

-----------------------------------------------------------------------------------------------
-- buffer two bytes so the EOP can be captured to GENERATE the TLAST flag on
-- the correct byte
-----------------------------------------------------------------------------------------------

    m_axis_proc : PROCESS(aclk)
        VARIABLE fsm : m_axis_proc_states := ST_READ_SPW_WORDS;
    BEGIN
    IF (reset = '1') THEN
        m_axis_tdata     <= (OTHERS => '0');
        m_axis_tvalid    <= '0';
        m_axis_tlast     <= '0';
        rxbuf_0          <= reset_spw_buf_t('0');
        rxbuf_1          <= reset_spw_buf_t('0');
        spw_rxread       <= '0';
        fsm              := ST_READ_SPW_WORDS;
    ELSIF (rising_edge(aclk)) THEN
    IF (spw_running = '1') THEN
        CASE (fsm) IS

            WHEN ST_READ_SPW_WORDS =>
                IF (spw_rxvalid = '1') THEN
                    spw_rxread <= '1';
                    fsm        := ST_SPW_WORD_SYNC;

                    IF (rxbuf_0.valid = FALSE) THEN
                        rxbuf_0.valid <= TRUE;
                        IF (spw_rxflag = '1') THEN
                            IF (spw_rxdata = SPW_EOP) THEN
                                rxbuf_0.eop <= TRUE;
                            ELSE
                                rxbuf_0.eep <= TRUE;
                            END IF;
                        ELSE
                            rxbuf_0.byte <= spw_rxdata;
                        END IF;

                    ELSE

                        rxbuf_1.valid <= TRUE;
                        IF (spw_rxflag = '1') THEN
                            IF (spw_rxdata = SPW_EOP) THEN
                                rxbuf_1.eop <= TRUE;
                            ELSE
                                rxbuf_1.eep <= TRUE;
                            END IF;
                        ELSE
                            rxbuf_1.byte <= spw_rxdata;
                        END IF;

                    END IF;

                END IF;

            WHEN ST_SPW_WORD_SYNC =>
                spw_rxread    <= '0';
                IF (rxbuf_1.valid = FALSE) THEN
                    fsm := ST_READ_SPW_WORDS;
                ELSE
                    fsm           := ST_SEND_AXIS;
                    m_axis_tdata  <= rxbuf_0.byte;
                    m_axis_tvalid <= '1';
                    IF (rxbuf_1.eop) THEN
                        m_axis_tlast  <= '1';
                        rxbuf_0       <= reset_spw_buf_t('0');
                        rxbuf_1       <= reset_spw_buf_t('0');
                    ELSE
                        m_axis_tlast  <= '0';
                        rxbuf_0       <= copy_spw_buf_t(rxbuf_1);
                    END IF;
                END IF;

            WHEN ST_SEND_AXIS =>
                IF (m_axis_tready = '1') THEN
                    fsm           := ST_READ_SPW_WORDS;
                    m_axis_tdata  <= (OTHERS => '0');
                    m_axis_tvalid <= '0';
                    m_axis_tlast  <= '0';
                END IF;

            WHEN OTHERS =>
                fsm           := ST_READ_SPW_WORDS;
                rxbuf_0       <= reset_spw_buf_t('0');
                rxbuf_1       <= reset_spw_buf_t('0');
                m_axis_tdata  <= (OTHERS => '0');
                m_axis_tvalid <= '0';
                m_axis_tlast  <= '0';

        END CASE;
        fsm_m_axis_proc_states <= fsm;
    ELSE
        fsm           := ST_READ_SPW_WORDS;
        rxbuf_0       <= reset_spw_buf_t('0');
        rxbuf_1       <= reset_spw_buf_t('0');
        m_axis_tdata  <= (OTHERS => '0');
        m_axis_tvalid <= '0';
        m_axis_tlast  <= '0';
    END IF;
    END IF;
    END PROCESS m_axis_proc;

-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
-- Generate Proper Instantiation OF spwstream interface
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

txrx_fast_gen : IF rximpl_fast AND tximpl_fast GENERATE
    spwstream_inst_txrx_fast : spwstream
    GENERIC MAP (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_fast,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_fast,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    PORT MAP (
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
        txrdy      => spw_txready, -- OUT
        txhalff    => spw_txhalff, -- OUT
        tick_out   => spw_tick_out,
        ctrl_out   => OPEN,
        time_out   => OPEN,
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
END GENERATE txrx_fast_gen;

-----------------------------------------------------------------------------------------------

rx_fast_gen   : IF rximpl_fast AND NOT tximpl_fast GENERATE
    spwstream_inst_rx_fast : spwstream
    GENERIC MAP (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_fast,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_generic,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    PORT MAP (
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
        txrdy      => spw_txready, -- OUT
        txhalff    => spw_txhalff, -- OUT
        tick_out   => spw_tick_out,
        ctrl_out   => OPEN,
        time_out   => OPEN,
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
END GENERATE rx_fast_gen;

-----------------------------------------------------------------------------------------------

tx_fast_gen   : IF NOT rximpl_fast AND tximpl_fast GENERATE
    spwstream_inst_tx_fast : spwstream
    GENERIC MAP (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_generic,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_fast,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    PORT MAP (
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
        txrdy      => spw_txready, -- OUT
        txhalff    => spw_txhalff, -- OUT
        tick_out   => spw_tick_out,
        ctrl_out   => OPEN,
        time_out   => OPEN,
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
END GENERATE tx_fast_gen;

-----------------------------------------------------------------------------------------------

generic_gen   : IF NOT rximpl_fast AND NOT tximpl_fast GENERATE
    spwstream_inst_generic : spwstream
    GENERIC MAP (
        sysfreq         => sysfreq,
        txclkfreq       => txclkfreq,
        rximpl          => impl_generic,
        rxchunk         => rxchunk_fast,
        tximpl          => impl_generic,
        rxfifosize_bits => rxfifosize_bits,
        txfifosize_bits => txfifosize_bits
    )
    PORT MAP (
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
        txrdy      => spw_txready, -- OUT
        txhalff    => spw_txhalff, -- OUT
        tick_out   => spw_tick_out,
        ctrl_out   => OPEN,
        time_out   => OPEN,
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
END GENERATE generic_gen;

END arch_imp;
