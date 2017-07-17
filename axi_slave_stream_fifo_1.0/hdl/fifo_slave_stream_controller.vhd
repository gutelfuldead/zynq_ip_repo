----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Package Name: fifo_slave_stream_controller
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: Module that reads data from an upstream AXI4-Stream device and 
--   write to an attached Dual-Port BRAM. Will accept read requests from a
--   AXI4-Lite interface and return data from the FIFO pointer to the BRAM.
-- 
--   Generics allow for alternate BRAM Data Width and BRAM Address Width. 
--   The data width of the AXI-Stream interface is the same as the BRAM
--   data width.
--
-- Dependencies: bram_fifo_controller.vhd and axi_slave_stream.vhd
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity FIFO_SLAVE_STREAM_CONTROLLER is
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
        clka  : out std_logic;
        rsta  : out std_logic;
        
        -- BRAM read port lines
        addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
        doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
        enb   : out STD_LOGIC;
        clkb  : out std_logic;
        rstb  : out std_logic;
        
        --AXIL Read Control Ports
        axil_dvalid    : out std_logic; -- assert to axi4-lite interface data is ready
        axil_read_done : in std_logic;  -- acknowledgment from axi4-lite iface data has been read
        
        -- AXIS Slave Stream Ports
        S_AXIS_ACLK : in std_logic;
        S_AXIS_ARESETN  : in std_logic;
        S_AXIS_TREADY   : out std_logic;
        S_AXIS_TDATA    : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        S_AXIS_TSTRB    : in std_logic_vector((BRAM_DATA_WIDTH/8)-1 downto 0);
        S_AXIS_TLAST    : in std_logic;
        S_AXIS_TVALID   : in std_logic;

        -- fifo control lines
        clk            : in std_logic;
        clkEn          : in std_logic;
        reset          : in std_logic;
        fifo_full      : out std_logic;
        fifo_empty     : out std_logic;
        fifo_occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fifo_read_en   : in  std_logic;
        fifo_dout      : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0)
		);
end FIFO_SLAVE_STREAM_CONTROLLER;

architecture Behavorial of FIFO_SLAVE_STREAM_CONTROLLER is
    
    -- axi-lite signals
    signal sig_axil_dvalid : std_logic := '0';
    
    -- axi-stream signals
    signal sig_axis_dout      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
    signal sig_axis_dvalid    : std_logic := '0';
    signal sig_axis_txdone    : std_logic := '0';
    signal sig_axis_rdy       : std_logic := '0';
    signal sig_controller_rdy : std_logic := '0';

    -- fifo signals
    signal sig_fifo_empty     : std_logic := '0';
    signal sig_fifo_full      : std_logic := '0';
    signal sig_fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal sig_fifo_write_en  : std_logic := '0';
    signal sig_fifo_din       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
    signal sig_fifo_dvalid    : std_logic := '0';
    signal sig_fifo_dout      : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
    signal sig_fifo_read_ready : std_logic := '0';
    signal sig_fifo_write_ready : std_logic := '0';
    signal sig_fifo_read : std_logic := '0';

    -- state machine signals
    type state is (ST_IDLE, ST_ACTIVE, ST_WAIT);
    signal fsm : state := ST_IDLE;

