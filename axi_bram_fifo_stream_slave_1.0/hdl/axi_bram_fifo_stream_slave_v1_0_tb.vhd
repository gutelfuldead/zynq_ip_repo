library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity axi_bram_fifo_stream_slave_v1_0_tb is
    generic (BRAM_ADDR_WIDTH  : integer := 10);
end axi_bram_fifo_stream_slave_v1_0_tb;

architecture Behavioral of axi_bram_fifo_stream_slave_v1_0_tb is

component axi_bram_fifo_stream_slave_v1_0 is
	generic (
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32;
		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH    : integer   := 4;
		-- Parameters of Axi Stream Slave Bus Interface
        C_S_AXIS_TDATA_WIDTH	: integer	:= 32
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
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
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
		s00_axi_rready	: in std_logic
	);
end component axi_bram_fifo_stream_slave_v1_0;

begin

UUT : axi_bram_fifo_stream_slave_v1_0
	port map (
		-- BRAM write port lines
		addra => open, --: out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
		dina  => open, --: out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
		ena   => open, --: out STD_LOGIC;
		wea   => open, --: out STD_LOGIC;
		clka  => open, --: out std_logic;
		rsta  => open, --: out std_logic;

		-- BRAM read port lines
		addrb => open, --: out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
		doutb => open, --: in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
		enb   => open, --: out STD_LOGIC;
		clkb  => open, --: out std_logic;
		rstb  => open, --: out std_logic;

		-- AXIS slave ports
		S_AXIS_ACLK	    => open, --: in std_logic;
		S_AXIS_ARESETN	=> open, --: in std_logic;
		S_AXIS_TREADY	=> open, --: out std_logic;
		S_AXIS_TDATA	=> open, --: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	=> open, --: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	=> open, --: in std_logic;
		S_AXIS_TVALID	=> open, --: in std_logic;

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
end axi_bram_fifo_stream_slave_v1_0;