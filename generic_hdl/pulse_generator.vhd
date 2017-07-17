----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 07/17/2017
-- Design Name: 
-- Module Name: pulse_generator
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description:  Generates a pulse from an input signal of arbitrary duration that
--   transitions from logic LOW to logic HIGH
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

entity pulse_generator is
	port (
        clk       : in std_logic;
        enable    : in std_logic;
        reset     : in std_logic;
        sig_in    : in std_logic;
        pulse_out : out std_logic
	);
end pulse_generator;

architecture arch_imp of pulse_generator is

	signal q_sig : std_logic := '0';
	signal s_out : std_logic := '0';

begin
	
	pulsegen : process(clk) is
	begin
	if(reset = '1') then
		q_sig <= '0';
		s_out <= '0';
    elsif(rising_edge(clk)) then
   		if(enable = '1') then
       		q_sig <= not sig_in;
       		s_out <= q_sig and sig_in;
   		end if;
    end if;
    end process;

    pulse_out <= s_out;

end arch_imp;