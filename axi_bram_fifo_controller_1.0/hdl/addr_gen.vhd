----------------------------------------------------------------------------------
-- Company:  Space Micro
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:26:23 AM
-- Design Name: 
-- Module Name: addr_gen - Behavioral
-- Project Name: MDA Cubesat Network
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
           rdwr : in STD_LOGIC;
           rd_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           wr_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           fifo_empty : out std_logic;
           fifo_full  : out std_logic;
           fifo_occupancy : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0));
end addr_gen;

architecture Behavioral of addr_gen is

    constant EMPTY : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant FULL  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1'); 
    constant READ  : std_logic := '1';
    constant WRITE : std_logic := '0';
    signal s_empty, s_full : std_logic := '0';
    signal s_rd_addr, s_wr_addr : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal s_occupancy : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

begin

    fifo_empty <= s_empty;
    fifo_full  <= s_full;
    rd_addr <= std_logic_vector(s_rd_addr);
    wr_addr <= std_logic_vector(s_wr_addr);
    fifo_occupancy <= std_logic_vector(s_occupancy);
    
    address_gen : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            s_rd_addr   <= (others => '0');
            s_wr_addr   <= (others => '0');
            s_occupancy <= (others => '0');
            s_empty <= '1';
            s_full  <= '0';
        elsif(en = '1') then
        
            if(rdwr = READ) then
               if(s_occupancy > EMPTY) then
                   s_rd_addr <= s_rd_addr + 1;
                   s_occupancy <= s_occupancy - 1;  
                   s_empty <= '0'; 
                   s_full <= '0';
               else
                   s_empty <= '1';
                   s_full <= '0';
               end if;
            end if;
            
            if(rdwr = WRITE) then
               if(s_occupancy < FULL) then
                   s_wr_addr <= s_wr_addr + 1;
                   s_occupancy <= s_occupancy + 1; 
                   s_full <= '0';
                   s_empty <= '0';
               else
                   s_full <= '1';
                   s_empty <= '0';
               end if;
            end if;
        end if;
    end if;
    end process address_gen;
    
--    check_occupancy : process(clk)
--    begin
--    if(rising_edge(clk)) then
--        if(rst = '1') then
--            s_empty <= '1';
--            s_full  <= '0';
----        elsif(en = '1') then
--        else
--            if(s_occupancy = FULL) then
--                s_full <= '1';
--            elsif(s_occupancy = EMPTY) then
--                s_empty <= '1';
--            else
--                s_empty <= '0';
--                s_full  <= '0';
--            end if;
--        end if;
--    end if;
--    end process check_occupancy;
        

end Behavioral;
