library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_wd_v1_0 is
	generic (
        reference_clk : integer := 10000000
	);
	port (
	    clk : in std_logic;
        led : out std_logic
	);
end led_wd_v1_0;

architecture arch_imp of led_wd_v1_0 is

    signal vled : std_logic := '0';

begin

    led <= vled;

    process(clk)
        variable cnt : integer range 0 to reference_clk := 0;
    begin
    if(rising_edge(clk)) then
        if(cnt = reference_clk) then
            cnt := 0;
            vled <= not vled;
        else
            cnt := cnt + 1;
        end if;           
            
    end if;
    end process;

end arch_imp;
