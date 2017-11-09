library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.Vcomponents.all;

entity axi_bram_fifo_controller_v1_0 is
	generic (
		-- Users to add parameters here
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32;
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
        addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
        dina  : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
        ena   : out STD_LOGIC;
        wea   : out STD_LOGIC;
        clka  : out std_logic;
        rsta  : out std_logic;
    
        addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
        doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
        enb   : out STD_LOGIC;
        clkb  : out std_logic;
        rstb  : out std_logic;

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
end axi_bram_fifo_controller_v1_0;

architecture arch_imp of axi_bram_fifo_controller_v1_0 is

	-- component declaration
	component axi_bram_fifo_controller_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4;
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32
		);
		port (
        fifo_clkEn      : out std_logic;
        fifo_write_en   : out std_logic;
        fifo_read_en    : out std_logic;
        fifo_reset      : out std_logic;
        fifo_din        : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        fifo_dout       : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        fifo_dout_valid : in std_logic;
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
	end component axi_bram_fifo_controller_v1_0_S00_AXI;
	
	component FIFO_Controller is
           generic (
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
           dout_valid : out std_logic;
           bram_full  : out std_logic;
           bram_empty : out std_logic;
           bram_occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
           );
    end component FIFO_Controller;
    
    signal axi_clkEn           : std_logic;
    signal axi_write_en        : std_logic;
    signal axi_read_en         : std_logic;
    signal axi_reset           : std_logic;
    signal axi_din             : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal axi_dout            : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
    signal axi_dout_valid      : std_logic;
    signal axi_bram_full       : std_logic;
    signal axi_bram_empty      : std_logic;
    signal axi_bram_occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    signal s_clk : std_logic;

begin

-- Instantiation of FIFO Controller
axi_bram_fifo_controller_inst : FIFO_Controller
    generic map( BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
        BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
    port map (
        -- write ports
        addra => addra,
        dina  => dina,
        ena   => ena,
        wea   => wea,
        clka  => open,
        rsta  => rsta,
        -- read ports
        addrb => addrb,
        doutb => doutb,
        enb   => enb,
        clkb  => open,
        rstb  => rstb,
        -- control ports
        clk   => s00_axi_aclk,
        clkEn => axi_clkEn,
        write_en => axi_write_en,
        read_en  => axi_read_en,
        reset    => axi_reset,
        din      => axi_din,
        dout     => axi_dout,
        dout_valid => axi_dout_valid,
        bram_full  => axi_bram_full,
        bram_empty => axi_bram_empty,
        bram_occupancy => axi_bram_occupancy
    );

-- Instantiation of Axi Bus Interface S00_AXI
axi_bram_fifo_controller_v1_0_S00_AXI_inst : axi_bram_fifo_controller_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH,
		BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
        BRAM_DATA_WIDTH => BRAM_DATA_WIDTH
	)
	port map (
	    fifo_clkEn    => axi_clkEn,
	    fifo_write_en => axi_write_en,
	    fifo_read_en  => axi_read_en,
	    fifo_reset    => axi_reset,
	    fifo_din      => axi_din,
	    fifo_dout     => axi_dout,
	    fifo_dout_valid => axi_dout_valid,
	    fifo_bram_full => axi_bram_full,
	    fifo_bram_empty => axi_bram_empty,
	    fifo_bram_occupancy => axi_bram_occupancy,
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
            O => s_clk
        );

    clka <= s_clk;
    clkb <= s_clk;

end arch_imp;
