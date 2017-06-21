library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity fifo_slave_stream_controller_tb is
--port();
end fifo_slave_stream_controller_tb;

architecture tb of fifo_slave_stream_controller_tb is

    constant BRAM_ADDR_WIDTH  : integer := 10;
    constant BRAM_DATA_WIDTH  : integer := 32;
    constant C_S_AXIS_TDATA_WIDTH    : integer   := 32;

	signal addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal ena   : STD_LOGIC;
    signal wea   : STD_LOGIC;
    signal clka  : std_logic;
    signal rsta  : std_logic;        
    -- BRAM read port lines
    signal addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal enb   : STD_LOGIC;
    signal clkb  : std_logic;
    signal rstb  : std_logic;
     -- AXI Master Stream Ports
    signal S_AXIS_ARESETN  : std_logic;
    signal S_AXIS_TREADY   : std_logic;
    signal S_AXIS_TDATA    : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    signal S_AXIS_TSTRB    : std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    signal S_AXIS_TLAST    : std_logic;
    signal S_AXIS_TVALID   : std_logic;
     -- fifo control lines
    signal clk            : std_logic;
    signal clkEn          : std_logic;
    signal reset          : std_logic;
    signal fifo_dout      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal fifo_read_en   : std_logic;
    signal fifo_full      : std_logic;
    signal fifo_empty     : std_logic;
    signal fifo_dvalid    : std_logic;
    signal fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
	constant clk_period : time := 10 ns; -- 100 MHz clock

begin

    DUT : FIFO_SLAVE_STREAM_CONTROLLER
    port map (
        -- BRAM write port lines
        addra => addra,
        dina  => dina,
        ena   => ena,
        wea   => wea,
        clka  => clka,
        rsta  => rsta,
        
        -- BRAM read port lines
        addrb => addrb,
        doutb => doutb,
        enb   => enb,
        clkb  => clkb,
        rstb  => rstb,

        -- AXIS Slave Stream Ports
        S_AXIS_ACLK    => clk,
        S_AXIS_ARESETN => S_AXIS_ARESETN,
        S_AXIS_TREADY  => S_AXIS_TREADY,
        S_AXIS_TDATA   => S_AXIS_TDATA,
        S_AXIS_TSTRB   => S_AXIS_TSTRB,
        S_AXIS_TLAST   => S_AXIS_TLAST,
        S_AXIS_TVALID  => S_AXIS_TVALID,

        -- fifo control lines
        clk            => clk,
        clkEn          => clkEn,
        reset          => reset,
        fifo_full      => fifo_full,
        fifo_empty     => fifo_empty,
        fifo_occupancy => fifo_occupancy,
        fifo_read_en   => fifo_read_en,
        fifo_dout      => fifo_dout,
        fifo_dvalid    => fifo_dvalid
        );    

    S_AXIS_ARESETN <= not reset;

	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process clk_process;

	tb : process
	begin
		clkEn <= '1';
		reset <= '1';
        S_AXIS_TVALID <= '0';
        S_AXIS_TDATA  <= (others => '1');
		wait for clk_period*4;
		reset <= '0';
		wait for clk_period;
        S_AXIS_TVALID <= '1';
        wait for clk_period*10;
        S_AXIS_TVALID <= '0';
        wait for clk_period*10;
	end process;


end tb;