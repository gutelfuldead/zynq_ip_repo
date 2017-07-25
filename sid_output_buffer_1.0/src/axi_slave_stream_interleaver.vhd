----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: axi_slave_stream
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description:  AXI4-Stream Slave Controller Interface
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

entity axi_slave_stream_interleaver is
	generic (
		-- Width of S_AXIS address bus.		
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- control ports
		-- top level is ready for new data
		user_rdy    : in std_logic;
		-- '1' when the user_data line has valid data
        user_dvalid : out std_logic;
        -- '1' when data is received (not necessarily valid)
        user_drecv  : out std_logic;
        -- the received transactional data
        user_data   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
        -- '1' when the interface is ready for a new transaction
    	axis_rdy    : out std_logic;
    	-- '1' when the last transaction is complete
    	axis_last   : out std_logic;
    	-- global AXI-Stream Slave ports
		S_AXIS_ACLK	: in std_logic;
		S_AXIS_ARESETN	: in std_logic;
		S_AXIS_TREADY	: out std_logic;
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		S_AXIS_TLAST	: in std_logic;
		S_AXIS_USR_RDY  : in std_logic;
		S_AXIS_TVALID	: in std_logic
	);
end axi_slave_stream_interleaver;

architecture arch_imp of axi_slave_stream_interleaver is
	type state is ( ST_IDLE, ST_READ);
    signal fsm : state := ST_IDLE;

begin

	-------------------------------------------------------------------
	-- AXI Slave Stream Controller Process (Async. Reset)
	-------------------------------------------------------------------
	-- Module asserts a ready bit to inform the top module that
	-- it is ready to receive data. The top module then indicates
	-- that it is ready to receive data form the interface.
	-- The interface will then wait until the S_AXIS_TVALID line
	-- is asserted high, it will then take the data off of the line and
	-- assert the S_AXIS_TREADY line to acknowledge the read
	-------------------------------------------------------------------
	stream_slave : process(S_AXIS_ACLK,S_AXIS_ARESETN)
	begin
	if(S_AXIS_ARESETN = '0') then
		fsm         <= ST_IDLE;
		user_dvalid <= '0';
		S_AXIS_TREADY    <= '0';
		axis_last <= '0';
	elsif (rising_edge (S_AXIS_ACLK)) then
	  	case (fsm) is

	        when ST_IDLE     => 
				axis_rdy <= '1';
				S_AXIS_TREADY <= '0';
				user_dvalid   <= '0';
				user_drecv    <= '0';
				if (user_rdy = '1') then
					fsm <= ST_READ;
				end if;

	        when ST_READ => 
	        	axis_rdy <= '0';
	        	if(S_AXIS_TVALID = '1') then
					S_AXIS_TREADY <= '1';
					user_drecv <= '1';
					if(S_AXIS_USR_RDY = '1') then
	                    user_data     <= S_AXIS_TDATA;	
						user_dvalid   <= '1';
					end if;
					fsm <= ST_IDLE;
					axis_last <= S_AXIS_TLAST;
				end if; 

	        when others => 
          		fsm <= ST_IDLE;

	  	end case;
	end if;
	end process stream_slave;

end arch_imp;
