library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity interleaver_data_buffer_v1_0 is
	generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 8;
		C_US_AXIS_TDATA_WIDTH	: integer	:= 8;
		C_M_AXIS_TDATA_WIDTH	: integer	:= 8
	);
	port (
	AXIS_ACLK   : in std_logic;
	AXIS_ARESETN : in std_logic;
	-- data slave interface
	S_AXIS_TREADY	: out std_logic;
	S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	S_AXIS_TVALID	: in std_logic;
	-- user data slave interface
	US_AXIS_TREADY	: out std_logic;
	US_AXIS_TDATA	: in std_logic_vector(C_US_AXIS_TDATA_WIDTH-1 downto 0);
	US_AXIS_TVALID	: in std_logic;
	-- master interface
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TREADY : in std_logic
	);
end interleaver_data_buffer_v1_0;

architecture arch_imp of interleaver_data_buffer_v1_0 is

	-- data slave signals
	signal s_user_rdy    : std_logic := '0';
	signal s_user_dvalid : std_logic := '0';
	signal s_user_data   : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	signal s_axis_rdy    : std_logic := '0';

	-- user data slave signals
	signal us_user_rdy    : std_logic := '0';
	signal us_user_dvalid : std_logic := '0';
	signal us_user_data   : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	signal us_axis_rdy    : std_logic := '0';

	-- data master signals
	signal m_user_din    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal m_user_dvalid : std_logic := '0';
	signal m_user_txdone : std_logic := '0';
	signal m_axis_rdy    : std_logic := '0';

	-- internal flags for synchronizing the multiple interfaces
	constant RDY_BIT    : integer := 1;
	signal us_rx_done   : std_logic := '0';
	signal us_rx_cont   : std_logic := '0';
	signal us_ready_bit : std_logic := '0';
	signal tx_valid     : std_logic := '0';

begin

-- interface to take channel data from interleaver core
axi_slave_stream_impl : axi_slave_stream
generic map ( C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH )
port map(
	user_rdy       => s_user_rdy,
	user_dvalid    => s_user_dvalid,
	user_data      => s_user_data,
	axis_rdy       => s_axis_rdy,
	axis_last      => open,
	S_AXIS_ACLK    => AXIS_ACLK,
	S_AXIS_ARESETN => AXIS_ARESETN,
	S_AXIS_TREADY  => S_AXIS_TREADY,
	S_AXIS_TDATA   => S_AXIS_TDATA,
	S_AXIS_TVALID  => S_AXIS_TVALID,
	S_AXIS_TSTRB   => (others => '0'),
	S_AXIS_TLAST   => '0'
	);

-- interface to take user data (rdy sig) from interleaver core
axi_slave_stream_user_data_impl : axi_slave_stream
generic map ( C_S_AXIS_TDATA_WIDTH => C_US_AXIS_TDATA_WIDTH )
port map(
	user_rdy       => us_user_rdy,
	user_dvalid    => us_user_dvalid,
	user_data      => us_user_data,
	axis_rdy       => us_axis_rdy,
	axis_last      => open,
	S_AXIS_ACLK    => AXIS_ACLK,
	S_AXIS_ARESETN => AXIS_ARESETN,
	S_AXIS_TREADY  => US_AXIS_TREADY,
	S_AXIS_TDATA   => US_AXIS_TDATA,
	S_AXIS_TVALID  => US_AXIS_TVALID,
	S_AXIS_TSTRB   => (others => '0'),
	S_AXIS_TLAST   => '0'
	);

