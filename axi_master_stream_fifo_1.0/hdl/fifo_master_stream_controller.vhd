library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity FIFO_MASTER_STREAM_CONTROLLER is
	generic (
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32;
		C_M_AXIS_TDATA_WIDTH : integer := 32
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

        -- AXI Master Stream Ports
        M_AXIS_ACLK	    : in std_logic;
        M_AXIS_ARESETN  : in std_logic;
        M_AXIS_TVALID   : out std_logic;
        M_AXIS_TDATA    : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
        M_AXIS_TSTRB    : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
        M_AXIS_TLAST    : out std_logic;
        M_AXIS_TREADY   : in std_logic;

        -- fifo control lines
        clk            : in std_logic;
        clkEn          : in std_logic;
        reset          : in std_logic;
        fifo_din       : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        fifo_write_en  : in std_logic;
        fifo_full      : out std_logic;
        fifo_empty     : out std_logic;
        fifo_occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fifo_ready       : out std_logic
		);
end FIFO_MASTER_STREAM_CONTROLLER;

architecture Behavorial of FIFO_MASTER_STREAM_CONTROLLER is

    -- fifo status, control, and data signals
    signal sig_fifo_full       : std_logic := '0';
    signal sig_fifo_empty      : std_logic := '1';
    signal sig_fifo_occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal sig_fifo_dout       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
    signal sig_fifo_dvalid     : std_logic := '0'; 
    signal sig_fifo_read_en    : std_logic := '0';
    signal sig_fifo_read_ready : std_logic := '0';
    signal sig_fifo_write_ready : std_logic := '0';
    
    -- axi-stream signals
    signal sig_axis_din    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    signal sig_axis_dvalid : std_logic := '0';
    signal sig_axis_txdone : std_logic := '0';
    signal sig_axis_rdy    : std_logic := '0';

    -- state machine signals
    type state is (ST_IDLE, ST_ACTIVE, ST_WAIT);
    signal fsm : state := ST_IDLE;

begin

	-- Instantiation of FIFO Controller
	BRAM_FIFO_CONTROLLER_inst : BRAM_FIFO_CONTROLLER
	    generic map( 
	        BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
	        BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
	    port map (
	        addra => addra,
	        dina  => dina,
	        ena   => ena,
	        wea   => wea,
	        clka  => clka, -- instantiated with BUFR top level
	        rsta  => rsta,
	        addrb => addrb,
	        doutb => doutb,
	        enb   => enb,
	        clkb  => clkb, -- instantiated with BUFR top level
	        rstb  => rstb,
	        
	        clk        => clk,
	        clkEn      => clkEn,
	        write_en   => fifo_write_en,
	        reset      => reset,
	        din        => fifo_din,
	        read_en    => sig_fifo_read_en,
            read_ready => sig_fifo_read_ready,
            write_ready => sig_fifo_write_ready,
	        dout       => sig_fifo_dout,
	        dvalid     => sig_fifo_dvalid,
	        full       => sig_fifo_full,
	        empty      => sig_fifo_empty,
	        occupancy  => sig_fifo_occupancy
	    );
	    
	-- Instantiation of Master Stream Interface
	axi_master_stream_inst : AXI_MASTER_STREAM
	    generic map( C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH)
	    port map(
	        user_din        => sig_axis_din,
	        user_dvalid     => sig_axis_dvalid,
	        user_txdone     => sig_axis_txdone,
	        axis_rdy        => sig_axis_rdy,
			M_AXIS_ACLK	    => M_AXIS_ACLK,
	        M_AXIS_ARESETN  => M_AXIS_ARESETN,
	        M_AXIS_TVALID   => M_AXIS_TVALID,
	        M_AXIS_TDATA    => M_AXIS_TDATA,
	        M_AXIS_TSTRB    => M_AXIS_TSTRB,
	        M_AXIS_TLAST    => M_AXIS_TLAST,
	        M_AXIS_TREADY   => M_AXIS_TREADY
	    );

    ------------------------------------------------
    -- load output lines synchronously with clock --
    ------------------------------------------------
    loader : process(clk)
    begin
    if(rising_edge(clk)) then
    	fifo_empty     <= sig_fifo_empty;
    	fifo_full      <= sig_fifo_full;
    	fifo_occupancy <= sig_fifo_occupancy;
        fifo_ready       <= sig_fifo_write_ready;
    end if;
    end process loader;

    -------------------------------------
    -- Stream and FIFO read controller --
    -------------------------------------
    axis_read_ctrl : process(clk) 
        constant MAX_WAIT : integer := 4;
        variable cnt : integer range 0 to MAX_WAIT := 0;
    begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            fsm <= ST_IDLE;
            sig_axis_dvalid <= '0';
            sig_fifo_read_en <= '0';
            cnt := 0;
        elsif(clkEn = '1') then
            case(fsm) is
                when ST_IDLE =>
                    if(sig_fifo_empty = '0' and sig_axis_rdy = '1' and sig_fifo_read_ready = '1') then
                        sig_fifo_read_en <= '1';
                        fsm <= ST_ACTIVE;
                    end if;
                
                when ST_ACTIVE =>
                    sig_fifo_read_en <= '0';
                    if(sig_fifo_dvalid = '1') then
                        sig_axis_din <= sig_fifo_dout;
                        sig_axis_dvalid <= '1'; 
                        fsm <= ST_WAIT;
                    end if;

                when ST_WAIT =>
                    sig_axis_dvalid <= '0';   
                    if(sig_axis_txdone = '1') then
                        fsm <= ST_IDLE;
                    end if;

                when others =>
                    fsm <= ST_IDLE;

            end case;
        end if;
    end if;
    end process axis_read_ctrl;

end Behavorial;