library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

Library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use unimacro.Vcomponents.all;

entity fifo_master_stream_controller_tb is
--port();
end fifo_master_stream_controller_tb;

architecture tb of fifo_master_stream_controller_tb is

    constant BRAM_ADDR_WIDTH  : integer := 10;
    constant BRAM_DATA_WIDTH  : integer := 32;
	constant C_M_AXIS_TDATA_WIDTH : integer := 32;

	signal addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal ena   : STD_LOGIC;
    signal wea   : STD_LOGIC;
    signal clka  : std_logic;
    signal rsta  : std_logic;        
    -- BRAM read port lines
    signal addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal sig_doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal enb   : STD_LOGIC;
    signal clkb  : std_logic;
    signal rstb  : std_logic;
     -- AXI Master Stream Ports
    signal M_AXIS_TVALID   : std_logic;
    signal M_AXIS_TDATA    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    signal M_AXIS_TSTRB    : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    signal M_AXIS_TLAST    : std_logic;
    signal M_AXIS_TREADY   : std_logic;
     -- fifo control lines
    signal clk            : std_logic;
    signal clkEn          : std_logic;
    signal reset          : std_logic;
    signal fifo_din       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal fifo_write_en  : std_logic;
    signal fifo_full      : std_logic;
    signal fifo_empty     : std_logic;
    signal fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
	constant clk_period : time := 10 ns; -- 100 MHz clock

    signal new_wea : std_logic_vector(3 downto 0);

begin

    update_wea : process(clk)
    begin
    if(rising_edge(clk)) then
        if(wea = '1') then
            new_wea <= (others => '1');
        else
            new_wea <= (others => '0');
        end if;
    end if;
    end process update_wea;
    

	DUT : FIFO_MASTER_STREAM_CONTROLLER
--    generic map(
--        BRAM_ADDR_WIDTH  => BRAM_ADDR_WIDTH,
--        BRAM_DATA_WIDTH  => BRAM_DATA_WIDTH,
--        C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH)
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
        doutb => sig_doutb,
        enb   => enb,
        clkb  => clkb,
        rstb  => rstb,

        -- AXI Master Stream Ports
        M_AXIS_ACLK     => clk,
        M_AXIS_ARESETN  => not reset,
        M_AXIS_TVALID   => M_AXIS_TVALID,
        M_AXIS_TDATA    => M_AXIS_TDATA,
        M_AXIS_TSTRB    => M_AXIS_TSTRB,
        M_AXIS_TLAST    => M_AXIS_TLAST,
        M_AXIS_TREADY   => M_AXIS_TREADY,

        -- control lines
        clk             => clk,
        clkEn           => clkEn,
        reset           => reset,
        fifo_din        => fifo_din,
        fifo_write_en   => fifo_write_en,
        fifo_full       => fifo_full,
        fifo_empty      => fifo_empty,
        fifo_occupancy  => fifo_occupancy
        );
        
--    BRAM_SDP_MACRO_inst : BRAM_SDP_MACRO
--    generic map(
--        BRAM_SIZE => "36kb",
--        DEVICE    => "7SERIES",
--        WRITE_WIDTH => BRAM_DATA_WIDTH,
--        READ_WIDTH  => BRAM_DATA_WIDTH,
--        DO_REG => 0,
--        INIT_FILE => "NONE",
--        SIM_COLLISION_CHECK => "ALL",
--        SRVAL => X"000000000000000000",
--        WRITE_MODE => "READ_FIRST",
--        INIT => X"000000000000000000",
--        INIT_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
--        INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
--        INIT_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
--        INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000")
--    port map(
--        DO => sig_doutb,
--        DI => dina,
--        RDADDR => addrb,
--        RDCLK => clk,
--        RDEN => enb,
--        RST  => rstb,
--        REGCE => '0',
--        WE => new_wea,
--        WRADDR => addra,
--        WRCLK => clk,
--        WREN => ena
--    );

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
        M_AXIS_TREADY <= '0';
        sig_doutb <= (others => '1');
		wait for clk_period*4;
		reset <= '0';
		wait for clk_period;
		fifo_din <= (others => '1');
		fifo_write_en <= '1';
		wait for clk_period;
		fifo_write_en <= '0';
		wait for clk_period*10;
		fifo_write_en <= '1';
		wait for clk_period;
		fifo_write_en <= '0';
		wait for clk_period*10;
		fifo_write_en <= '1';
		wait for clk_period;
		fifo_write_en <= '0';
		wait for clk_period*3;
--		wait for M_AXIS_TVALID = '1';
		M_AXIS_TREADY <= '1';
        wait for clk_period;
        M_AXIS_TREADY <= '0';
        wait for clk_period*10;
        M_AXIS_TREADY <= '1';
        wait for clk_period;
        M_AXIS_TREADY <= '0';
        wait for clk_period*10;

	end process;


end tb;