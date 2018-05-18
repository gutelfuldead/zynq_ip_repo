library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.axistream_spw_lite_v1_0_pkg.all;

entity axistream_spw_lite_v1_0_tb is
	generic (
		sysfreq : real := 100000000.0;
		txclkfreq : real := 200000000.0;
		--rximpl : spw_implementation_type := impl_generic; 
		rxchunk_fast : integer range 1 to 4 := 1;
		--tximpl : spw_implementation_type := impl_generic; 
		rxfifosize_bits : integer range 6 to 14 := 11; -- 11 (2 kByte)
		txfifosize_bits : integer range 2 to 14 := 11; -- 11 (2 kByte)
		txdivcnt : std_logic_vector(7 downto 0) := x"04";
		rximpl_fast         : boolean := false; -- true to use rx_clk 
		tximpl_fast         : boolean := false; -- true to use tx_clk
		debug_loopback_mode : boolean := true
	);
end axistream_spw_lite_v1_0_tb;

architecture arch_imp of axistream_spw_lite_v1_0_tb is

	-- control signals
    constant aclk_period : time := 10 ns; -- 100 MHz clock
    constant txclk_period : time := 5 ns; 
    constant rxclk_period : time := 12 ns;
	signal aclk, txclk, rxclk : std_logic := '0';
	signal aresetn : std_logic := '0';

    -- data connections
    signal s_di : std_logic := '0';
    signal s_si : std_logic := '0';
    signal s_do : std_logic := '0';
    signal s_so : std_logic := '0';

    -- slave axis lines
    signal s_axis_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    signal s_axis_tvalid : std_logic := '0';
    signal s_axis_tready : std_logic := '0';
    signal s_axis_tlast  : std_logic := '0';

    -- master axis lines
    signal m_axis_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    signal m_axis_tvalid : std_logic := '0';
    signal m_axis_tready : std_logic := '0';
    signal m_axis_tlast  : std_logic := '0';
    signal rx_error      : std_logic := '0';
        
    -- test data
    signal word_in  : unsigned(7 downto 0) := (others => '0');
    signal word_out : unsigned(7 downto 0) := (others => '0');
    signal expected_word : unsigned(7 downto 0) := (others => '0');
    signal INVALID_WORD_RECEIVED : std_logic := '0';

begin

    aclk_gen : process
    begin
        aclk <= not aclk;
        wait for aclk_period/2;
    end process aclk_gen;

    txclk_gen : process
    begin
        txclk <= not txclk;
        wait for txclk_period/2;
    end process txclk_gen;

    rxclk_gen : process
    begin
        rxclk <= not rxclk;
        wait for rxclk_period/2;
    end process rxclk_gen;

    reset_gen : process
    begin
        aresetn <= '0';
        wait for aclk_period*5;
        aresetn <= '1';
        wait for 1000 ms;
    end process reset_gen;

	axistream_spw_lite_v1_0_inst : axistream_spw_lite_v1_0
	generic map (
		sysfreq             => sysfreq,
		txclkfreq           => txclkfreq,
		rximpl_fast         => rximpl_fast,
		rxchunk_fast        => rxchunk_fast,
		tximpl_fast         => tximpl_fast,
		rxfifosize_bits     => rxfifosize_bits,
		txfifosize_bits     => txfifosize_bits,
		txdivcnt            => txdivcnt,
		debug_loopback_mode => debug_loopback_mode
	)
	port map (
		aclk    => aclk,
		aresetn => aresetn,
		rx_clk  => rxclk,
		tx_clk  => txclk,

        spw_di => s_di,
        spw_si => s_si,
        spw_do => s_do,
        spw_so => s_so,

        s_axis_tdata  => s_axis_tdata,
        s_axis_tvalid => s_axis_tvalid,
        s_axis_tready => s_axis_tready,
        s_axis_tlast  => s_axis_tlast,

        m_axis_tdata  => m_axis_tdata,
        m_axis_tvalid => m_axis_tvalid,
        m_axis_tready => m_axis_tready,
        m_axis_tlast  => m_axis_tlast,

        rx_error      => rx_error
	);

	s_axis_tvalid <= '1';
	m_axis_tready <= '1';
	s_axis_tdata  <= std_logic_vector(word_in);
	s_axis_tlast  <= '1' when word_in = to_unsigned(255, 8) else '0';
	word_out      <= unsigned(m_axis_tdata) when m_axis_tvalid = '1' else word_out;


	process(aclk)
	begin
	if(rising_edge(aclk)) then
		if(m_axis_tvalid = '1') then
			expected_word <= expected_word + 1;
			if(unsigned(m_axis_tdata) /= expected_word) then
				report "INVALID WORD RECEIVED" severity warning;
				INVALID_WORD_RECEIVED <= '1';
			end if;
		end if;
	end if;
	end process;

	process(aclk)
	begin
	if(rising_edge(aclk)) then
		if(s_axis_tready = '1') then
			word_in <= word_in + 1;
		end if;
	end if;
	end process;


end arch_imp;
