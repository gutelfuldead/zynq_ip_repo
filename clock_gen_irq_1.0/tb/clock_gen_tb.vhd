----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/16/2017 05:19:52 PM
-- Design Name: 
-- Module Name: clock_gen_tb - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity clock_gen_tb is
--  Port ( );
end clock_gen_tb;

architecture Behavioral of clock_gen_tb is

component clock_gen_irq_v1_0 is
	generic (
		-- Users to add parameters here
        input_freq : integer := 100000000;
        output_freq : integer := 10;
        ps_enable : string := "OFF" -- "ON"
	);
	port (
		-- Users to add ports here
        clk : in std_logic;
        led : out std_logic
        );
end component clock_gen_irq_v1_0;

    constant clk_period : time := 10 ns; -- 100 MHz clock
    signal clk,led : std_logic := '0';

begin

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;
    
    dut : clock_gen_irq_v1_0
    port map(
        clk => clk,
        led => led
    );


end Behavioral;
