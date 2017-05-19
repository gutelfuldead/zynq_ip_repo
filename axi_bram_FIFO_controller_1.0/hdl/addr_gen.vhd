----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:26:23 AM
-- Design Name: 
-- Module Name: addr_gen - Behavioral
-- Target Devices: CSP -- Zynq7020
-- Tool Versions:  Vivado 2015.4
-- Description:    Generates address for BRAM interface
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
use IEEE.NUMERIC_STD.ALL;


entity addr_gen is
    generic ( BRAM_ADDR_WIDTH  : integer := 10 );
    Port ( clk : in STD_LOGIC;
           en  : in STD_LOGIC;
           rst : in STD_LOGIC;
           direction : in STD_LOGIC;
           addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           empty : out std_logic;
           full  : out std_logic);
end addr_gen;

architecture Behavioral of addr_gen is

    constant c_empty : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant c_full  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1'); 
    signal s_empty, s_full : std_logic := '0';
    constant count_down : std_logic := '0';
    constant count_up   : std_logic := '1';
    signal s_addr : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

begin

    addr <= std_logic_vector(s_addr);
    empty <= s_empty;
    full  <= s_full;
    
    address_gen : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            s_addr <= (others => '0');
        elsif(en = '1') then
            if(direction = count_down) then
               if(s_addr > unsigned(c_empty)) then
                  s_addr <= s_addr - 1;
               end if;
            elsif(direction = count_up) then -- count_up
                if(s_addr < unsigned(c_full)) then
                    s_addr <= s_addr + 1;   
                end if;
            end if;
        end if;
    end if;
    end process address_gen;
    
    check_occupancy : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            s_empty <= '1';
            s_full  <= '0';
        elsif(en = '1') then
            if(unsigned(s_addr) = unsigned(c_full)) then
                s_full <= '1';
            elsif(unsigned(s_addr) = unsigned(c_empty)) then
                s_empty <= '1';
            else
                s_empty <= '0';
                s_full  <= '0';
            end if;
        end if;
    end if;
    end process check_occupancy;
        

end Behavioral;
