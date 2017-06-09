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

	type state is ( IDLE, READ_STATE );
    signal fsm : state := IDLE;
	signal s_tready	: std_logic;
	signal s_user_data : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);

begin
	-- I/O Connections assignments
	s_tready <= '1' when ((fsm = READ_STATE) and (user_rdy = '1')) else '0';
	S_AXIS_TREADY	<= s_tready;
	
	-- Control state machine implementation
	process(S_AXIS_ACLK)
	begin
	  if (rising_edge (S_AXIS_ACLK)) then
	  	if(S_AXIS_ARESETN = '0') then
	  		fsm    <= IDLE;
	  		user_dvalid <= '0';
  		else
	      	case (fsm) is
		        when IDLE     => 
		          user_dvalid <= '0';
		          if (S_AXIS_TVALID = '1')then
		            fsm <= READ_STATE;
		          else
		            fsm <= IDLE;
		          end if;
		        when READ_STATE => 
		          if(s_tready = '1') then
	                  user_data <= S_AXIS_TDATA;
	                  user_dvalid <= '1';
	                  fsm <= IDLE;
	              end if;
		        when others    => 
		          fsm <= IDLE;
	      	end case;
	  end if;
	end process;

end arch_imp;
