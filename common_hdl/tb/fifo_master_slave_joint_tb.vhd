library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.generic_pkg.all;

use IEEE.NUMERIC_STD.ALL;

entity fifo_master_slave_joint_tb is
end fifo_master_slave_joint_tb;

architecture Behavioral of fifo_master_slave_joint_tb is
	
	-- constants
	constant BRAM_ADDR_WIDTH  : integer := 10;
    constant BRAM_DATA_WIDTH  : integer := 32;
	constant C_M_AXIS_TDATA_WIDTH : integer := 32;
    constant C_S_AXIS_TDATA_WIDTH    : integer   := 32;	
	constant clk_period : time := 10 ns; -- 100 MHz clock
  
  	-- general signals
    signal clk            : std_logic;
    signal clkEn          : std_logic;
    signal reset          : std_logic;

    -- master interface
	  signal mstr_addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal mstr_dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal mstr_ena   : STD_LOGIC;
    signal mstr_wea   : STD_LOGIC;
    signal mstr_clka  : std_logic;
    signal mstr_rsta  : std_logic;        
    signal mstr_addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal mstr_sig_doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal mstr_enb   : STD_LOGIC;
    signal mstr_clkb  : std_logic;
    signal mstr_rstb  : std_logic;
    signal M_AXIS_TVALID   : std_logic;
    signal M_AXIS_TDATA    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    signal M_AXIS_TSTRB    : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    signal M_AXIS_TLAST    : std_logic;
    signal M_AXIS_TREADY   : std_logic;
    signal mstr_fifo_din       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal mstr_fifo_write_en  : std_logic;
    signal mstr_fifo_full      : std_logic;
    signal mstr_fifo_empty     : std_logic;
    signal mstr_fifo_ready     : std_logic;
    signal mstr_fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);

    -- slave interface
    signal slv_addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal slv_dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal slv_ena   : STD_LOGIC;
    signal slv_wea   : STD_LOGIC;
    signal slv_clka  : std_logic;
    signal slv_rsta  : std_logic;        
    signal slv_addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
    signal slv_doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
    signal slv_enb   : STD_LOGIC;
    signal slv_clkb  : std_logic;
    signal slv_rstb  : std_logic;
    signal slv_fifo_dout      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal slv_fifo_read_en   : std_logic;
    signal slv_fifo_full      : std_logic;
    signal slv_fifo_empty     : std_logic;
    signal slv_fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    signal slv_axil_dvalid    : std_logic;
    signal slv_axil_read_done : std_logic;

    -- fifos
    constant BRAM_MAX_SZ : integer := 1023;
    constant READ_CNT  : integer := 0;
    constant DEADBEEF : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := x"DEADBEEF";  
    type bram_array_type is array (0 to BRAM_MAX_SZ) of std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal mstr_bram : bram_array_type;
    signal slav_bram : bram_array_type;
