library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXIS_MONITOR_v1_0 is
	generic (
		AXIS_DWIDTH : integer := 8;
		AXIS_UWIDTH : integer := 8;
		S_TUSER_EN : boolean := true;
		S_TUSER_BIT_ON : integer := 0;
		S_TUSER_BIT_LEVEL : std_logic := '1';

		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4
	);
	port (
    	S_AXIS_TDATA  : in std_logic_vector(AXIS_DWIDTH-1 downto 0);
    	S_AXIS_TUSER  : in std_logic_vector(AXIS_UWIDTH-1 downto 0);
    	S_AXIS_TREADY : out std_logic;
    	S_AXIS_TVALID : in std_logic;

    	M_AXIS_TDATA  : out std_logic_vector(AXIS_DWIDTH-1 downto 0);
    	M_AXIS_TUSER  : out std_logic_vector(AXIS_UWIDTH-1 downto 0);
    	M_AXIS_TREADY : in std_logic;
    	M_AXIS_TVALID : out std_logic;


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
end AXIS_MONITOR_v1_0;

architecture arch_imp of AXIS_MONITOR_v1_0 is

	-- component declaration
	component AXIS_MONITOR_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
		axil_reset  : out std_logic;
		tvalid_cnt  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		tuser_bit_cnt  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
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
	end component AXIS_MONITOR_v1_0_S00_AXI;

	signal tvalid_cnt    : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal tuser_bit_cnt : unsigned(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');
	signal reset, axil_reset : std_logic := '0';

begin
	reset <= (not s00_axi_aresetn) or axil_reset;

	S_AXIS_CAPTURE : process(s00_axi_aclk, reset)
		type states is (ST_IDLE, ST_SYNC);
		variable fsm : states := ST_IDLE;
	begin
	if (reset = '1') then
		fsm := ST_IDLE;
		tvalid_cnt <= (others => '0');
		tuser_bit_cnt <= (others => '0');
		S_AXIS_TREADY <= '0';
		M_AXIS_TUSER  <= (others => '0');
		M_AXIS_TDATA  <= (others => '0');
		M_AXIS_TVALID <= '0';
	elsif(rising_edge(s00_axi_aclk)) then
	case (fsm) is
		when ST_IDLE =>
			if(S_AXIS_TVALID = '1') then
				tvalid_cnt <= tvalid_cnt + 1;
				S_AXIS_TREADY <= '1';
				M_AXIS_TVALID <= '1';
				M_AXIS_TDATA  <= S_AXIS_TDATA;
				if(S_TUSER_EN = true) then
					M_AXIS_TUSER <= S_AXIS_TUSER;
					if(S_AXIS_TUSER(S_TUSER_BIT_ON) = S_TUSER_BIT_LEVEL) then
						tuser_bit_cnt <= tuser_bit_cnt + 1;
					end if;
				end if;
				fsm := ST_SYNC;
			end if;

		when ST_SYNC =>
			S_AXIS_TREADY <= '0';
			if(M_AXIS_TREADY = '1') then
				M_AXIS_TDATA  <= (others => '0');
				M_AXIS_TUSER  <= (others => '0');
				M_AXIS_TVALID <= '0';
				fsm := ST_IDLE;
			end if;

	end case;
	end if;
	end process S_AXIS_CAPTURE;

-- Instantiation of Axi Bus Interface S00_AXI
AXIS_MONITOR_v1_0_S00_AXI_inst : AXIS_MONITOR_v1_0_S00_AXI
	generic map (
		C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
	)
	port map (
		axil_reset => axil_reset,
		tvalid_cnt    => std_logic_vector(tvalid_cnt),
		tuser_bit_cnt => std_logic_vector(tuser_bit_cnt),
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


end arch_imp;
