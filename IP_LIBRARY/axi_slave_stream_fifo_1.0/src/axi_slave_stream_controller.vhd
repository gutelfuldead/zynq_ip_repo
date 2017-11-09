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
    signal S_AXIS_TVALID   : std_logic;
     -- fifo control lines
    signal clk            : std_logic;
    signal clkEn          : std_logic;
    signal reset          : std_logic;
    signal fifo_dout      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal fifo_read_en   : std_logic;
    signal fifo_full      : std_logic;
    signal fifo_empty     : std_logic;
    signal fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    signal axil_dvalid    : std_logic;
    signal axil_read_done : std_logic;
  	constant clk_period : time := 10 ns; -- 100 MHz clock

    constant BRAM_MAX_SZ : integer := 1023;
    constant READ_CNT  : integer := 0;
    constant DEADBEEF : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := x"DEADBEEF";  
    type bram_array_type is array (0 to BRAM_MAX_SZ) of std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal bram_array : bram_array_type;
	
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
        
        axil_dvalid => axil_dvalid,
        axil_read_done => axil_read_done,

        -- AXIS Slave Stream Ports
        S_AXIS_ACLK    => clk,
        S_AXIS_ARESETN => S_AXIS_ARESETN,
        S_AXIS_TREADY  => S_AXIS_TREADY,
        S_AXIS_TDATA   => S_AXIS_TDATA,
        S_AXIS_TVALID  => S_AXIS_TVALID,

        -- fifo control lines
        clk            => clk,
        clkEn          => clkEn,
        reset          => reset,
        fifo_full      => fifo_full,
        fifo_empty     => fifo_empty,
        fifo_occupancy => fifo_occupancy,
        fifo_read_en   => fifo_read_en,
        fifo_dout      => fifo_dout
        );    

    S_AXIS_ARESETN <= not reset;

	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process clk_process;
	
	rst_proc : process(clk)
	   constant rst_cnt : integer := 2000;
	   variable cnt : integer range 0 to rst_cnt := rst_cnt;
	begin
	   if(rising_edge(clk)) then
	       if (cnt = rst_cnt) then
	           reset <= '1';
	           cnt := 0;
           else
               reset <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;
      
   read_test : process(clk)
       variable cnt : integer range 0 to READ_CNT := 0;
       variable read_en_asserted : std_logic := '0';
       variable read_done_asserted : std_logic := '0';
   begin
   if(reset = '1') then
       read_en_asserted := '0';
       read_done_asserted := '0';
       fifo_read_en <= '0';
       cnt := 0;
       axil_read_done <= '0';
   elsif(rising_edge(clk)) then
       doutb <= bram_array(to_integer(unsigned(addrb)));
       if(fifo_empty = '0' and axil_dvalid = '0' and read_en_asserted = '0') then
           fifo_read_en <= '1';
           read_en_asserted := '1';
       elsif(read_en_asserted = '1') then
           fifo_read_en <= '0';
       end if;
       
       if(axil_dvalid = '1' and read_done_asserted = '0') then
           axil_read_done <= '1';
           read_done_asserted := '1';
           cnt := 0;
       elsif(read_done_asserted = '1') then
           axil_read_done <= '0';
           if(cnt = READ_CNT) then
               read_done_asserted := '0';
               read_en_asserted := '0';
           else
              cnt := cnt + 1;
           end if;
       end if;
           
   end if;
   end process read_test;
   
   
   valid_assert : process(clk)
       variable data_val : integer := 1;
       variable asserted : std_logic := '0';
       variable addr : integer := 0;
   begin
   if(reset = '1') then
       data_val := 1;
       asserted := '0';
       for i in 0 to BRAM_MAX_SZ loop
          bram_array(i) <= DEADBEEF;
       end loop;
   elsif(rising_edge(clk)) then
       if(asserted = '0') then
           S_AXIS_TVALID <= '1';
           asserted := '1';
           S_AXIS_TDATA <= std_logic_vector(to_unsigned(data_val, BRAM_DATA_WIDTH));
           bram_array(addr) <= std_logic_vector(to_unsigned(data_val,BRAM_DATA_WIDTH));
       elsif(S_AXIS_TREADY = '1') then
           S_AXIS_TVALID <= '0';
           S_AXIS_TDATA <= (others => '0');
           data_val := data_val + 1;
           asserted := '0';
           addr := addr + 1;
       end if;
   end if;
   end process valid_assert;
   
   clkEn <= '1';



end tb;