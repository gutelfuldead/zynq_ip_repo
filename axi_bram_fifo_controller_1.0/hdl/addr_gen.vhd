----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:26:23 AM
-- Design Name: 
-- Module Name: addr_gen - Behavioral
-- Target Devices: Zynq7020
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
           rden : in STD_LOGIC;
           wren : in STD_LOGIC;
           rd_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           wr_addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           fifo_empty : out std_logic;
           fifo_full  : out std_logic;
           fifo_occupancy : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0));
end addr_gen;

architecture Behavioral of addr_gen is

    constant EMPTY : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant FULL  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1'); 
    signal s_empty, s_full : std_logic := '0';
    signal s_rd_done, s_wr_done : std_logic := '0';
    signal s_rd_addr, s_wr_addr : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal s_occupancy : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');

begin

    fifo_empty <= s_empty;
    fifo_full  <= s_full;
    rd_addr <= std_logic_vector(s_rd_addr);
    wr_addr <= std_logic_vector(s_wr_addr);
    fifo_occupancy <= std_logic_vector(s_occupancy);
    
    address_gen_read : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
           s_rd_addr   <= (others => '0');
        elsif(en = '1' and rden = '1') then
           if(s_empty = '0') then
               s_rd_addr <= s_rd_addr + 1;
               s_rd_done <= '1';  
           end if;
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
        elsif(en = '1' and wren = '1') then
            if(s_full = '0') then
                s_wr_addr <= s_wr_addr + 1;
                s_wr_done <= '1';
            end if;
        else
            s_wr_done <= '0';
        end if;
    end if;
    end process address_gen_write;
    
    occupancy_generator : process(clk)
    begin
    if(rising_edge(clk)) then
        if(rst = '1') then
          s_occupancy <= (others => '0');
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
      elsif(s_occupancy = EMPTY) then
          s_empty <= '1';
          s_full  <= '0';
      elsif(s_occupancy = FULL) then
          s_full  <= '1';
          s_empty <= '0';
      else
          s_full  <= '0';
          s_empty <= '0';
      end if;
    end if;
    end process full_empty_checker;
    
end Behavioral;
