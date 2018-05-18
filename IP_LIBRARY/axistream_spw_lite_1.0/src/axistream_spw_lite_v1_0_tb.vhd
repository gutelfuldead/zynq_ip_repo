library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.spwpkg.all;

entity axistream_spw_lite_v1_0_tb is
	generic (
		sysfreq : real := 100e6;
		txclkfreq : real := 0.0;
		rximpl : spw_implementation_type := impl_generic; 
		rxchunk_fast : integer range 1 to 4 := 1;
		tximpl : spw_implementation_type := impl_generic; 
		rxfifosize_bits : integer range 6 to 14 := 11; -- 11 (2 kByte)
		txfifosize_bits : integer range 2 to 14 := 11; -- 11 (2 kByte)
		txdivcnt : std_logic_vector(7 downto 0) := 4;
		debug_loopback_mode : boolean := false
	);
end axistream_spw_lite_v1_0_tb;

architecture arch_imp of axistream_spw_lite_v1_0_tb is

	-- control signals
	signal aclk    : std_logic := '0';
	signal rx_clk  : std_logic := '0';
	signal tx_clk  : std_logic := '0';
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
    signal test_counter  : unsigned(7 downto 0) := (others => '0');

begin

	axistream_spw_lite_v1_0_inst : axistream_spw_lite_v1_0
	generic map (
		sysfreq => sysfreq,
		txclkfreq => txclkfreq,
		rximpl => rximpl,
		rxchunk_fast => rxchunk_fast,
		tximpl => tximpl,
		rxfifosize_bits => rxfifosize_bits,
		txfifosize_bits => txfifosize_bits,
		txdivcnt => txdivcnt,
		debug_loopback_mode => debug_loopback_mode
	)
	port map (
		aclk    => aclk,
		aresetn => aresetn,
		rx_clk  => rx_clk,
		tx_clk  => tx_clk,

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
	end component axistream_spw_lite_v1_0;

	s_axis_tvalid <= '1';
	m_axis_tready <= '1';
	s_axis_tdata  <= std_logic_vector(test_counter);


	process(aclk)
	begin
	if(rising_edge(aclk)) then
		if(s_axis_tready = '1') then
			test_counter <= test_counter + 1;
		end if;
	end if;


end arch_imp;
