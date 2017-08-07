library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity spi_to_axis_v1_0 is
	generic (
        INPUT_CLK_MHZ : integer := 100;
        SPI_CLK_MHZ   : integer := 10;
        DSIZE         : integer := 8
	);
	port (
	sclk : in STD_LOGIC;
	sclk_en : in STD_LOGIC;
	mosi : in STD_LOGIC;
    M_AXIS_ACLK : in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(DSIZE-1 downto 0);
    M_AXIS_TREADY : in std_logic
	);
end spi_to_axis_v1_0;

architecture arch_imp of spi_to_axis_v1_0 is

	-- AXI-Stream Master Signals
	signal user_din    : std_logic_vector(DSIZE-1 downto 0) := (others => '0');
	signal user_dvalid : std_logic := '0'; 
	signal user_txdone : std_logic := '0';
	signal axis_rdy    : std_logic := '0';
	signal axis_last   : std_logic := '0';

	-- SPI Slave Signals
	signal spi_dout   : std_logic_vector(DSIZE-1 downto 0) := (others => '0');
	signal spi_dvalid : std_logic := '0';

	-- Control Signals
	signal reset : std_logic := '0';
	signal new_word : std_logic_vector(DSIZE-1 downto 0) := (others => '0');
	signal new_word_rdy, new_word_accessed : std_logic := '0';

begin

	reset <= not M_AXIS_ARESETN;

	axi_master_inst : axi_master_stream
	generic map ( C_M_AXIS_TDATA_WIDTH  => DSIZE )
	port map (
	user_din        => user_din,
	user_dvalid     => user_dvalid,
	user_txdone     => user_txdone,
	axis_rdy        => axis_rdy,
	axis_last       => '0',
	M_AXIS_ACLK     => M_AXIS_ACLK,
	M_AXIS_ARESETN  => M_AXIS_ARESETN,
	M_AXIS_TVALID   => M_AXIS_TVALID,
	M_AXIS_TDATA    => M_AXIS_TDATA,
	M_AXIS_TSTRB    => open,
	M_AXIS_TLAST    => open,
	M_AXIS_TREADY   => M_AXIS_TREADY
	);

	spi_slave_inst : spi_slave
	generic map (
	INPUT_CLK_MHZ => INPUT_CLK_MHZ,
	SPI_CLK_MHZ   => SPI_CLK_MHZ,
	DSIZE         => DSIZE
	)
	Port map ( 
	clk      => M_AXIS_ACLK,
	reset    => reset,
	sclk     => sclk,
	sclk_en  => sclk_en,
	mosi     => mosi,
	dout     => spi_dout,
	dvalid   => spi_dvalid 
	);

	spi_read : process(M_AXIS_ACLK, reset)
		type states is (ST_IDLE, ST_SYNC);
		variable fsm : states := ST_IDLE;
	begin
	if(reset = '1') then
		fsm := ST_IDLE;
		new_word <= (others => '0');
		new_word_rdy <= '0';
	elsif(rising_edge(M_AXIS_ACLK)) then
	case(fsm) is
	
		when ST_IDLE =>
			if(spi_dvalid = '1') then
				new_word <= spi_dout;
				new_word_rdy <= '1';
				fsm := ST_SYNC;
			end if;

		when ST_SYNC =>
			if(new_word_accessed = '1') then
				new_word_rdy <= '0';
				fsm := ST_IDLE;
			end if;

		when others => 
			fsm := ST_IDLE;

	end case;
	end if;
	end process spi_read;

	axi_write : process(M_AXIS_ACLK, reset)
		type states is (ST_IDLE, ST_ACTIVE, ST_WAIT);
		variable fsm : states := ST_IDLE;
	begin
	if(reset = '1') then
		fsm := ST_IDLE;
		new_word_accessed <= '0';
	elsif(rising_edge(M_AXIS_ACLK)) then
	case(fsm) is
	
		when ST_IDLE =>
			if(new_word_rdy = '1') then
				new_word_accessed <= '1';
				user_din <= new_word;
				fsm := ST_ACTIVE;
			end if;

		when ST_ACTIVE =>
			new_word_accessed <= '0';
			if(axis_rdy = '1') then
				user_dvalid <= '1';
				fsm := ST_WAIT;
			end if;

		when ST_WAIT =>
			user_dvalid <= '0';
			if(user_txdone = '1') then
				fsm := ST_IDLE;
			end if;

		when others =>
			fsm := ST_IDLE;
	end case;
	end if;
	end process axi_write;



end arch_imp;
