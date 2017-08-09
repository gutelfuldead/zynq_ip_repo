library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity axis_to_spi_to_spi_to_axis_tb is
end axis_to_spi_to_spi_to_axis_tb;


architecture tb of axis_to_spi_to_spi_to_axis_tb is

	component axis_to_spi_v1_0 is
		generic (
	    INPUT_CLK_MHZ : integer := 100;
	    SPI_CLK_MHZ   : integer := 10;
	    DATA_WIDTH    : integer := 8
		);
		port (
		sclk : out STD_LOGIC;
	    sclk_en : out STD_LOGIC;
	    mosi : out STD_LOGIC;
	    S_AXIS_ACLK	: in std_logic;
	    S_AXIS_ARESETN    : in std_logic;
	    S_AXIS_TREADY    : out std_logic;
	    S_AXIS_TDATA    : in std_logic_vector(DATA_WIDTH-1 downto 0);
	    S_AXIS_TVALID    : in std_logic
		);
	end component axis_to_spi_v1_0;

	component spi_to_axis_v1_0 is
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
	end component spi_to_axis_v1_0;

	constant DSIZE  : integer := 8;
	signal sclk, sclk_en, mosi : std_logic := '0';
	signal clk, aresetn : std_logic := '0';
	signal S_AXIS_TREADY, S_AXIS_TVALID : std_logic := '0';
	signal M_AXIS_TVALID, M_AXIS_TREADY : std_logic := '0';
	signal S_AXIS_TDATA, M_AXIS_TDATA : std_logic_vector(DSIZE-1 downto 0) := (others => '0');
    constant clk_period : time := 10 ns; -- 100 MHz clock

    signal dout : std_logic_vector(DSIZE-1 downto 0) := (others => '0');

begin

	axis_to_spi_inst : axis_to_spi_v1_0
	port map (
		sclk => sclk,
		sclk_en => sclk_en,
		mosi => mosi,
		S_AXIS_ACLK => clk,
		S_AXIS_ARESETN => aresetn,
		S_AXIS_TVALID => S_AXIS_TVALID,
		S_AXIS_TREADY => S_AXIS_TREADY,
		S_AXIS_TDATA => S_AXIS_TDATA
		);

	spi_to_axis_inst : spi_to_axis_v1_0
	port map(
		sclk => sclk,
		sclk_en => sclk_en,
		mosi => mosi,
		M_AXIS_ACLK => clk,
		M_AXIS_ARESETN => aresetn,
		M_AXIS_TVALID => M_AXIS_TVALID,
		M_AXIS_TREADY => M_AXIS_TREADY,
		M_AXIS_TDATA  => M_AXIS_TDATA
		);

	clk_gen : process
    begin
        clk <= '1';
        wait for clk_period;
        clk <= '0';
        wait for clk_period;
    end process clk_gen;
    
    rst : process(clk)
        constant RESET_CYCLES : integer := 200000;
        variable cnt : integer range 0 to RESET_CYCLES;
    begin
    if(rising_edge(clk)) then
        if(cnt = RESET_CYCLES) then
            cnt := 0;
            aresetn <= '0';
        else
            aresetn <= '1';
            cnt := cnt + 1;
        end if;
    end if;
    end process rst;

    axis_to_spi_tb : process(clk)
    	type states is (ST_IDLE, ST_SYNC);
    	variable fsm : states := ST_IDLE;
    	variable cnt : integer := 0;
    begin
    case(fsm) is
    	when ST_IDLE =>
			S_AXIS_TVALID <= '1';
			S_AXIS_TDATA  <= std_logic_vector(to_unsigned(cnt, M_AXIS_TDATA'length));
			fsm := ST_SYNC;

    	when ST_SYNC =>
    		if(S_AXIS_TREADY = '1') then
    			cnt := cnt + 1;
    			S_AXIS_TVALID <= '0';
    			S_AXIS_TDATA <= (others => '0');
    			fsm := ST_IDLE;
    		end if;

    end case;
    end process axis_to_spi_tb;

    spi_to_axis_tb : process(clk)
    	type states is (ST_IDLE, ST_SYNC);
    	variable fsm : states := ST_IDLE;
    begin
    case(fsm) is
    	when ST_IDLE =>
    		if(M_AXIS_TVALID = '1') then
    			M_AXIS_TREADY <= '1';
    			dout <= M_AXIS_TDATA;
    			fsm := ST_SYNC;
			end if;

    	when ST_SYNC =>
    		M_AXIS_TREADY <= '0';
    		fsm := ST_IDLE;

    end case;
    end process spi_to_axis_tb;




end tb;