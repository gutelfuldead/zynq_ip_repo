library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity sid_output_buffer_v1_0 is
	generic (
		C_S_AXIS_TDATA_WIDTH	: integer	:= 8;
		C_M_AXIS_TDATA_WIDTH	: integer	:= 8
	);
	port (
	AXIS_ACLK   : in std_logic;
	AXIS_ARESETN : in std_logic;
	-- data slave interface
	S_AXIS_TREADY	: out std_logic;
	S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	S_AXIS_TVALID	: in std_logic;
	S_AXIS_TLAST    : in std_logic;
	S_AXIS_USR_RDY  : in std_logic;
	-- master interface
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TREADY : in std_logic;
    M_AXIS_TLAST  : out std_logic
	);
end sid_output_buffer_v1_0;

architecture arch_imp of sid_output_buffer_v1_0 is

	-- data slave signals
	signal s_user_rdy    : std_logic := '0';
	signal s_user_dvalid : std_logic := '0';
	signal s_user_drecv  : std_logic := '0';
	signal s_user_data   : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
	signal s_axis_rdy    : std_logic := '0';
	signal s_user_last  : std_logic := '0';

	-- data master signals
	signal m_user_din    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
	signal m_user_dvalid : std_logic := '0';
	signal m_user_txdone : std_logic := '0';
	signal m_axis_rdy    : std_logic := '0';
	signal m_user_last  : std_logic := '0';

	-- internal flags for synchronizing the multiple interfaces
	signal tx_valid     : std_logic := '0';
	signal tx_rdy       : std_logic := '0';

	component axi_slave_stream_interleaver is
	generic (
		-- Width of S_AXIS address bus.		
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- control ports
		-- top level is ready for new data
		user_rdy    : in std_logic;
		-- '1' when the user_data line has valid data
        user_dvalid : out std_logic;
        -- '1' when data is received (not necessarily valid)
        user_drecv  : out std_logic;
        -- the received transactional data
        user_data   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
        -- '1' when the interface is ready for a new transaction
    	axis_rdy    : out std_logic;
    	-- '1' when the last transaction is complete
    	axis_last   : out std_logic;
    	-- global AXI-Stream Slave ports
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_USR_RDY  : in std_logic;
		S_AXIS_TVALID	: in std_logic
	);
	end component axi_slave_stream_interleaver;

begin

-- interface to take channel data from interleaver core
axi_slave_stream_interleaver_inst : axi_slave_stream_interleaver
generic map ( C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH )
port map(
	user_rdy       => s_user_rdy,
	user_dvalid    => s_user_dvalid,
	user_drecv     => s_user_drecv,
	user_data      => s_user_data,
	axis_rdy       => s_axis_rdy,
	axis_last      => s_user_last,
	S_AXIS_ACLK    => AXIS_ACLK,
	S_AXIS_ARESETN => AXIS_ARESETN,
	S_AXIS_TREADY  => S_AXIS_TREADY,
	S_AXIS_TDATA   => S_AXIS_TDATA,
	S_AXIS_TVALID  => S_AXIS_TVALID,
	S_AXIS_USR_RDY => S_AXIS_USR_RDY,
	S_AXIS_TLAST   => S_AXIS_TLAST
	);

-- interface to pass valid data to downstream module
axi_master_stream_inst : axi_master_stream
generic map ( C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH )
port map(
	user_din       => m_user_din,
	user_dvalid    => m_user_dvalid,
	user_txdone    => m_user_txdone,
	axis_rdy       => m_axis_rdy,
	axis_last      => m_user_last,
	M_AXIS_ACLK    => AXIS_ACLK,
	M_AXIS_ARESETN => AXIS_ARESETN,
	M_AXIS_TVALID  => M_AXIS_TVALID,
	M_AXIS_TDATA   => M_AXIS_TDATA,
	M_AXIS_TSTRB   => open,
	M_AXIS_TLAST   => M_AXIS_TLAST,
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
	type fsm_states is (ST_IDLE, ST_READ);
	variable fsm : fsm_states := ST_IDLE;
begin
if(AXIS_ARESETN = '0') then
	fsm := ST_IDLE;
	s_user_rdy <= '0';
	tx_valid   <= '0';
elsif(rising_edge(AXIS_ACLK)) then
	case(fsm) is
	when ST_IDLE =>
		tx_valid <= '0';
		if(s_axis_rdy = '1' and tx_rdy = '1') then
			s_user_rdy <= '1';
			fsm := ST_READ;
		end if;

	when ST_READ =>
		s_user_rdy <= '0';
		if(s_user_drecv = '1') then
			fsm := ST_IDLE;
			if(s_user_dvalid = '1') then
				tx_valid <= '1';
				m_user_din <= s_user_data;
				m_user_last <= s_user_last;
			end if;
		end if;

	when others =>
		fsm := ST_IDLE;
	end case;
end if;
end process interleaver_read;

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
	tx_rdy <= '1';
elsif(rising_edge(AXIS_ACLK)) then
	case(fsm) is
	when ST_IDLE =>
		tx_rdy <= '1';
		if(m_axis_rdy = '1' and tx_valid = '1') then
			m_user_dvalid <= '1';
			fsm := ST_WRITE;
		end if;

	when ST_WRITE =>
		tx_rdy <= '0';
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
