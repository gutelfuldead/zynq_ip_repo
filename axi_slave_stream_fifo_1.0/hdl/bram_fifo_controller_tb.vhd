library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.generic_pkg.all;

use IEEE.NUMERIC_STD.ALL;

entity bram_fifo_controller_tb is
end bram_fifo_controller_tb;

architecture Behavioral of bram_fifo_controller_tb is

	constant BRAM_ADDR_WIDTH  : integer := 10;    
	constant BRAM_DATA_WIDTH  : integer := 32;

	-- BRAM write port lines
	signal addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
	signal dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
	signal ena   : STD_LOGIC;
	signal wea   : STD_LOGIC;
	signal clka  : std_logic;
	signal rsta  : std_logic;
	
	-- BRAM read port lines
	signal addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
	signal doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
	signal enb   : STD_LOGIC;
	signal clkb  : std_logic;
	signal rstb  : std_logic;
	
	-- Core logic
	signal clk        : std_logic;
	signal clkEn      : std_logic;
	signal write_en   : std_logic;
	signal read_en    : std_logic;
	signal reset      : std_logic;
	signal din        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
	signal dout       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
	signal dvalid     : std_logic;
	signal full       : std_logic;
	signal empty      : std_logic;
	signal occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);

	constant clk_period : time := 10 ns; -- 100 MHz clock
	constant WRITE_WAIT : integer := 10;
	constant READ_WAIT : integer := WRITE_WAIT + WRITE_WAIT;

begin

	DUT : BRAM_FIFO_CONTROLLER
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
	        write_en   => write_en,
	        reset      => reset,
	        din        => din,
	        read_en    => read_en,
	        dout       => dout,
	        dvalid     => dvalid,
	        full       => full,
	        empty      => empty,
	        occupancy  => occupancy 
	    );

	clkEn <= '1';

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;
    
    rst_proc : process(clk)
       constant rst_cnt : integer := 200;
       variable cnt : integer range 0 to rst_cnt := rst_cnt;
    begin
       if(rising_edge(clk)) then
           if (cnt = rst_cnt) then
               reset <= '1';
               cnt := 0;
           else
               reset <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

   write_test : process(clk,reset)
   		variable data : integer := 1;
   		variable data_sent_asserted : std_logic := '0';
   		variable cnt : integer range 0 to WRITE_WAIT := 0;
   begin
   if(reset = '1') then
   		data := 1;
   		cnt := 0;
   		data_sent_asserted := '0';
   		write_en <= '0';
   elsif(rising_edge(clk)) then
   		if(full = '0' and data_sent_asserted = '0') then
   			din <= std_logic_vector(to_unsigned(data,BRAM_DATA_WIDTH));
   			write_en <= '1';
   			data_sent_asserted := '1';
		elsif(data_sent_asserted = '1') then
			write_en <= '0';
			if(cnt = WRITE_WAIT) then
				cnt := 0;
				data_sent_asserted := '0';
				data := data + 1;
			else
				cnt := cnt + 1;
			end if;
		else
			write_en <= '0';
		end if;

   end if;
   end process write_test;

   read_test : process(clk,reset)
   		variable data : integer := 1;
   		variable data_read_asserted : std_logic := '0';
   		variable cnt : integer range 0 to READ_WAIT := 0;
   begin
   if(reset = '1') then
   		data := 1;
   		cnt := 0;
   		data_read_asserted := '0';
   		read_en <= '0';
   elsif(rising_edge(clk)) then
   		if(empty = '0' and data_read_asserted = '0') then
   			doutb <= std_logic_vector(to_unsigned(data,BRAM_DATA_WIDTH));
   			read_en <= '1';
   			data_read_asserted := '1';
		elsif(data_read_asserted = '1') then
			read_en <= '0';
			if(dvalid = '1' or cnt = READ_WAIT) then
				data_read_asserted := '0';
				data := data + 1;
				cnt := 0;
			else
				cnt := cnt + 1;
			end if;
		else
			read_en <= '0';
		end if;

   end if;
   end process read_test;

end Behavioral;
