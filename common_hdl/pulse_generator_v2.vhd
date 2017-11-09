----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 07/17/2017
-- Design Name: 
-- Module Name: pulse_generator_v2
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

entity pulse_generator_v2 is
  generic (
    ACTIVE_LEVEL : std_logic := '1'
    );
  port (
        clk       : in std_logic;
        reset     : in std_logic;
        sig_in    : in std_logic;
        pulse_out : out std_logic
  );
end pulse_generator_v2;

architecture arch_imp of pulse_generator_v2 is

  signal q_sig : std_logic := ACTIVE_LEVEL;

begin
  
  pulsegen : process(clk, reset)
  begin
  if(reset = '1') then
    q_sig <= ACTIVE_LEVEL;
  if(rising_edge(clk)) then
    q_sig <= not sig_in;
  end if;
  end process;

  sync_out : process(clk, reset)
  begin
  if(reset = '1') then
    pulse_out <= not ACTIVE_LEVEL;
  elsif(rising_edge(clk)) then
    if (ACTIVE_LEVEL = '1') then
      pulse_out <= q_sig and sig_in;
    else 
      pulse_out <= not (q_sig and sig_in);
    end if; 
  end if;
  end process sync_out;

end arch_imp;