begin

	-- Instantiation of FIFO Controller
	bram_fifo_controller_inst : BRAM_FIFO_CONTROLLER
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
	        write_en   => sig_fifo_write_en,
	        reset      => reset,
	        din        => sig_fifo_din,
	        read_en    => sig_fifo_read,
            read_ready => sig_fifo_read_ready,
            write_ready => sig_fifo_write_ready,
	        dout       => sig_fifo_dout,
	        dvalid     => sig_fifo_dvalid,
	        full       => fifo_full,
	        empty      => fifo_empty,
	        occupancy  => fifo_occupancy 
	    );
	    
	-- Instantiation of Slave Stream Interface
    axi_slave_stream_inst : AXI_SLAVE_STREAM
        generic map(
            C_S_AXIS_TDATA_WIDTH => BRAM_DATA_WIDTH
            )
        port map(
            user_rdy       => sig_controller_rdy,
            user_dvalid    => sig_axis_dvalid,
            user_data      => sig_axis_dout,
            axis_rdy       => sig_axis_rdy,
            S_AXIS_ACLK    => S_AXIS_ACLK,
            S_AXIS_ARESETN => S_AXIS_ARESETN,
            S_AXIS_TREADY  => S_AXIS_TREADY,
            S_AXIS_TDATA   => S_AXIS_TDATA,
            S_AXIS_TSTRB   => S_AXIS_TSTRB,
            S_AXIS_TLAST   => S_AXIS_TLAST,
            S_AXIS_TVALID  => S_AXIS_TVALID
            );

	axil_dvalid    <= sig_axil_dvalid;    

    -------------------------------------------------------------------------
    -- FIFO Read Controller (Async. Reset)
    -------------------------------------------------------------------------
    -- takes an input read request pulse (fifo_read_en) and waits for the
    -- FIFO to become synchronized. The request will then be sent to the FIFO
    -- and the controller will wait until the data line is asserted valid
    -- by the FIFO. The controller will then assert that the data is valid to
    -- the top module and wait for a confirmation that it has been read
    -------------------------------------------------------------------------
    read_ctrl : process(clk, reset)
        type fsm_states is (ST_IDLE, ST_SYNC, ST_ACTIVE, ST_WAIT);
        variable fsm : fsm_states := ST_IDLE;
    begin
    if(reset = '1') then
        sig_axil_dvalid <= '0';
        fifo_dout <= (others => '0');
        fsm := ST_IDLE;
    elsif(rising_edge(clk)) then
        case (fsm) is
            when ST_IDLE =>
                fifo_dout <= (others => '0');
                if(fifo_read_en = '1') then
                    fsm := ST_SYNC;
                end if;

            when ST_SYNC =>
                if(sig_fifo_read_ready = '1') then
                    sig_fifo_read <= '1';
                    fsm := ST_ACTIVE;
                end if;

            when ST_ACTIVE =>
                sig_fifo_read <= '0';
                if(sig_fifo_dvalid = '1') then
                    sig_axil_dvalid <= '1';
                    fifo_dout <= sig_fifo_dout;
                    fsm := ST_WAIT;
                end if;

            when ST_WAIT =>
                if(axil_read_done = '1') then
                    fsm := ST_IDLE;
                    sig_axil_dvalid <= '0';
                end if;

        end case;

    end if;
    end process;

    --------------------------------------------------------------------
    -- Stream and FIFO write controller (Async. Reset)
    --------------------------------------------------------------------
    -- Waits for the AXI-Stream module to be ready and for the FIFO
    -- to be ready to accept new data. Will then enable the AXI-Stream
    -- and wait for the valid data to be returned. The data will then be
    -- written to the FIFO
    --------------------------------------------------------------------
    fifo_write : process(clk, reset)
    begin
    if(reset = '1') then
        fsm                <= ST_IDLE;
        sig_fifo_write_en  <= '0';
        sig_controller_rdy <= '0';
    elsif(rising_edge(clk)) then
        if(clkEn = '1') then
            case(fsm) is
            when ST_IDLE =>
                sig_fifo_write_en <= '0';
                if(sig_axis_rdy = '1' and sig_fifo_write_ready = '1') then
                    sig_controller_rdy <= '1';
                    fsm                <= ST_ACTIVE;
                end if;
            when ST_ACTIVE =>
                sig_controller_rdy <= '0';       
                if(sig_axis_dvalid = '1') then
                    sig_fifo_din      <= sig_axis_dout;
                    sig_fifo_write_en <= '1';
                    fsm               <= ST_IDLE;
                end if;
            when others =>
                fsm <= ST_IDLE;
            end case;
        end if;
    end if;
    end process fifo_write;

end Behavorial;