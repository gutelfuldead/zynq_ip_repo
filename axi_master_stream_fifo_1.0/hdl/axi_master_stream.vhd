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
		-- '1' when core is ready to start a new transaction
		axis_rdy : out std_logic;
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

	type state is (ST_IDLE, ST_WRITE);
	signal fsm : state := ST_IDLE;
	
begin

	----------------------------------------------
	-- un-used interface ports set to constants --
	----------------------------------------------
	M_AXIS_TLAST	<= '0';
	M_AXIS_TSTRB	<= (others => '1');
    
    ----------------------------------
	-- axi4-stream master interface --
    ----------------------------------
    stream_master : process(M_AXIS_ACLK)
    begin
    if(rising_edge(M_AXIS_ACLK)) then
    	if(M_AXIS_ARESETN = '0') then
    		fsm <= ST_IDLE;
    		user_txdone <= '0';
    		M_AXIS_TVALID <= '0';
			M_AXIS_TDATA  <= (others => '0');
		else
			case(fsm) is
			when ST_IDLE =>
				user_txdone <= '0';
				axis_rdy <= '1';
				if(user_dvalid = '1') then
					fsm <= ST_WRITE;
					M_AXIS_TVALID <= '1';
					M_AXIS_TDATA  <= user_din;
				end if;
			when ST_WRITE =>
				axis_rdy <= '0';
				if(M_AXIS_TREADY = '1') then
					user_txdone   <= '1';
					M_AXIS_TVALID <= '0';
					M_AXIS_TDATA  <= (others => '0');
					fsm <= ST_IDLE;
				end if;
			when others =>
				fsm <= ST_IDLE;
			end case;
		end if;
    end if;
    end process stream_master;

end implementation;
