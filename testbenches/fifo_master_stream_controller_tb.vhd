library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

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
    signal doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
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
    signal fifo_ready     : std_logic;
    signal fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
	constant clk_period : time := 10 ns; -- 100 MHz clock

    constant BRAM_MAX_SZ : integer := 1023;
    constant READ_CNT  : integer := 0;
    constant DEADBEEF : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := x"DEADBEEF";  
    type bram_array_type is array (0 to BRAM_MAX_SZ) of std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal bram_array : bram_array_type;

    constant RESET_WAIT : integer := 3000;
    constant WRITE_WAIT : integer := 1;
    constant AXIS_WAIT  : integer := 1;
begin    

	DUT : FIFO_MASTER_STREAM_CONTROLLER
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
        fifo_ready      => fifo_ready,
        fifo_full       => fifo_full,
        fifo_empty      => fifo_empty,
        fifo_occupancy  => fifo_occupancy
        );

    clkEn <= '1';
        
	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process clk_process;

    rst_proc : process(clk)
       variable cnt : integer range 0 to RESET_WAIT := RESET_WAIT;
    begin
       if(rising_edge(clk)) then
           if (cnt = RESET_WAIT) then
               reset <= '1';
               cnt := 0;
           else
               reset <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

    write_test : process(clk, reset)
        variable cnt : integer range 0 to WRITE_WAIT := 0;
        variable write_asserted : std_logic := '0';
        variable addr : integer := 0;
    begin
    if(reset = '1') then
        for i in 0 to BRAM_MAX_SZ loop
            bram_array(i) <= std_logic_vector(to_unsigned(10 + i, BRAM_DATA_WIDTH));
        end loop;
        cnt := 0;
        write_asserted := '0';
        fifo_write_en <= '0';
    elsif(rising_edge(clk)) then
        if(fifo_full = '0' and fifo_ready = '1' and write_asserted = '0') then
            fifo_din <= bram_array(addr); 
            --fifo_din <= std_logic_vector(to_unsigned(data_val,BRAM_DATA_WIDTH));
            fifo_write_en <= '1';
            write_asserted := '1';
        elsif(write_asserted = '1') then
            fifo_write_en <= '0';
            if(cnt = WRITE_WAIT) then
                write_asserted := '0';
                cnt := 0;
                addr := addr + 1;
            else
                cnt := cnt + 1;
            end if;
        end if;
    end if;
    end process write_test;

    axis_test : process(clk, reset)
        variable cnt : integer range 0 to AXIS_WAIT;
        variable ready_asserted : std_logic := '0';
    begin
    if(reset = '1') then
        cnt := 0;
        M_AXIS_TREADY <= '0';
        ready_asserted := '1';
    elsif(rising_edge(clk)) then
        doutb <= bram_array(to_integer(unsigned(addrb)));
        if(M_AXIS_TVALID = '1' and ready_asserted = '0') then
            M_AXIS_TREADY <= '1';
            ready_asserted := '1';
        elsif(ready_asserted = '1') then
            M_AXIS_TREADY <= '0';
            if(cnt = AXIS_WAIT) then
                cnt := 0;
                ready_asserted := '0';
            else
                cnt := cnt + 1;
            end if;
        end if;
    end if;
    end process axis_test;



end tb;