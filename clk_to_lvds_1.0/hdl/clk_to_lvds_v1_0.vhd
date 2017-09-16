library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity clk_to_lvds_v1_0 is
	port (
        clk_in  : in std_logic;
        clk_out_p : out std_logic;
        clk_out_n : out std_logic
	);
end clk_to_lvds_v1_0;

architecture arch_imp of clk_to_lvds_v1_0 is

signal clk_buf : std_logic;

begin

    oddr_inst : oddr
    generic map(
        DDR_CLK_EDGE => "SAME_EDGE",
        INIT => '0',
        SRTYPE => "SYNC"
    )
    port map (
        Q => clk_buf,
        C => clk_in,
        CE => '1',
        D1 => '1',
        D2 => '0',
        R => '0',
        S => '0'
    );
    
    obufds_inst : obufds
    port map(
        O  => clk_out_p,
        OB => clk_out_n,
        I  => clk_buf
    );

end arch_imp;
