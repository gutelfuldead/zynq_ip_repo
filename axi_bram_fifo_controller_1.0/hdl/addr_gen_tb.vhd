library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity addr_gen_tb is
    generic (BRAM_ADDR_WIDTH  : integer := 10);
end addr_gen_tb;

architecture Behavioral of addr_gen_tb is

	component fifo_addr_gen is
	    generic ( BRAM_ADDR_WIDTH  : integer := 10 );
	    Port ( clk : in STD_LOGIC;
	           en  : in STD_LOGIC;
	           rst : in STD_LOGIC;
	           rden : in STD_LOGIC;
	           wren : in STD_LOGIC;
	           rd_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
	           wr_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
	           fifo_empty : out std_logic;
	           fifo_full  : out std_logic;
	           fifo_occupancy : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0));
	end component fifo_addr_gen;

	signal clk            :  STD_LOGIC := '0';
	signal en             :  STD_LOGIC := '0';
	signal rst            :  STD_LOGIC := '0';
	signal rden           :  STD_LOGIC := '0';
	signal wren           :  STD_LOGIC := '0';
	signal rd_addr        :  STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal wr_addr        :  STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal fifo_occupancy :  STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
	signal fifo_empty     :  std_logic := '0';
	signal fifo_full      :  std_logic := '0';
	constant clk_period : time := 10 ns; -- 100 MHz clock


begin

	UUT : fifo_addr_gen
	generic map( BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH )
	port map(
		clk => clk,
		en  => en,
		rst => rst,
		rden => rden,
		wren => wren,
		rd_addr => rd_addr,
		wr_addr => wr_addr,
		fifo_empty => fifo_empty,
		fifo_full => fifo_full,
		fifo_occupancy => fifo_occupancy
	);	

	clk_process : process
	begin
		clk <= '1';
		wait for clk_period/2;
		clk <= '0';
		wait for clk_period/2;
	end process clk_process;

	tb : process()
		wait for clk_period;
		en  <= '1';
		rst <= '1';
		wait for clk_period*2;
		rden <= '1';
		wait for clk_period;
		rden <= '0';
		wren <= '1';
		wait for clk_period*10;
		wren <= '0';
		wait for clk_period*2;
		wren <= '1';
		rden <= '1';
		wait for clk_period*3;
		wren <= '0';
		wait for clk_period*3;
		rden <= '0';
	end process tb;


end Behavioral;
