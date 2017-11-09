library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity simple_rx_fifo_v1_0 is
	generic (
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32;

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 5;

		-- Parameters of Axi Slave Bus Interface S_AXI_INTR
		C_S_AXI_INTR_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_INTR_ADDR_WIDTH	: integer	:= 5;
		C_NUM_OF_INTR	: integer	:= 1;
		C_INTR_SENSITIVITY	: std_logic_vector	:= x"FFFFFFFF";
		C_INTR_ACTIVE_STATE	: std_logic_vector	:= x"FFFFFFFF";
		C_IRQ_SENSITIVITY	: integer	:= 1;
		C_IRQ_ACTIVE_STATE	: integer	:= 1
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

		-- AXIS slave ports
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
		S_AXIS_TVALID	: in std_logic;

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
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXI_INTR
		s_axi_intr_aclk	: in std_logic;
		s_axi_intr_aresetn	: in std_logic;
		s_axi_intr_awaddr	: in std_logic_vector(C_S_AXI_INTR_ADDR_WIDTH-1 downto 0);
		s_axi_intr_awprot	: in std_logic_vector(2 downto 0);
		s_axi_intr_awvalid	: in std_logic;
		s_axi_intr_awready	: out std_logic;
		s_axi_intr_wdata	: in std_logic_vector(C_S_AXI_INTR_DATA_WIDTH-1 downto 0);
		s_axi_intr_wstrb	: in std_logic_vector((C_S_AXI_INTR_DATA_WIDTH/8)-1 downto 0);
		s_axi_intr_wvalid	: in std_logic;
		s_axi_intr_wready	: out std_logic;
		s_axi_intr_bresp	: out std_logic_vector(1 downto 0);
		s_axi_intr_bvalid	: out std_logic;
		s_axi_intr_bready	: in std_logic;
		s_axi_intr_araddr	: in std_logic_vector(C_S_AXI_INTR_ADDR_WIDTH-1 downto 0);
		s_axi_intr_arprot	: in std_logic_vector(2 downto 0);
		s_axi_intr_arvalid	: in std_logic;
		s_axi_intr_arready	: out std_logic;
		s_axi_intr_rdata	: out std_logic_vector(C_S_AXI_INTR_DATA_WIDTH-1 downto 0);
		s_axi_intr_rresp	: out std_logic_vector(1 downto 0);
		s_axi_intr_rvalid	: out std_logic;
		s_axi_intr_rready	: in std_logic;
		irq	: out std_logic
	);
end simple_rx_fifo_v1_0;

architecture arch_imp of simple_rx_fifo_v1_0 is

	-- component declaration
	component simple_rx_fifo_v1_0_S00_AXI is
		generic (
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32;
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
		);
		port (
		fifo_clkEn : out std_logic;
		fifo_reset : out std_logic;
		fifo_bram_full : in std_logic;
		fifo_bram_empty : in std_logic;
        fifo_bram_occupancy  : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fifo_read_en : out std_logic;
        fifo_read_done       : out std_logic;
        fifo_din : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        fifo_din_valid       : in std_logic;
        irq_set_value  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);	
        irq_en  : out std_logic;

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
	end component simple_rx_fifo_v1_0_S00_AXI;

	component simple_rx_fifo_v1_0_S_AXI_INTR is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5;
		C_NUM_OF_INTR	: integer	:= 1;
		C_INTR_SENSITIVITY	: std_logic_vector	:= x"FFFFFFFF";
		C_INTR_ACTIVE_STATE	: std_logic_vector	:= x"FFFFFFFF";
		C_IRQ_SENSITIVITY	: integer	:= 1;
		C_IRQ_ACTIVE_STATE	: integer	:= 1
		);
		port (
		irq_in_pulse : in std_logic;
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
		S_AXI_RREADY	: in std_logic;
		irq	: out std_logic
		);
	end component simple_rx_fifo_v1_0_S_AXI_INTR;

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
        rsta  : out std_logic;
        
        -- BRAM read port lines
        addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
        doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
        enb   : out STD_LOGIC;
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
        irq_en : in std_logic
		);
end component FIFO_SLAVE_STREAM_CONTROLLER;

	-- ports to control the bram from axi-lite interface
	signal axil_clkEn      : std_logic := '0';
	signal axil_read_en    : std_logic := '0';
	signal axil_read_done  : std_logic := '0';
	signal axil_reset      : std_logic := '0';
	signal axil_dout       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
	signal s_axil_dvalid     : std_logic := '0';
	signal s_axil_read_done  : std_logic := '0';
	-- information ports from bram
	signal bram_full       : std_logic := '0';
	signal bram_empty      : std_logic := '0';
	signal bram_occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal bram_clk        : std_logic := '0';

	signal irq_set_value : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1');
	signal irq_pulse     : std_logic := '0';
	signal irq_en : std_logic := '0';

	type state is (ST_IDLE, ST_ACTIVE);
	signal fsm : state := (ST_IDLE);

