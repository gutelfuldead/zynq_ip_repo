library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity signal_inverter_v1_0 is

	port (
	   input : in std_logic;
	   inv_output : out std_logic

	);
end signal_inverter_v1_0;

architecture arch_imp of signal_inverter_v1_0 is

	
begin

    inv_output <=  not input;

end arch_imp;
