library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

library work;
use work.generic_pkg.all;

entity axis_data_buf_v1_0 is
	generic (
       BRAM_ADDR_WIDTH  : integer := 10;
       BRAM_DATA_WIDTH  : integer := 32
	);
	port (
		-- BRAM write port lines
		addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
		dina  : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
		ena   : out STD_LOGIC;
		wea   : out STD_LOGIC;
		clka  : out std_logic;
		rsta  : out std_logic;

		-- BRAM read port lines
		addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
		doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
		enb   : out STD_LOGIC;
		clkb  : out std_logic;
		rstb  : out std_logic;

		-- general AXIS Lines
		AXIS_ACLK    : in std_logic;
		AXIS_ARESETN : in std_logic;

		-- AXIS Slave Lines
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
		S_AXIS_TVALID	: in std_logic;

		-- AXIS Master Lines
		M_AXIS_TVALID : out std_logic;
		M_AXIS_TDATA  : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
		M_AXIS_TREADY : in std_logic
	);
end axis_data_buf_v1_0;

architecture arch_imp of axis_data_buf_v1_0 is
	
	-- bram controller logic
	signal s_clk_buf, reset : std_logic := '0';
	signal fifo_clkEn, fifo_write_en, fifo_read_en, fifo_dvalid, 
		fifo_full, fifo_empty, fifo_write_ready, fifo_read_ready : std_logic := '0';
	signal fifo_din, fifo_dout : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
	signal fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

	-- axis master logic
	signal m_user_dvalid, m_user_txdone, m_axis_rdy : std_logic := '0';
	signal m_user_din : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

	--axis slave logic 
	signal s_user_rdy, s_user_dvalid, s_axis_rdy : std_logic := '0';
	signal s_user_data : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');

begin

	reset <= not AXIS_ARESETN;
	fifo_clkEn <= '1' when (reset = '0') else '0';

    BUFR_inst : BUFR
    generic map(
        BUFR_DIVIDE => "BYPASS",
        SIM_DEVICE => "7SERIES"
    )
    port map(
        I => AXIS_ACLK,
        CE => '1',
        CLR => '0',
        O => s_clk_buf
    );
    clka <= s_clk_buf;
    clkb <= s_clk_buf;

	bram_fifo_controller_inst : BRAM_FIFO_CONTROLLER
	generic map(
		BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
		BRAM_DATA_WIDTH => BRAM_DATA_WIDTH
		)
	port map(
		addra => addra,
		dina  => dina,
		ena   => ena,
		wea   => wea,
		clka  => open,
		rsta  => rsta,
		addrb => addrb,
		doutb => doutb,
		enb   => enb,
		clkb  => open,
		rstb  => rstb,

		clk         => AXIS_ACLK,
		clkEn       => fifo_clkEn,
		write_en    => fifo_write_en,
		read_en     => fifo_read_en,
		reset       => reset,
		write_ready => fifo_write_ready,
		read_ready  => fifo_read_ready,
		din         => fifo_din,
		dout        => fifo_dout,
		dvalid      => fifo_dvalid,
		full        => fifo_full,
		empty       => fifo_empty,
		occupancy   => fifo_occupancy
		);

	axi_slave_stream_inst : AXI_SLAVE_STREAM
	generic map( C_S_AXIS_TDATA_WIDTH => BRAM_DATA_WIDTH)
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
		S_AXIS_TSTRB   => (others => '1'),
		S_AXIS_TLAST   => '0',
		S_AXIS_TVALID  => S_AXIS_TVALID
		);

	axi_master_stream_inst : AXI_MASTER_STREAM
	generic map( C_M_AXIS_TDATA_WIDTH => BRAM_DATA_WIDTH)
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

	slave_stream_controller : process(AXIS_ACLK, reset)
		type states is (ST_IDLE, ST_WRITE, ST_SYNC);
		variable fsm : states := ST_IDLE;
	begin
	if(reset = '1') then
		s_user_rdy    <= '0';
		fifo_write_en <= '0';
		fifo_din      <= (others => '0');
		fifo_write_en <= '0';
		fsm           := ST_IDLE;
	elsif(rising_edge(AXIS_ACLK)) then
	case (fsm) is
		when ST_IDLE =>
			if(s_axis_rdy = '1' and fifo_write_ready = '1') then
				s_user_rdy <= '1';
				fsm        := ST_WRITE;
			end if;

		when ST_WRITE =>
			s_user_rdy <= '0';
			if(s_user_dvalid = '1') then
				fifo_din <= s_user_data;
				fifo_write_en <= '1';
				fsm := ST_SYNC;
			end if;

		when ST_SYNC =>
			fifo_write_en <= '0';
			fsm := ST_IDLE;

		when others =>
			fsm := ST_IDLE;
	end case;
	end if;
	end process slave_stream_controller;

	master_stream_controller : process(AXIS_ACLK, reset)
		type states is (ST_IDLE, ST_READ, ST_SYNC);
		variable fsm : states := ST_IDLE;
	begin
	if(reset = '1') then
		fsm := ST_IDLE;
		fifo_read_en  <= '0';
		m_user_dvalid <= '0';
		m_user_din    <= (others => '0');
	elsif(rising_edge(AXIS_ACLK)) then
	case (fsm) is
		when ST_IDLE =>
			if(fifo_read_ready = '1' and m_axis_rdy = '1') then
				fifo_read_en <= '1';
				fsm := ST_READ;
			end if;

		when ST_READ =>
			fifo_read_en <= '0';
			if(fifo_dvalid = '1') then
				m_user_din <= fifo_dout;
				m_user_dvalid <= '1';
				fsm := ST_SYNC;
			end if;

		when ST_SYNC =>
			m_user_dvalid <= '0';
			fsm := ST_IDLE;

		when others =>
			fsm := ST_IDLE;

	end case;
	end if;
	end process master_stream_controller;


end arch_imp;