begin

-- Instantiation of Axi Bus Interface S00_AXI
simple_rx_fifo_v1_0_S00_AXI_inst : simple_rx_fifo_v1_0_S00_AXI
	generic map (
		BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
		BRAM_DATA_WIDTH => BRAM_DATA_WIDTH,
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		fifo_clkEn           => axil_clkEn,
		fifo_reset           => axil_reset,
		fifo_bram_full       => bram_full,
		fifo_bram_empty      => bram_empty,
        fifo_bram_occupancy  => bram_occupancy,
        fifo_read_en         => axil_read_en,
        fifo_din             => axil_dout,
        fifo_din_valid       => s_axil_dvalid,
        fifo_read_done       => s_axil_read_done,
        irq_set_value        => irq_set_value,
        irq_en               => irq_en,
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

-- Instantiation of Axi Bus Interface S_AXI_INTR
simple_rx_fifo_v1_0_S_AXI_INTR_inst : simple_rx_fifo_v1_0_S_AXI_INTR
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_INTR_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_INTR_ADDR_WIDTH,
		C_NUM_OF_INTR	=> C_NUM_OF_INTR,
		C_INTR_SENSITIVITY	=> C_INTR_SENSITIVITY,
		C_INTR_ACTIVE_STATE	=> C_INTR_ACTIVE_STATE,
		C_IRQ_SENSITIVITY	=> C_IRQ_SENSITIVITY,
		C_IRQ_ACTIVE_STATE	=> C_IRQ_ACTIVE_STATE
	)
	port map (
		irq_in_pulse => irq_pulse,
		S_AXI_ACLK	=> s_axi_intr_aclk,
		S_AXI_ARESETN	=> s_axi_intr_aresetn,
		S_AXI_AWADDR	=> s_axi_intr_awaddr,
		S_AXI_AWPROT	=> s_axi_intr_awprot,
		S_AXI_AWVALID	=> s_axi_intr_awvalid,
		S_AXI_AWREADY	=> s_axi_intr_awready,
		S_AXI_WDATA	=> s_axi_intr_wdata,
		S_AXI_WSTRB	=> s_axi_intr_wstrb,
		S_AXI_WVALID	=> s_axi_intr_wvalid,
		S_AXI_WREADY	=> s_axi_intr_wready,
		S_AXI_BRESP	=> s_axi_intr_bresp,
		S_AXI_BVALID	=> s_axi_intr_bvalid,
		S_AXI_BREADY	=> s_axi_intr_bready,
		S_AXI_ARADDR	=> s_axi_intr_araddr,
		S_AXI_ARPROT	=> s_axi_intr_arprot,
		S_AXI_ARVALID	=> s_axi_intr_arvalid,
		S_AXI_ARREADY	=> s_axi_intr_arready,
		S_AXI_RDATA	=> s_axi_intr_rdata,
		S_AXI_RRESP	=> s_axi_intr_rresp,
		S_AXI_RVALID	=> s_axi_intr_rvalid,
		S_AXI_RREADY	=> s_axi_intr_rready,
		irq	=> irq
	);

	fifo_stream_controller_inst :  FIFO_SLAVE_STREAM_CONTROLLER 
    generic map(
        BRAM_ADDR_WIDTH  => BRAM_ADDR_WIDTH,
        BRAM_DATA_WIDTH  => BRAM_DATA_WIDTH
        )
    port map(
        -- BRAM write port lines
        addra => addra,
        dina  => dina,
        ena   => ena,
        wea   => wea,
        rsta  => rsta,
        
        -- BRAM read port lines
        addrb => addrb,
        doutb => doutb,
        enb   => enb,
        rstb  => rstb,

        -- AXIS Slave Stream Ports
        S_AXIS_TREADY  => S_AXIS_TREADY,
        S_AXIS_TDATA   => S_AXIS_TDATA,
        S_AXIS_TVALID  => S_AXIS_TVALID,
        
        -- axil done line
        axil_read_done => s_axil_read_done,
        axil_dvalid    => s_axil_dvalid,

        -- fifo control lines
        clk            => s00_axi_aclk,
        clkEn          => axil_clkEn,
        reset          => axil_reset,
        fifo_full      => bram_full,
        fifo_empty     => bram_empty,
        fifo_occupancy => bram_occupancy,
        fifo_read_en   => axil_read_en,
        fifo_dout      => axil_dout,
        irq_set_value  => irq_set_value,
        irq_out_pulse  => irq_pulse,
        irq_en         => irq_en
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

end arch_imp;
