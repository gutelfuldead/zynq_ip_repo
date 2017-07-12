library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity axi_master_stream_fifo_v1_0 is
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
end axi_master_stream_fifo_v1_0;

architecture arch_imp of axi_master_stream_fifo_v1_0 is

	-- component declaration
	component axi_master_stream_fifo_v1_0_S00_AXI is
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
        fifo_full  : in std_logic;
        fifo_empty : in std_logic;
        fifo_occupancy  : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fifo_ready     : in std_logic;

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
	end component axi_master_stream_fifo_v1_0_S00_AXI;	

    signal sig_fifo_clkEn      : std_logic := '0';
    signal sig_fifo_write_en   : std_logic := '0';
    signal sig_fifo_reset      : std_logic := '0';
    signal sig_fifo_din        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal sig_fifo_full  : std_logic := '0';
    signal sig_fifo_ready   : std_logic := '0';
    signal sig_fifo_empty : std_logic := '0';
    signal sig_fifo_occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal bram_clk : std_logic := '0';

begin

-------------------- INSTANTIATIONS -------------------------------------------

-- Instantiation of Axi Bus Interface S00_AXI
axi_master_stream_fifo_v1_0_S00_AXI_inst : axi_master_stream_fifo_v1_0_S00_AXI
	generic map (
	    BRAM_ADDR_WIDTH     => BRAM_ADDR_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
        -- fifo control signals
        fifo_clkEn      => sig_fifo_clkEn,
        fifo_write_en   => sig_fifo_write_en,
        fifo_reset      => sig_fifo_reset,
        fifo_din        => sig_fifo_din,
        fifo_full       => sig_fifo_full,
        fifo_empty      => sig_fifo_empty,
        fifo_occupancy  => sig_fifo_occupancy,
        fifo_ready      => sig_fifo_ready,
        -- axi4-lite template signals
		S_AXI_ACLK	    => s00_axi_aclk,
		S_AXI_ARESETN	=> s00_axi_aresetn,
		S_AXI_AWADDR	=> s00_axi_awaddr,
		S_AXI_AWPROT	=> s00_axi_awprot,
		S_AXI_AWVALID	=> s00_axi_awvalid,
		S_AXI_AWREADY	=> s00_axi_awready,
		S_AXI_WDATA  	=> s00_axi_wdata,
		S_AXI_WSTRB  	=> s00_axi_wstrb,
		S_AXI_WVALID	=> s00_axi_wvalid,
		S_AXI_WREADY	=> s00_axi_wready,
		S_AXI_BRESP	    => s00_axi_bresp,
		S_AXI_BVALID	=> s00_axi_bvalid,
		S_AXI_BREADY	=> s00_axi_bready,
		S_AXI_ARADDR	=> s00_axi_araddr,
		S_AXI_ARPROT	=> s00_axi_arprot,
		S_AXI_ARVALID	=> s00_axi_arvalid,
		S_AXI_ARREADY	=> s00_axi_arready,
		S_AXI_RDATA	    => s00_axi_rdata,
		S_AXI_RRESP	    => s00_axi_rresp,
		S_AXI_RVALID	=> s00_axi_rvalid,
		S_AXI_RREADY	=> s00_axi_rready
	);

    fifo_stream_control_inst : FIFO_MASTER_STREAM_CONTROLLER
    generic map(
                -- Users to add parameters here
        BRAM_ADDR_WIDTH  => BRAM_ADDR_WIDTH,
        BRAM_DATA_WIDTH  => BRAM_DATA_WIDTH,
        C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH)
    port map (
        -- BRAM write port lines
        addra => addra,
        dina  => dina,
        ena   => ena,
        wea   => wea,
        clka  => open,
        rsta  => rsta,
        
        -- BRAM read port lines
        addrb => addrb,
        doutb => doutb,
        enb   => enb,
        clkb  => open,
        rstb  => rstb,

        -- AXI Master Stream Ports
        M_AXIS_ACLK     => M_AXIS_ACLK,
        M_AXIS_ARESETN  => M_AXIS_ARESETN,
        M_AXIS_TVALID   => M_AXIS_TVALID,
        M_AXIS_TDATA    => M_AXIS_TDATA,
        M_AXIS_TSTRB    => M_AXIS_TSTRB,
        M_AXIS_TLAST    => M_AXIS_TLAST,
        M_AXIS_TREADY   => M_AXIS_TREADY,

        -- control lines
        clk             => s00_axi_aclk,
        clkEn           => sig_fifo_clkEn,
        reset           => sig_fifo_reset,
        fifo_din        => sig_fifo_din,
        fifo_write_en   => sig_fifo_write_en,
        fifo_full       => sig_fifo_full,
        fifo_empty      => sig_fifo_empty,
        fifo_ready      => sig_fifo_ready,
        fifo_occupancy  => sig_fifo_occupancy
        );

    --------------------------------
    -- generate bram clock buffer --
    --------------------------------
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

end arch_imp;