begin

	DUT_MSTR : FIFO_MASTER_STREAM_CONTROLLER
	port map (
	    -- BRAM write port lines
	    addra => mstr_addra,
	    dina  => mstr_dina,
	    ena   => mstr_ena,
	    wea   => mstr_wea,
	    clka  => mstr_clka,
	    rsta  => mstr_rsta,
	    
	    -- BRAM read port lines
	    addrb => mstr_addrb,
	    doutb => mstr_sig_doutb,
	    enb   => mstr_enb,
	    clkb  => mstr_clkb,
	    rstb  => mstr_rstb,

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
	    fifo_din        => mstr_fifo_din,
	    fifo_write_en   => mstr_fifo_write_en,
	    fifo_full       => mstr_fifo_full,
	    fifo_empty      => mstr_fifo_empty,
      fifo_ready      => mstr_fifo_ready,  
	    fifo_occupancy  => mstr_fifo_occupancy
	    );

    DUT_SLV : FIFO_SLAVE_STREAM_CONTROLLER
    port map (
        -- BRAM write port lines
        addra => slv_addra,
        dina  => slv_dina,
        ena   => slv_ena,
        wea   => slv_wea,
        clka  => slv_clka,
        rsta  => slv_rsta,
        
        -- BRAM read port lines
        addrb => slv_addrb,
        doutb => slv_doutb,
        enb   => slv_enb,
        clkb  => slv_clkb,
        rstb  => slv_rstb,
        
        axil_dvalid    => slv_axil_dvalid,
        axil_read_done => slv_axil_read_done,

        -- AXIS Slave Stream Ports
        S_AXIS_ACLK    => clk,
        S_AXIS_ARESETN => not reset,
        S_AXIS_TREADY  => M_AXIS_TREADY,
        S_AXIS_TDATA   => M_AXIS_TDATA,
        S_AXIS_TSTRB   => M_AXIS_TSTRB,
        S_AXIS_TLAST   => M_AXIS_TLAST,
        S_AXIS_TVALID  => M_AXIS_TVALID,

        -- fifo control lines
        clk            => clk,
        clkEn          => clkEn,
        reset          => reset,
        fifo_full      => slv_fifo_full,
        fifo_empty     => slv_fifo_empty,
        fifo_occupancy => slv_fifo_occupancy,
        fifo_read_en   => slv_fifo_read_en,
        fifo_dout      => slv_fifo_dout
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
       constant rst_cnt : integer := 20000;
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

    mstr_write_test : process(clk, reset)
        constant maxcnt : integer := 10;
        variable data_val : integer := 1;
        variable cnt : integer range 0 to maxcnt := 0;
        variable write_asserted : std_logic := '0';
    begin
    if(reset = '1') then
        cnt := 0;
        data_val := 1;
        write_asserted := '0';
        mstr_fifo_write_en <= '0';
        for i in 0 to BRAM_MAX_SZ loop
          mstr_bram(i) <= DEADBEEF;
        end loop;
    elsif(rising_edge(clk)) then
        if(mstr_fifo_ready = '1' and write_asserted = '0') then
            mstr_fifo_din <= std_logic_vector(to_unsigned(data_val, BRAM_DATA_WIDTH));
            mstr_bram(to_integer(unsigned(mstr_addra))) <= std_logic_vector(to_unsigned(data_val, BRAM_DATA_WIDTH));
            mstr_fifo_write_en <= '1';
            write_asserted := '1';
        elsif(write_asserted = '1') then
            mstr_fifo_write_en <= '0';
            if(cnt = maxcnt) then
                write_asserted := '0';
                data_val := data_val + 1;
                cnt := 0;
            else
                cnt := cnt + 1;
            end if;
        end if;
    end if;
    end process mstr_write_test;

    slv_read_test : process(clk)
       variable data_val : integer := 1;
       constant maxcnt : integer := 100;
       variable cnt : integer range 0 to maxcnt := 0;
       variable read_en_asserted : std_logic := '0';
       variable read_done_asserted : std_logic := '0';
   begin
   if(reset = '1') then
       data_val := 1;
       read_en_asserted := '0';
       read_done_asserted := '0';
       slv_fifo_read_en <= '0';
       cnt := 0;
       for i in 0 to BRAM_MAX_SZ loop
          slav_bram(i) <= DEADBEEF;
       end loop;
   elsif(rising_edge(clk)) then
       if(slv_axil_dvalid = '0' and read_en_asserted = '0') then
           slv_fifo_read_en <= '1';
           slv_doutb <= mstr_bram(to_integer(unsigned(slv_addrb)));
           read_en_asserted := '1';
       elsif(read_en_asserted = '1') then
           slv_fifo_read_en <= '0';
       end if;
       
       if(slv_axil_dvalid = '1' and read_done_asserted = '0') then
           slv_axil_read_done <= '1';
           read_done_asserted := '1';
           slav_bram(to_integer(unsigned(slv_addrb))) <= slv_fifo_dout;
           cnt := 0;
       elsif(read_done_asserted = '1') then
           slv_axil_read_done <= '0';
           if(cnt = maxcnt) then
               data_val := data_val + 1;
               slav_bram(to_integer(unsigned(slv_addrb))) <= std_logic_vector(to_unsigned(data_val, BRAM_DATA_WIDTH));
               read_done_asserted := '0';
               read_en_asserted := '0';
           else
              cnt := cnt + 1;
           end if;
       end if;
           
   end if;
   end process slv_read_test;

end Behavioral;