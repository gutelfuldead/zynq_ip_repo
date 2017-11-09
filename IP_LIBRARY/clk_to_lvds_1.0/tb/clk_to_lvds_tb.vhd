----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09/16/2017 03:02:50 PM
-- Design Name: 
-- Module Name: clk_to_lvds_tb - Behavioral
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

entity clk_to_lvds_tb is
--  Port ( );
end clk_to_lvds_tb;

architecture Behavioral of clk_to_lvds_tb is

  constant clk_period : time := 10 ns; -- 100 MHz clock


component clk_to_lvds_v1_0 is
	port (
        clk_in  : in std_logic;
        clk_out_p : out std_logic;
        clk_out_n : out std_logic
	);
end component clk_to_lvds_v1_0;

signal clk_in, clk_out_p, clk_out_n : std_logic := '0';

begin

dut : clk_to_lvds_v1_0
port map(
    clk_in => clk_in,
    clk_out_p => clk_out_p,
    clk_out_n => clk_out_n
);

    clk_proc : process
    begin
        clk_in <= '1';
        wait for clk_period/2;
        clk_in <= '0';
        wait for clk_period/2;
    end process clk_proc;


end Behavioral;
