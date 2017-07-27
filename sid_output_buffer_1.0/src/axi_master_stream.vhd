----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: axi_master_stream
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description:  AXI4-Stream Master Controller Interface
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
use ieee.numeric_std.all;

entity AXI_MASTER_STREAM is
  generic (
    -- Width of S_AXIS address bus.
    C_M_AXIS_TDATA_WIDTH  : integer := 32
  );
  port (
    -- the data to be streamed
    user_din    : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    -- '1' when user_din is valid
    user_dvalid : in std_logic; 
    -- '1' when the transaction has completed
    user_txdone : out std_logic;
    -- '1' when core is ready to start a new transaction
    axis_rdy : out std_logic;
    -- '1' when the last piece of data is passed
    axis_last : in std_logic;
    -- Global AXI-Stream Master Ports
    M_AXIS_ACLK : in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TSTRB  : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST  : out std_logic;
    M_AXIS_TREADY : in std_logic
  );
end AXI_MASTER_STREAM;

architecture implementation of AXI_MASTER_STREAM is

  type state is (ST_IDLE, ST_WRITE); --, ST_CLEAN);
  signal fsm : state := ST_IDLE;
  
begin

----------------------------------------------
-- un-used interface ports set to constants --
----------------------------------------------
M_AXIS_TSTRB  <= (others => '1');
    
------------------------------------------------------------------------
-- axi4-stream master interface (Async. Reset)
------------------------------------------------------------------------
-- interface asserts that it is ready to above module then waits on
-- a valid data bit. The data is then latched to the M_AXIS_TDATA line
-- and the M_AXIS_TVALID line is held high until the M_AXIS_TREADY line
-- is asserted
------------------------------------------------------------------------
  stream_master : process(M_AXIS_ACLK,M_AXIS_ARESETN)
  begin
  if(M_AXIS_ARESETN = '0') then
    fsm <= ST_IDLE;
    user_txdone <= '0';
    M_AXIS_TVALID <= '0';
    M_AXIS_TDATA  <= (others => '0');
    M_AXIS_TLAST <= '0';
  elsif(rising_edge(M_AXIS_ACLK)) then
    case(fsm) is

    when ST_IDLE =>
      user_txdone <= '0';
      axis_rdy <= '1';
      if(user_dvalid = '1') then
        fsm <= ST_WRITE;
        M_AXIS_TVALID <= '1';
        M_AXIS_TDATA  <= user_din;
        M_AXIS_TLAST  <= axis_last;
      end if;

    when ST_WRITE =>
      axis_rdy <= '0';
      if(M_AXIS_TREADY = '1') then
        user_txdone   <= '1';
        M_AXIS_TVALID <= '0';
        M_AXIS_TLAST  <= '0';
        M_AXIS_TDATA  <= (others => '0');
        fsm <= ST_IDLE;
      end if;

    when others =>
      fsm <= ST_IDLE;

    end case;
  end if;
  end process stream_master;

end implementation;