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
    signal rx_data : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal enb   : STD_LOGIC;
    signal clkb  : std_logic;
    signal rstb  : std_logic;
     -- AXI Master Stream Ports
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

  signal irq_set_value  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal irq_out_pulse  : std_logic;
  signal irq_en         : std_logic;

  component FIFO_SLAVE_STREAM_CONTROLLER is
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
          
          --AXIL Read Control Ports
          axil_dvalid    : out std_logic; -- assert to axi4-lite interface data is ready
          axil_read_done : in std_logic;  -- acknowledgment from axi4-lite iface data has been read
          
          -- AXIS Slave Stream Ports
          S_AXIS_TREADY   : out std_logic;
          S_AXIS_TDATA    : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          S_AXIS_TVALID   : in std_logic;

          -- fifo control lines
          clk            : in std_logic;
          clkEn          : in std_logic;
          reset          : in std_logic;
          fifo_full      : out std_logic;
          fifo_empty     : out std_logic;
          fifo_occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          fifo_read_en   : in  std_logic;
          fifo_dout      : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
          irq_set_value  : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
          irq_out_pulse  : out std_logic;
          irq_en         : in std_logic
      );
  end component FIFO_SLAVE_STREAM_CONTROLLER;

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
        S_AXIS_TREADY  => S_AXIS_TREADY,
        S_AXIS_TDATA   => S_AXIS_TDATA,
        S_AXIS_TVALID  => S_AXIS_TVALID,

        -- fifo control lines
        clk            => clk,
        clkEn          => '1',
        reset          => reset,
        fifo_full      => fifo_full,
        fifo_empty     => fifo_empty,
        fifo_occupancy => fifo_occupancy,
        fifo_read_en   => fifo_read_en,
        fifo_dout      => fifo_dout,
        irq_set_value => irq_set_value,
        irq_out_pulse => irq_out_pulse,
        irq_en => irq_en
        );    

  bram_process : process(clk, reset)
  begin
  if(rising_edge(clk)) then
    if(wea = '1') then
      bram_array(to_integer(unsigned(addra))) <= dina;
    end if;
    doutb <= bram_array(to_integer(unsigned(addrb)));
  end if;
  end process bram_process;

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

   write_stim : process(clk,reset)
    type states is (ST_IDLE, ST_WRITE, ST_INIT, ST_DONE);
    variable fsm : states := ST_IDLE;
    variable cnt : integer := 1;
    constant init_value : integer := 20;
   begin
   if(reset = '1') then
    fsm := ST_INIT;
    S_AXIS_TDATA  <= (others => '0');
    S_AXIS_TVALID <= '0';
    cnt := 1;
   elsif(rising_edge(clk)) then
   case (fsm) is

    when ST_INIT =>
      irq_set_value <= std_logic_vector(to_unsigned(init_value,irq_set_value'length));
      irq_en <= '1';
      fsm := ST_IDLE;

    when ST_IDLE =>
      S_AXIS_TDATA <= std_logic_vector(to_unsigned(cnt, S_AXIS_TDATA'length));
      S_AXIS_TVALID <= '1';
      fsm := ST_WRITE;

    when ST_WRITE =>
      if(S_AXIS_TREADY = '1') then
        S_AXIS_TDATA <= (others => '0');
        S_AXIS_TVALID <= '0';
        fsm := ST_IDLE;
        if(cnt = init_value) then
          fsm := ST_DONE;
        else
          cnt := cnt + 1;
        end if;
      end if;

    when ST_DONE =>
      fsm := ST_DONE;

   end case;
   end if;
   end process write_stim;
      
   read_test : process(clk,reset)
    type states is (ST_IDLE, ST_GO, ST_WAIT_FOR_DATA);
    variable fsm : states := ST_IDLE;
   begin
   if(reset = '1') then
      fsm := ST_IDLE;
       fifo_read_en <= '0';
       axil_read_done <= '0';
   elsif(rising_edge(clk)) then
   case (fsm) is 

    when ST_IDLE =>
      if(irq_out_pulse = '1') then
        fsm := ST_GO;
      end if;

    when ST_GO =>
      axil_read_done <= '0';
      if(fifo_empty = '0') then
        fifo_read_en <= '1';
        fsm := ST_WAIT_FOR_DATA;
      else
        fsm := ST_IDLE;
      end if;

    when ST_WAIT_FOR_DATA =>
      fifo_read_en <= '0';
      if(axil_dvalid = '1') then
        rx_data <= fifo_dout;
        axil_read_done <= '1';
        fsm := ST_GO;
      end if;
           
   end case;
   end if;
   end process read_test;

end tb;