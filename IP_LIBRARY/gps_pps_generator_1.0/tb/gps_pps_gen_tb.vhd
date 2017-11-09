----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/29/2017 02:59:56 PM
-- Design Name: 
-- Module Name: gps_pps_gen_tb - Behavioral
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

entity gps_pps_gen_tb is

end gps_pps_gen_tb;

architecture Behavioral of gps_pps_gen_tb is

    component gps_pps_gen is
    generic(
        clk_freq_in  : integer := 100; -- MHz
        pulse_high   : integer := 5 -- cycles
        );
    Port ( 
        clk, en, rst     : in std_logic;
        gps_pps          : out std_logic
    );
    end component gps_pps_gen;

    constant clk_period : time := 10 ns; -- 100 MHz clock
    
    signal s_clk, s_en, s_rst, s_gps_pps : std_logic := '0';

begin

        -- generate clock
    clk_process : process
    begin
        s_clk <= '0';
        wait for clk_period/2;
        s_clk <= '1';
        wait for clk_period/2;
    end process clk_process;
    
    UUT : gps_pps_gen
    port map(
        clk => s_clk,
        en => s_en,
        rst => s_rst,
        gps_pps => s_gps_pps
        );
        
    tb : process
    begin        
        wait for 100 ns;
        s_en <= '1';
        s_rst <= '1';
        wait for 100 ns;
        s_rst <= '0';
        wait for 1000000000 ns; -- wait for 1 second
        wait for 1000000000 ns; -- wait for 1 second
        wait for 1000000000 ns; -- wait for 1 second
        wait for 100000000 ns; -- wait for 100ms
        s_rst <= '1';
        wait for 100 ns;
    end process;


end Behavioral;
