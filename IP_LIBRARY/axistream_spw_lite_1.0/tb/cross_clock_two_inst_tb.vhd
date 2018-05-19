library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.axistream_spw_lite_v1_0_pkg.all;

entity cross_clock_two_inst_tb is
	generic (
		sysfreq_i0      : real := 100000000.0;
		aclk_period_i0  : time := 10 ns; -- 100 MHz clock
		txclkfreq_i0    : real := 200000000.0;
		txclk_period_i0 : time := 5 ns; 
		rxclk_period_i0 : time := 5 ns;
		
		sysfreq_i1      : real := 33000000.0;
		aclk_period_i1  : time := 30.3030303 ns; -- 33 MHz clock
		txclkfreq_i1    : real := 200000000.0;
		txclk_period_i1 : time := 5 ns; 
		rxclk_period_i1 : time := 5 ns;
		
		--rximpl : spw_implementation_type := impl_generic; 
		rxchunk_fast : integer range 1 to 4 := 1;
		--tximpl : spw_implementation_type := impl_generic; 
		rxfifosize_bits : integer range 6 to 14 := 11; -- 11 (2 kByte)
		txfifosize_bits : integer range 2 to 14 := 11; -- 11 (2 kByte)
		txdivcnt : std_logic_vector(7 downto 0) := x"04";
		rximpl_fast         : boolean := false; -- true to use rx_clk 
		tximpl_fast         : boolean := false -- true to use tx_clk
	);
end cross_clock_two_inst_tb;

architecture arch_imp of cross_clock_two_inst_tb is

	signal start : boolean := true;

	-- control signals instance 0
	signal aclk_i0, txclk_i0, rxclk_i0 : std_logic := '0';
	signal aresetn_i0 : std_logic := '0';

	-- control signals instance 1
	signal aclk_i1, txclk_i1, rxclk_i1 : std_logic := '1';
	signal aresetn_i1 : std_logic := '0';

    -- data connections
    signal s_do : std_logic := '0';
    signal s_di : std_logic := '0';
    signal s_so : std_logic := '0';
    signal s_si : std_logic := '0';

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

    -- loopback axis
    signal lb_axis_tdata  : std_logic_vector(7 downto 0) := (others => '0');
    signal lb_axis_tvalid : std_logic := '0';
    signal lb_axis_tready : std_logic := '0';
    signal lb_axis_tlast  : std_logic := '0';
        
    -- test data
    signal word_in  : unsigned(7 downto 0) := (others => '0');
    signal word_out : unsigned(7 downto 0) := (others => '0');
    signal expected_word : unsigned(7 downto 0) := (others => '0');
    signal TLAST_NOT_ASSERTED : std_logic := '0';
    signal INVALID_WORD_RECEIVED : std_logic := '0';

begin

------- INSTANCE 0 CLOCKS

    aclk_i0_gen : process
    begin
    	if(start) then
    		wait for aclk_period_i0/7;
    		start <= false; 
    	end if;
        aclk_i0 <= not aclk_i0;
        wait for aclk_period_i0/2;
    end process aclk_i0_gen;

    txclk_i0_gen : process
    begin
    	if(start) then
    		wait for txclk_period_i0/3;
		end if;
        txclk_i0 <= not txclk_i0;
        wait for txclk_period_i0/2;
    end process txclk_i0_gen;

    rxclk_i0_gen : process
    begin
    	if(start) then
    		wait for rxclk_period_i0/4;
		end if;
        rxclk_i0 <= not rxclk_i0;
        wait for rxclk_period_i0/2;
    end process rxclk_i0_gen;

------- INSTANCE 1 CLOCKS

    aclk_i1_gen : process
    begin
        aclk_i1 <= not aclk_i1;
        wait for aclk_period_i1/2;
    end process aclk_i1_gen;

    txclk_i1_gen : process
    begin
        txclk_i1 <= not txclk_i1;
        wait for txclk_period_i1/2;
    end process txclk_i1_gen;

    rxclk_i1_gen : process
    begin
        rxclk_i1 <= not rxclk_i1;
        wait for rxclk_period_i1/2;
    end process rxclk_i1_gen;

    reset_i1_gen : process
    begin
        aresetn_i1 <= '0';
        aresetn_i0 <= '0';
        wait for aclk_period_i1*5;
        aresetn_i1 <= '1';
        aresetn_i1 <= '0';
        wait for 1000 ms;
    end process reset_i1_gen;



	axistream_spw_lite_v1_0_inst_i0 : axistream_spw_lite_v1_0
	generic map (
		sysfreq             => sysfreq_i0,
		txclkfreq           => txclkfreq_i0,
		rximpl_fast         => rximpl_fast,
		rxchunk_fast        => rxchunk_fast,
		tximpl_fast         => tximpl_fast,
		rxfifosize_bits     => rxfifosize_bits,
		txfifosize_bits     => txfifosize_bits,
		txdivcnt            => txdivcnt
	)
	port map (
		aclk    => aclk_i0,
		aresetn => aresetn_i0,
		rx_clk  => rxclk_i0,
		tx_clk  => txclk_i0,

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

	axistream_spw_lite_v1_0_inst_i1 : axistream_spw_lite_v1_0
	generic map (
		sysfreq             => sysfreq_i1,
		txclkfreq           => txclkfreq_i1,
		rximpl_fast         => rximpl_fast,
		rxchunk_fast        => rxchunk_fast,
		tximpl_fast         => tximpl_fast,
		rxfifosize_bits     => rxfifosize_bits,
		txfifosize_bits     => txfifosize_bits,
		txdivcnt            => txdivcnt
	)
	port map (
		aclk  => aclk_i1,
		aresetn  => aresetn_i1,
		rx_clk   => rxclk_i1,
		tx_clk   => txclk_i1,

        spw_di => s_do,
        spw_si => s_so,
        spw_do => s_di,
        spw_so => s_si,

        s_axis_tdata  => lb_axis_tdata,
        s_axis_tvalid => lb_axis_tvalid,
        s_axis_tready => lb_axis_tready,
        s_axis_tlast  => lb_axis_tlast,

        m_axis_tdata  => lb_axis_tdata,
        m_axis_tvalid => lb_axis_tvalid,
        m_axis_tready => lb_axis_tready,
        m_axis_tlast  => lb_axis_tlast,

        rx_error      => rx_error
	);

	s_axis_tvalid <= '1';
	m_axis_tready <= '1';
	s_axis_tdata  <= std_logic_vector(word_in);
	s_axis_tlast  <= '1' when word_in = to_unsigned(255, 8) else '0';
	word_out      <= unsigned(m_axis_tdata) when m_axis_tvalid = '1' else word_out;


	process(aclk_i0)
	begin
	if(rising_edge(aclk_i0)) then
		if(m_axis_tvalid = '1') then
			expected_word <= expected_word + 1;
			if(unsigned(m_axis_tdata) /= expected_word) then
				report "INVALID WORD RECEIVED" severity warning;
				INVALID_WORD_RECEIVED <= '1';
			end if;
			if(unsigned(m_axis_tdata) = 255 and m_axis_tlast = '0' and m_axis_tvalid = '1') then
				report "TLAST NOT ASSERTED" severity warning;
				TLAST_NOT_ASSERTED <= '1';
			end if;
		end if;
	end if;
	end process;

	process(aclk_i0)
	begin
	if(rising_edge(aclk_i0)) then
		if(s_axis_tready = '1') then
			word_in <= word_in + 1;
		end if;
	end if;
	end process;


end arch_imp;
