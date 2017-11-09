----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2017 02:51:22 PM
-- Design Name: 
-- Module Name: gps_pps_gen - Behavioral
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

entity gps_pps_gen is
    generic(
        clk_freq_in  : integer := 100; -- MHz
        pulse_high   : integer := 5 -- cycles
        );
    port ( 
        clk, en, rst     : in std_logic;
        gps_pps          : out std_logic
    );
end gps_pps_gen;

architecture Behavioral of gps_pps_gen is

    constant C_MAX     : integer := clk_freq_in * 1000000;
    constant C_PPS_DUR : integer := pulse_high; -- number of input clock cycles to keep high
    
    signal s_gps_pps : std_logic := '0';
    
begin

    gps_pps <= s_gps_pps;
	
    counter : process(clk)
        variable v_clk_cnt  : natural range 0 to C_MAX + 1 := 0;
        variable v_high_cnt : natural range 0 to C_PPS_DUR + 1 := 0; 
    begin
        if(rising_edge(clk)) then
            if(en = '1') then
                if(rst = '1') then
                    s_gps_pps <= '0';
                    v_clk_cnt  := 0;
                    v_high_cnt := 0;
                else
                    if(v_clk_cnt < C_MAX - 1) then
                        v_clk_cnt := v_clk_cnt + 1;
                        s_gps_pps <= '0';
                    else
                        if(v_high_cnt < C_PPS_DUR - 1) then
                            s_gps_pps <= '1';
                            v_high_cnt := v_high_cnt + 1;
                        else
                            v_high_cnt := 0;
                            v_clk_cnt := 0;
                        end if;
                    end if;
                end if;
            else
                s_gps_pps <= '0';
            end if;
        end if;
    end process counter;
	-- User logic ends

end Behavioral;
