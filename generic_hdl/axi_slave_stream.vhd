library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_SLAVE_STREAM is
	generic (
		-- Width of S_AXIS address bus.		
		C_S_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- control ports
		-- top level is ready for new data
		user_rdy    : in std_logic;
		-- the user_data line has valid data
        user_dvalid : out std_logic;
        -- the received transactional data
        user_data   : out std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    	axis_rdy    : out std_logic;
    	-- global ports
		-- AXI4Stream sink: Clock
		S_AXIS_ACLK	: in std_logic;
		-- AXI4Stream sink: Reset
		S_AXIS_ARESETN	: in std_logic;
		-- Ready to accept data in
		S_AXIS_TREADY	: out std_logic;
		-- Data in
		S_AXIS_TDATA	: in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
		-- Byte qualifier
		S_AXIS_TSTRB	: in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- Indicates boundary of last packet
		S_AXIS_TLAST	: in std_logic;
		-- Data is in valid
		S_AXIS_TVALID	: in std_logic
	);
end AXI_SLAVE_STREAM;

architecture arch_imp of AXI_SLAVE_STREAM is

	type state is ( ST_IDLE, ST_READ);
    signal fsm : state := ST_IDLE;
	signal s_tready	: std_logic;

begin

	stream_slave : process(S_AXIS_ACLK)
	   constant MAX_CNT : integer := 4;
	   variable cnt : integer range 0 to MAX_CNT := 0;
	begin
	if (rising_edge (S_AXIS_ACLK)) then
		if(S_AXIS_ARESETN = '0') then
			fsm         <= ST_IDLE;
			user_dvalid <= '0';
			S_AXIS_TREADY    <= '0';
			cnt := 0;
		else
		  	case (fsm) is
		        when ST_IDLE     => 
					axis_rdy <= '1';
					S_AXIS_TREADY <= '0';
					user_dvalid   <= '0';
					if (user_rdy = '1') then
						fsm <= ST_READ;
					end if;
		        when ST_READ => 
		        	axis_rdy <= '0';
		        	if(S_AXIS_TVALID = '1') then
						S_AXIS_TREADY <= '1';
	                    user_data     <= S_AXIS_TDATA;	
						user_dvalid   <= '1';
						fsm <= ST_IDLE;
					end if;                    
		        when others => 
	          		fsm <= ST_IDLE;
		  	end case;
		end if;
	end if;
	end process stream_slave;

end arch_imp;
