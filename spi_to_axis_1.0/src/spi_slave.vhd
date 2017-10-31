----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Jason Gutel
-- 
-- Create Date: 08/03/2017 02:53:04 PM
-- Design Name: 
-- Module Name: spi_slave - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

entity spi_slave is
    generic (
        DSIZE         : integer := 8
    );
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           sclk : in STD_LOGIC;
           sclk_en : in STD_LOGIC;
           mosi : in STD_LOGIC;
           dout : out std_logic_vector(DSIZE-1 downto 0);
           dvalid : out std_logic 
           );
end spi_slave;

architecture Behavioral of spi_slave is

    type states is (ST_IDLE, ST_ACTIVE, ST_DONE);
    signal fsm : states := ST_IDLE;
    
    signal mosi_reg : std_logic_vector(DSIZE-1 downto 0) := (others => '0');
    signal sclk_delay_one : std_logic := '0';
    signal sclk_delay_two : std_logic := '0';
    signal sclk_en_delay  : std_logic := '0';
    
begin

  sclk_delay : process(clk)
  begin
  if(rising_edge(clk)) then
    sclk_en_delay  <= sclk_en;
    sclk_delay_one <= sclk;
    sclk_delay_two <= sclk_delay_one;    
  end if;
  end process sclk_delay;

  main : process(clk,reset)
      variable bit_idx : integer range 0 to DSIZE := 0;
  begin
  if(reset = '1') then
      bit_idx := 0;
      fsm <= ST_IDLE;
      dout <= (others => '0');
      dvalid <= '0';
      mosi_reg <= (others => '0');
  elsif(rising_edge(clk)) then
  case(fsm) is
  
  when ST_IDLE =>
    dvalid <= '0';
    bit_idx := 0;
    if(sclk_en = '1' and sclk_en_delay = '0') then
      fsm <= ST_ACTIVE;
    end if;
          
  when ST_ACTIVE =>
    if(bit_idx = DSIZE) then
      if(sclk_en = '0') then
        fsm <= ST_DONE;
      end if;
    elsif(sclk = '1' and sclk_delay_one = '1' and sclk_delay_two = '0') then
        mosi_reg(bit_idx) <= mosi;
        bit_idx := bit_idx + 1;
    end if;

  when ST_DONE =>
    dvalid <= '1';
    dout <= mosi_reg;
    fsm <= ST_IDLE;

  when others =>
    fsm <= ST_IDLE;
  
  end case;
      
  end if;
  end process main;
         
end Behavioral;
