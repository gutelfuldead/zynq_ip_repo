library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity AXI_MASTER_STREAM is
	generic (
		-- Width of S_AXIS address bus.
		C_M_AXIS_TDATA_WIDTH	: integer	:= 32
	);
	port (
		-- the data to be streamed
		user_din    : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- '1' when user_din is valid
		user_dvalid : in std_logic; 
		-- '1' when the transaction has completed
		user_txdone : out std_logic;
		-- Global ports
		M_AXIS_ACLK	: in std_logic;
		-- Active Low Synchronous Reset
		M_AXIS_ARESETN	: in std_logic;
		-- Master Stream Ports. TVALID indicates that the master is driving a valid transfer, A transfer takes place when both TVALID and TREADY are asserted. 
		M_AXIS_TVALID	: out std_logic;
		-- TDATA is the primary payload that is used to provide the data that is passing across the interface from the master.
		M_AXIS_TDATA	: out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
		-- TSTRB is the byte qualifier that indicates whether the content of the associated byte of TDATA is processed as a data byte or a position byte.
		M_AXIS_TSTRB	: out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
		-- TLAST indicates the boundary of a packet.
		M_AXIS_TLAST	: out std_logic;
		-- TREADY indicates that the slave can accept a transfer in the current cycle.
		M_AXIS_TREADY	: in std_logic
	);
end AXI_MASTER_STREAM;

architecture implementation of AXI_MASTER_STREAM is

	type state is (IDLE, SEND_STREAM);
	signal fsm : state := IDLE;
	
	--streaming data valid
	signal axis_tvalid	: std_logic;
	--streaming data valid delayed by one clock cycle
	signal axis_tvalid_delay	: std_logic;
	--Last of the streaming data 
	signal axis_tlast	: std_logic;
	--Last of the streaming data delayed by one clock cycle
	signal axis_tlast_delay	: std_logic;
	--FIFO implementation signals
	signal stream_data_out	: std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);

begin
	-- I/O Connections assignments

	M_AXIS_TVALID	<= axis_tvalid;
	M_AXIS_TDATA	<= user_din;
	M_AXIS_TLAST	<= '0';
	M_AXIS_TSTRB	<= (others => '1');


	-- Control state machine implementation                                               
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      -- Synchronous reset (active low)                                                     
	      fsm      <= IDLE;                                                          
	    else                                                                                    
	      case (fsm) is                                                              
	        when IDLE     =>   
	        	user_txdone <= '0';
	        	if(user_dvalid = '1') then
	        		fsm <= SEND_STREAM;   
        		end if;   			
	        when SEND_STREAM   =>  
	        	if(M_AXIS_TREADY = '1' and axis_tvalid = '1') then
	        		fsm <= IDLE;
	        		user_txdone <= '1';
        		end if;
	        when others    =>                                                                   
	          fsm <= IDLE;                                                           
	                                                                                            
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;                                                                                


	--tvalid generation
	--axis_tvalid is asserted when the control state machine's state is SEND_STREAM and
	--number of output streaming data is less than the NUMBER_OF_OUTPUT_WORDS.
	axis_tvalid <= '1' when (fsm = SEND_STREAM) else '0';
	                                                                                                           	                                                                                                                                                                                

end implementation;
