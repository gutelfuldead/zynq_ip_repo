----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Package Name: fifo_master_stream_controller
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description: Module that takes data from AXI4-Lite interface with associated
--  device drivers and writes them to a dual port BRAM FIFO. Has independent 
--  AXI4-Stream interface that will read from the FIFO and pass the data to the
--  downstream slave device independently.
--
--  Generics for setting the BRAM Address and Data Widths. The Data Width of the
--  AXI-Stream Master interface is equal to the BRAM Data Width.
-- 
-- Dependencies: bram_fifo_controller.vhd and axi_master_stream.vhd
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

entity FIFO_MASTER_STREAM_CONTROLLER is
	generic (
        USE_WRITE_COMMIT : string := "ENABLE"; -- "DISABLE"
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

        -- AXI Master Stream Ports
        M_AXIS_TVALID   : out std_logic;
        M_AXIS_TDATA    : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        M_AXIS_TREADY   : in std_logic;

        -- fifo control lines
        clk            : in std_logic;
        clkEn          : in std_logic;
        reset          : in std_logic;
        fifo_din       : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        fifo_write_en  : in std_logic;
        fifo_full      : out std_logic;
        fifo_empty     : out std_logic;
        fifo_occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fifo_ready     : out std_logic;
        write_commit   : in std_logic
		);
end FIFO_MASTER_STREAM_CONTROLLER;

architecture Behavorial of FIFO_MASTER_STREAM_CONTROLLER is

    -- fifo status, control, and data signals
    signal ReadEn  :   STD_LOGIC;
    signal DataOut :  STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);
    signal Empty   :  STD_LOGIC;
    signal Full    :  STD_LOGIC;
    signal DataOutValid : std_logic;
begin

    -- Instantiation of FIFO Controller
    BRAM_FIFO_CONTROLLER_v2_inst : BRAM_FIFO_CONTROLLER_v2
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
            WriteEn    => fifo_write_en,
            DataIn     => fifo_din,
            ReadEn     => ReadEn,
            DataOut    => DataOut,
            DataOutValid => DataOutValid,
            Empty      => Empty,
            Full       => Full,
            SetProgFull => (others => '1'),
            ProgFullPulse => open,
            Occupancy => fifo_occupancy
        );

    fifo_full <= Full;
    fifo_empty <= Empty;
    fifo_ready <= '1' when (Full = '0') else '0';
    --------------------------------------------------------------------------
    -- Stream and FIFO read controller (Async. Reset)
    --------------------------------------------------------------------------
    -- Checks if the AXIS interface is ready and if the FIFO is ready to read
    -- Then will pass the current FIFO address data to the AXIS interface
    -- Will wait for confirmation of transmission then move to the next
    -- FIFO address data
    --------------------------------------------------------------------------
    axis_read_ctrl : process(clk, reset) 
        type state is (ST_IDLE, ST_GET_DATA, ST_CHECK_FIFO, ST_AXIS);
        variable fsm : state := ST_IDLE;
    begin
    if(reset = '1') then
        if(USE_WRITE_COMMIT = "ENABLE") then
            fsm := ST_IDLE;
        else
            fsm := ST_CHECK_FIFO;
        end if;
        ReadEn <= '0';
        M_AXIS_TDATA <= (others => '0');
        M_AXIS_TVALID <= '0';
    elsif(rising_edge(clk)) then
        if(clkEn = '1') then
            case(fsm) is

            when ST_IDLE =>
                if(USE_WRITE_COMMIT = "ENABLE") then
                    if(write_commit = '1') then
                        fsm := ST_CHECK_FIFO;
                    end if;
                else
                    fsm := ST_CHECK_FIFO;
                end if;

            when ST_CHECK_FIFO =>
                if(Empty = '0') then
                    ReadEn <= '1';
                    fsm := ST_GET_DATA;
                end if;
            
            when ST_GET_DATA =>
                ReadEn <= '0';
                if(DataOutValid = '1') then
                    M_AXIS_TDATA    <= DataOut;
                    M_AXIS_TVALID   <= '1';
                    fsm := ST_AXIS;
                end if;

            when ST_AXIS =>
                if(M_AXIS_TREADY = '1') then
                    M_AXIS_TDATA    <= (others => '0');
                    M_AXIS_TVALID   <= '0';
                    if(USE_WRITE_COMMIT = "ENABLE") then
                        if(Empty = '1') then
                            fsm := ST_IDLE;
                        else
                            fsm := ST_CHECK_FIFO;
                        end if;
                    else
                        fsm := ST_CHECK_FIFO;
                    end if;
                end if;

            when others =>
                fsm := ST_IDLE;

            end case;
        end if;
    end if;
    end process axis_read_ctrl;

end Behavorial;