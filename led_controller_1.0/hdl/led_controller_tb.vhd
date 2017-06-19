library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_controller_tb is
end led_controller_tb;

architecture tb of led_lcontroller_tb is

	component led_controller is
		generic(
			NUM_LEDS : integer := 7;
			CYCLES_ON : integer := 250000
			);
		port(
			clk : in std_logic;
			en  : in std_logic;
			rst : in std_logic;
			led_ctrl : in  std_logic_vector(NUM_LEDS-1 downto 0);
	        led_out  : out std_logic_vector(NUM_LEDS-1 downto 0)
	        );
	end component led_controller;

	constant NUM_LEDS : integer := 7;
	constant CYCLES_ON : integer := 250000;
	signal clk, en, rst : std_logic := '0';
	signal led_ctrl : std_logic_vector(NUM_LEDS-1 downto 0) := (others => '0');
	signal led_out : std_logic_vector(NUM_LEDS-1 downto 0) := (others => '0');
    constant clk_period : time := 10 ns; -- 100 MHz clock

begin

	UUT : led_controller
	port map(
		clk => clk,
		en  => en,
		rst => rst,
		led_ctrl => led_ctrl,
		led_out => led_out
		);

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;

    tb : process
    begin
    	wait for clk_period;
    	rst <= '1';
    	wait for clk_period;
    	rst <= '0';
    	en  <= '1';
    	wait for clk_period*2;	
    	led_ctrl(1) <= '1';
    	led_ctrl(3) <= '1';
    	wait for clk_period*10;
    	led_ctrl(1) <= '0';
    	led_ctrl(3) <= '0';
    	wait for clk_period*10000000;
    end process tb;

end tb;