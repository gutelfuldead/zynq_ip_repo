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
        fifo_dout      : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0)
		);
end FIFO_SLAVE_STREAM_CONTROLLER;

architecture Behavorial of FIFO_SLAVE_STREAM_CONTROLLER is
    
    -- fifo signals
    signal sig_fifo_empty     : std_logic := '0';
    signal sig_fifo_full      : std_logic := '0';
    signal sig_fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal WriteEn :   STD_LOGIC;
    signal DataIn  :   STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);

begin

    fifo_full <= sig_fifo_full;
    fifo_empty <= sig_fifo_empty;
    fifo_occupancy <= sig_fifo_occupancy;

	-- Instantiation of FIFO Controller
  bram_fifo_controller_v2_inst : bram_fifo_controller_v2
      generic map( 
          BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
          BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
      port map (
          addra => addra,
          dina  => dina,
          ena   => ena,
          wea   => wea,
          rsta  => rsta,
          addrb => addrb,
          doutb => doutb,
          enb   => enb,
          rstb  => rstb,
          
          clk        => clk,
          reset      => reset,
          WriteEn    => WriteEn,
          DataIn     => DataIn,
          ReadEn     => fifo_read_en,
          DataOut    => fifo_dout,
          DataOutValid => axil_dvalid,
          Empty      => sig_fifo_empty,
          Full       => sig_fifo_full,
          SetProgFull => (others => '1'),
          ProgFullPulse => open,
          Occupancy => sig_fifo_occupancy
      );
	    
    --------------------------------------------------------------------
    -- Stream and FIFO write controller (Async. Reset)
    --------------------------------------------------------------------
    -- Waits for the AXI-Stream module to be ready and for the FIFO
    -- to be ready to accept new data. Will then enable the AXI-Stream
    -- and wait for the valid data to be returned. The data will then be
    -- written to the FIFO
    --------------------------------------------------------------------
    fifo_write : process(clk, reset)
        type state is (ST_IDLE, ST_SYNC);
        variable fsm : state := ST_IDLE;
    begin
    if(reset = '1') then
        fsm           := ST_IDLE;
        S_AXIS_TREADY <= '0';
        WriteEn       <= '0';
    elsif(rising_edge(clk)) then
        if(clkEn = '1') then
            case(fsm) is

            when ST_IDLE =>
                if(S_AXIS_TVALID = '1' and sig_fifo_full = '0') then
                    DataIn  <= S_AXIS_TDATA;
                    WriteEn <= '1';
                    S_AXIS_TREADY <= '1';
                    fsm           := ST_SYNC;
                end if;
            
            when ST_SYNC =>
                WriteEn       <= '0';
                S_AXIS_TREADY <= '0';
                fsm               := ST_IDLE;
            
            when others =>
                fsm := ST_IDLE;
            end case;
        end if;
    end if;
    end process fifo_write;

end Behavorial;