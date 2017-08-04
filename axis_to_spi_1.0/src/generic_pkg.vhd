----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Package Name: generic_pkg
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: Contains component declarations for bram_fifo_controller,
--	axi_master_stream, axi_slave_stream
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
	use ieee.std_logic_1164.all;
	use ieee.std_logic_unsigned.all;

package generic_pkg is

--------------------------------------------------------------------------
--------------------------- COMPONENTS -----------------------------------
--------------------------------------------------------------------------

	--------------------------------------
    -- Turns dual port BRAM into a FIFO --
	--------------------------------------
	component BRAM_FIFO_CONTROLLER is
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
               write_ready  : out std_logic;
               read_ready   : out std_logic;
	           din        : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
	           dout       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
	           dvalid     : out std_logic;
	           full       : out std_logic;
	           empty      : out std_logic;
	           occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
	           );
	end component BRAM_FIFO_CONTROLLER;

    ------------------------------------------
    -- Generic AXI4-Stream Master Interface --
    ------------------------------------------
    component AXI_MASTER_STREAM is
	generic ( C_M_AXIS_TDATA_WIDTH	: integer	:= 32 );
	port ( -- control ports
		user_din    : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		user_dvalid : in std_logic; 
		user_txdone : out std_logic;
		axis_rdy    : out std_logic;
		axis_last   : in std_logic;
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
		axis_rdy    : out std_logic;
		axis_last   : out std_logic;
		-- global ports
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_TVALID	: in std_logic);
	end component AXI_SLAVE_STREAM;
	
	----------------------------------
	-- generates a pulse from an input
	----------------------------------
	component pulse_generator is
		generic (
		ACTIVE_LEVEL : string := "HIGH" -- "LOW"
    	);
		port (
        clk       : in std_logic;
        sig_in    : in std_logic;
        pulse_out : out std_logic
		);
	end component pulse_generator;

	-----------------------------------------------------
	-- spi master interface (uni-directional xactions) --
	-----------------------------------------------------
	component spi_master is
        generic (
            INPUT_CLK_MHZ : integer := 100;
            SPI_CLK_MHZ   : integer := 10;
            DSIZE         : integer := 8
        );
        Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               sclk : out STD_LOGIC;
               sclk_en : out STD_LOGIC;
               mosi : out STD_LOGIC;
               din  : in std_logic_vector(DSIZE-1 downto 0);
               rdy  : out std_logic;
               dvalid : in std_logic 
               );
    end component spi_master;

end generic_pkg;