-- interface to pass valid data to downstream module
axi_master_stream_impl : axi_master_stream
generic map ( C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH )
port map(
	user_din       => m_user_din,
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

--------------------------------------------------------------
-- Reads data on the slave data line and synchronizes with the 
-- data read in the interleaver_user_read process. Determines 
-- if data is valid or invalid. If the data is valid it is 
-- passed to the master interface. If the data is invalid it
-- is ignored.
--------------------------------------------------------------
-- uses us_rx_cont to inform user data iface to take new data
-- uses tx_valid to inform master interface to pass recovered
--------------------------------------------------------------
interleaver_read : process(AXIS_ACLK, AXIS_ARESETN)
	type fsm_states is (ST_IDLE, ST_READ, ST_SYNC);
	variable fsm : fsm_states := ST_IDLE;
begin
if(AXIS_ARESETN = '0') then
	fsm := ST_IDLE;
	us_rx_cont <= '0';
	s_user_rdy <= '0';
	tx_valid   <= '0';
elsif(rising_edge(AXIS_ACLK)) then
	case(fsm) is
	when ST_IDLE =>
		us_rx_cont <= '0';
		tx_valid <= '0';
		if(s_axis_rdy = '1') then
			s_user_rdy <= '1';
			fsm := ST_READ;
		end if;

	when ST_READ =>
		s_user_rdy <= '0';
		if(s_user_dvalid = '1') then
			fsm := ST_SYNC;
		end if;

	when ST_SYNC =>
		if(us_rx_done = '1') then
			fsm := ST_IDLE;
			us_rx_cont <= '1';
			if(us_ready_bit = '1') then
				tx_valid <= '1';
				m_user_din <= s_user_data;
			end if;
		end if;

	when others =>
		fsm := ST_IDLE;
	end case;
end if;
end process interleaver_read;

------------------------------------------------------------------
-- Reads data on the slave user data line to monitor if the ready
-- flag is high or low. Passes this information to the
-- interleaver_read process. Waits for the interleaver_read process
-- to assert it has received the data and to move to the next 
-- transaction
------------------------------------------------------------------
-- uses us_rx_done to inform the interleaver_read process that it
-- 	  has received new data
------------------------------------------------------------------
interleaver_user_read : process(AXIS_ACLK, AXIS_ARESETN)
	type fsm_states is (ST_IDLE, ST_READ, ST_SYNC);
	variable fsm : fsm_states := ST_IDLE;
begin
if(AXIS_ARESETN = '0') then
	fsm := ST_IDLE;
	us_rx_done <= '0';
	us_user_rdy <= '0';
elsif(rising_edge(AXIS_ACLK)) then
	case(fsm) is
	when ST_IDLE =>
		us_rx_done <= '0';
		if(us_axis_rdy = '1') then
			us_user_rdy <= '1';
			fsm := ST_READ;
		end if;

	when ST_READ =>
		us_user_rdy <= '0';
		if(us_user_dvalid = '1') then
			fsm := ST_SYNC;
			us_rx_done <= '1';
			us_ready_bit <= us_user_data(RDY_BIT);
		end if;

	when ST_SYNC =>
		if(us_rx_cont = '1') then
			fsm := ST_IDLE;
		end if;

	when others =>
		fsm := ST_IDLE;
	end case;
end if;
end process interleaver_user_read;

----------------------------------------------------
-- Waits for assertion from interleaver_read process
-- to begin a transfer of valid data to the 
-- downstream module (tx_valid).
----------------------------------------------------
interleaver_write : process(AXIS_ACLK, AXIS_ARESETN)
	type fsm_states is (ST_IDLE, ST_WRITE);
	variable fsm : fsm_states := ST_IDLE;
begin
if(AXIS_ARESETN = '0') then
	fsm := ST_IDLE;
	m_user_dvalid <= '0';
elsif(rising_edge(AXIS_ACLK)) then
	case(fsm) is
	when ST_IDLE =>
		if(m_axis_rdy = '1' and tx_valid = '1') then
			m_user_dvalid <= '1';
			fsm := ST_WRITE;
		end if;

	when ST_WRITE =>
		m_user_dvalid <= '0';
		if(m_user_txdone = '1') then
			fsm := ST_IDLE;
		end if;

	when others =>
		fsm := ST_IDLE;
	end case;
end if;
end process interleaver_write;

end arch_imp;
