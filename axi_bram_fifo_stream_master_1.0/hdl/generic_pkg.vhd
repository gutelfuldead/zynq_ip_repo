library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

package generic_pkg is

--------------------------------------------------------------------------
--------------------------- CONSTANTS ------------------------------------
--------------------------------------------------------------------------
    -- used to latch the dout_valid signal in the BRAM_FIFO_CONTROLLER core
    -- high when the read interface is coming from the PS to allow time
    -- to capture the data over the AXI bus
    constant CMN_PS_READ : std_logic := '1';
    constant CMN_PL_READ : std_logic := '0';

--------------------------------------------------------------------------
--------------------------- COMPONENTS -----------------------------------
--------------------------------------------------------------------------

	--------------------------------------
    -- Turns dual port BRAM into a FIFO --
	--------------------------------------
	component BRAM_FIFO_CONTROLLER is
	    generic (
	           READ_SRC         : std_logic := '1';
	           BRAM_ADDR_WIDTH  : integer := 10;
	           BRAM_DATA_WIDTH  : integer := 32 );
	    Port ( 
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
	           
	           -- Core logic
	           clk        : in std_logic;
	           clkEn      : in std_logic;
	           write_en   : in std_logic;
	           read_en    : in std_logic;
	           reset      : in std_logic;
	           din        : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
	           dout       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
	           dvalid     : out std_logic;
	           full       : out std_logic;
	           empty      : out std_logic;
	           occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
	           );
	end component BRAM_FIFO_CONTROLLER;

	------------------------------------------------
    -- address generator for BRAM_FIFO_CONTROLLER --
	------------------------------------------------
    component FIFO_ADDR_GEN is
        generic ( BRAM_ADDR_WIDTH  : integer := 10 );
        Port ( clk : in STD_LOGIC;
               en  : in STD_LOGIC;
               rst : in STD_LOGIC;
               rden : in STD_LOGIC;
               wren : in STD_LOGIC;
               rd_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
               wr_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
               fifo_empty : out std_logic;
               fifo_full  : out std_logic;
               fifo_occupancy : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0));
    end component FIFO_ADDR_GEN;

    ------------------------------------------
    -- Generic AXI4-Stream Master Interface --
    ------------------------------------------
    component AXI_MASTER_STREAM is
	generic ( C_M_AXIS_TDATA_WIDTH	: integer	:= 32 );
	port ( -- control ports
		user_din    : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		user_dvalid : in std_logic; 
		user_txdone : out std_logic;
		axis_rdy: out std_logic;
		-- global ports
		M_AXIS_ACLK	    : in std_logic;
		M_AXIS_ARESETN	: in std_logic;
		M_AXIS_TVALID	: out std_logic;
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		M_AXIS_TLAST	: out std_logic;
		M_AXIS_TREADY	: in std_logic);
	end component AXI_MASTER_STREAM;

	-----------------------------------------
	-- generic AXI4-Stream Slave Interface --
	-----------------------------------------
	component AXI_SLAVE_STREAM is
	generic ( C_S_AXIS_TDATA_WIDTH	: integer	:= 32 );
	port ( -- control ports		
		user_rdy    : in std_logic;
        user_dvalid : out std_logic;
        user_data   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		axis_rdy: out std_logic;
		-- global ports
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic);
	end component AXI_SLAVE_STREAM;
	
	---------------------------------------------------------------------
	-- controller combining AXI_MASTER_STREAM and BRAM_FIFO_CONTROLLER --
	---------------------------------------------------------------------
	component FIFO_MASTER_STREAM_CONTROLLER is
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
	        fifo_occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
			);
	end component FIFO_MASTER_STREAM_CONTROLLER;


end generic_pkg;
