----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:26:23 AM
-- Design Name: 
-- Module Name: FIFO_ADDR_GEN - Behavioral
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

library work;
use work.generic_pkg.all;

entity FIFO_ADDR_GEN is
    generic ( BRAM_ADDR_WIDTH  : integer := 10 );
    Port ( clk : in STD_LOGIC;
           en  : in STD_LOGIC;
           rst : in STD_LOGIC;
           rden : in STD_LOGIC;
           wren : in STD_LOGIC;
           rd_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           wr_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           empty : out std_logic;
           full  : out std_logic;
           occupancy : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0));
end FIFO_ADDR_GEN;

architecture Behavioral of FIFO_ADDR_GEN is

    constant C_EMPTY : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant C_FULL  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1'); 
    signal s_full : std_logic := '0';
    signal s_empty : std_logic := '1';
    signal s_rd_done, s_wr_done : std_logic := '0';
    signal s_rd_addr, s_wr_addr : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal s_occupancy : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

begin
    
    loader : process(clk)
    begin
    if(rising_edge(clk)) then
        empty <= s_empty;
        full  <= s_full;
        rd_addr <= std_logic_vector(s_rd_addr);
        wr_addr <= std_logic_vector(s_wr_addr);
        occupancy <= std_logic_vector(s_occupancy);
    end if;
    end process loader;
    
    address_gen_read : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
           s_rd_addr   <= (others => '0');
           s_rd_done   <= '0';
        elsif(en = '1' and rden = '1' and s_empty = '0') then
           s_rd_addr <= s_rd_addr + 1;
           s_rd_done <= '1';  
        else
           s_rd_done <= '0';
        end if;
    end if;
    end process address_gen_read;
   
    address_gen_write : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
            s_wr_addr   <= (others => '0');
            s_wr_done   <= '0';
        elsif(en = '1' and wren = '1' and s_full = '0') then
            s_wr_addr <= s_wr_addr + 1;
            s_wr_done <= '1';
        else
            s_wr_done <= '0';
        end if;
    end if;
    end process address_gen_write;
    
    occupancy_generator : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
          s_occupancy <= C_EMPTY;
        elsif(s_rd_done = '1' and s_wr_done = '0') then
          s_occupancy <= s_occupancy - 1;
        elsif(s_wr_done = '1' and s_rd_done = '0') then
          s_occupancy <= s_occupancy + 1;
        end if;
    end if;
    end process occupancy_generator;
    
    full_empty_checker : process(clk)
    begin
    if(rising_edge(clk)) then
      if(rst = '1') then
          s_empty <= '1';
          s_full <= '0';
      elsif(s_occupancy = C_EMPTY) then
          s_empty <= '1';
          s_full  <= '0';
      elsif(s_occupancy = C_FULL) then
          s_full  <= '1';
          s_empty <= '0';
      else
          s_full  <= '0';
          s_empty <= '0';
      end if;
    end if;
    end process full_empty_checker;
    
end Behavioral;