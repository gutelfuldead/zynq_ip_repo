library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library UNISIM;
use UNISIM.Vcomponents.all;

entity clk_to_lvds_v1_0 is
	port (
        clk_in  : in std_logic;
        clk_out_p : out std_logic;
        clk_out_n : out std_logic;
        clk_out : out std_logic
	);
end clk_to_lvds_v1_0;

architecture arch_imp of clk_to_lvds_v1_0 is

signal clk_buf : std_logic;
signal clk_inv : std_logic;

begin

-- V1
--    oddr_inst : oddr
--    generic map(
--        DDR_CLK_EDGE => "SAME_EDGE",
--        INIT => '0',
--        SRTYPE => "SYNC"
--    )
--    port map (
--        Q => clk_buf,
--        C => clk_in,
--        CE => '1',
--        D1 => '1',
--        D2 => '0',
--        R => '0',
--        S => '0'
--    );
    
-- V2
	
clk_inv <= not clk_in;

oddr2_inst : ODDR2
generic map(
    DDR_ALIGNMENT => "NONE",
    INIT          => '0',
    SRTYPE        => "SYNC")
port map(
    Q  => clk_buf,
    C0 => clk_in,
    C1 => clk_inv,
    CE => '1',
    D0 => '1',
    D1 => '0',
    R  => '0',
    S  => '0'
);
    
--    obufds_inst : obufds
--    generic map ( IOSTANDARD=>"LVDS_25" ) 
--    port map(
--        O  => clk_out_p,
--        OB => clk_out_n,
--        I  => clk_buf
--    );
    clk_out_p <= '1';
    clk_out_n <= '0';
    
    obuf_inst : obuf
    port map(
        O => clk_out,
        I => clk_buf
    );

end arch_imp;
