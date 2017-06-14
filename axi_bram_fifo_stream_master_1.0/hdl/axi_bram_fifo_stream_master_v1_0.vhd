library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity axi_bram_fifo_stream_master_v1_0 is
	generic (
		-- Users to add parameters here
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32;
		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;
		-- Parameter for AXI Master Stream
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
        M_AXIS_ARESETN    : in std_logic;
        M_AXIS_TVALID    : out std_logic;
        M_AXIS_TDATA    : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
        M_AXIS_TSTRB    : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
        M_AXIS_TLAST    : out std_logic;
        M_AXIS_TREADY    : in std_logic;

		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic
	);
end axi_bram_fifo_stream_master_v1_0;

architecture arch_imp of axi_bram_fifo_stream_master_v1_0 is

	-- component declaration
	component axi_bram_fifo_stream_master_v1_0_S00_AXI is
		generic (
        BRAM_ADDR_WIDTH  : integer := 10;
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
        fifo_clkEn      : out std_logic;
        fifo_write_en   : out std_logic;
        fifo_reset      : out std_logic;
        fifo_din        : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        fifo_bram_full  : in std_logic;
        fifo_bram_empty : in std_logic;
        fifo_bram_occupancy  : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);

		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component axi_bram_fifo_stream_master_v1_0_S00_AXI;
	
--------------------------- SIGNALS ------------------------------------------
	
	-- axi-lite signals for controlling the bram writes
    signal axil_clkEn      : std_logic := '0';
    signal axil_write_en   : std_logic := '0';
    signal axil_reset      : std_logic := '0';
    signal axil_din        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
    
    -- generic fifo status signals
    signal bram_full  : std_logic := '0';
    signal bram_empty : std_logic := '1';
    signal bram_occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal bram_dout :  std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
    signal bram_dvalid : std_logic := '0'; 
    signal bram_read_en : std_logic := '0';
    signal bram_clk     : std_logic := '0';
    
    -- axi-stream signals
    signal axis_user_din    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    signal axis_user_dvalid : std_logic := '0';
    signal axis_txdone      : std_logic := '0';
    signal axis_rdy         : std_logic := '0';
    
    type state is (ST_IDLE, ST_ACTIVE, ST_WAIT);
    signal fsm : state := ST_IDLE;

begin

-------------------- INSTANTIATIONS -------------------------------------------

-- Instantiation of Axi Bus Interface S00_AXI
axi_bram_fifo_stream_master_v1_0_S00_AXI_inst : axi_bram_fifo_stream_master_v1_0_S00_AXI
	generic map (
	    BRAM_ADDR_WIDTH     => BRAM_ADDR_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
        fifo_clkEn      => axil_clkEn,
        fifo_write_en   => axil_write_en,
        fifo_reset      => axil_reset,
        fifo_din        => axil_din,
        fifo_bram_full  => bram_full,
        fifo_bram_empty => bram_empty,
        fifo_bram_occupancy  => bram_occupancy,
		S_AXI_ACLK	=> s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA	=> s00_axi_wdata,
		S_AXI_WSTRB	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	=> s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	=> s00_axi_rdata,
		S_AXI_RRESP	=> s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

-- Instantiation of FIFO Controller
axi_bram_fifo_controller_inst : bram_fifo_controller
    generic map( 
        READ_SRC => CMN_PL_READ,
        BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
        BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
    port map (
        addra => addra,
        dina  => dina,
        ena   => ena,
        wea   => wea,
        clka  => open,
        rsta  => rsta,
        addrb => addrb,
        doutb => doutb,
        enb   => enb,
        clkb  => open,
        rstb  => rstb,
        
        clk   => s00_axi_aclk,
        clkEn => axil_clkEn,
        write_en => axil_write_en,
        read_en  => bram_read_en,
        reset    => axil_reset,
        din      => axil_din,
        dout     => bram_dout,
        dout_valid => bram_dvalid,
        bram_full  => bram_full,
        bram_empty => bram_empty,
        bram_occupancy => bram_occupancy
    );
    
axi_master_stream_inst : AXI_MASTER_STREAM
    generic map( C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH)
    port map(
        user_din        => axis_user_din,
        user_dvalid     => axis_user_dvalid,
        user_txdone     => axis_txdone,
        axis_rdy        => axis_rdy,
		M_AXIS_ACLK	    => M_AXIS_ACLK,
        M_AXIS_ARESETN  => M_AXIS_ARESETN,
        M_AXIS_TVALID   => M_AXIS_TVALID,
        M_AXIS_TDATA    => M_AXIS_TDATA,
        M_AXIS_TSTRB    => M_AXIS_TSTRB,
        M_AXIS_TLAST    => M_AXIS_TLAST,
        M_AXIS_TREADY   => M_AXIS_TREADY
    );
    
    -- bram clock and reset line
    BUFR_inst : BUFR
        generic map(
            BUFR_DIVIDE => "BYPASS",
            SIM_DEVICE => "7SERIES"
        )
        port map(
            I => s00_axi_aclk,
            CE => '1',
            CLR => '0',
            O => bram_clk
        );
    clka <= bram_clk;
    clkb <= bram_clk;
    
----------------- TOP LEVEL LOGIC ------------------------------

    axis_write_ctrl : process(s00_axi_aclk) 
    begin
    if(rising_edge(s00_axi_aclk)) then
        if(axil_reset = '1') then
            fsm <= ST_IDLE;
            axis_user_dvalid <= '0';
            bram_read_en <= '0';
        elsif(axil_clkEn = '1') then
            case(fsm) is
                when ST_IDLE =>
                    if(bram_empty = '0' and axis_rdy = '1') then
                        bram_read_en <= '1';
                        fsm <= ST_ACTIVE;
                    end if;
                
                when ST_ACTIVE =>
                    bram_read_en <= '0';
                    if(bram_dvalid = '1') then
                        axis_user_din <= bram_dout;
                        axis_user_dvalid <= '1'; 
                        fsm <= ST_WAIT;
                    end if;

                when ST_WAIT =>
                    axis_user_dvalid <= '0';   
                    if(axis_txdone = '1') then
                        fsm <= ST_IDLE;
                    end if;

                when others =>
                    fsm <= ST_IDLE;

            end case;
        end if;
    end if;
    end process axis_write_ctrl;

end arch_imp;
