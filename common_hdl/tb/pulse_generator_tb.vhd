library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity pulse_generator_tb is
    
end pulse_generator_tb;

architecture arch_tb of pulse_generator_tb is

    constant clk_period : time := 10 ns; -- 100 MHz clock

    signal clk       : std_logic := '0';
    signal sig_in    : std_logic := '0';
    signal pulse_out : std_logic := '0';
    signal new_pulse : std_logic := '0';

begin

    DUT : pulse_generator
    port map(
        clk => clk,
        sig_in => sig_in,
        pulse_out => pulse_out
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
        sig_in <= '0';
        wait for clk_period*10;
        sig_in <= '1';
        wait for clk_period*10;
    end process tb;

end arch_tb;
