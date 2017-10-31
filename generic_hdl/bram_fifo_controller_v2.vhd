----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: bram_fifo_controller
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description:   Controller interface for BRAM block_memory_generator core
--  based off of code from -- https://github.com/DeathByLogic/HDL/tree/master/FIFO/FWFT%20FIFO%20with%20Progamable%20Flag
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

entity BRAM_FIFO_CONTROLLER_v2 is
    generic (
           BRAM_ADDR_WIDTH  : integer := 10;
           BRAM_DATA_WIDTH  : integer := 32 );
    Port ( 
           -- BRAM write port lines
           addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           dina  : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
           ena   : out STD_LOGIC;
           wea   : out STD_LOGIC;
           rsta  : out std_logic;

           -- BRAM read port lines
           addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
           enb   : out STD_LOGIC;
           rstb  : out std_logic;
           
           -- Core logic
           clk     : in std_logic;
           reset   : in  STD_LOGIC;
           WriteEn : in  STD_LOGIC;
           DataIn  : in  STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);
           ReadEn  : in  STD_LOGIC;
           DataOut : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);
           DataOutValid : out std_logic;
           Empty   : out STD_LOGIC;
           Full    : out STD_LOGIC;
           ProgFullPulse : out STD_LOGIC;
           SetProgFull : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
           Occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
           );
end BRAM_FIFO_CONTROLLER_v2;

architecture Behavioral of BRAM_FIFO_CONTROLLER_v2 is

  signal PROG_FULL : integer := 0;
  constant fifo_sz : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1');
  constant FIFO_DEPTH : integer := to_integer(unsigned(fifo_sz));
  signal ProgFull : std_logic := '0';

begin 
  
  PROG_FULL <= to_integer(unsigned(SetProgFull));
  ena  <= '1';
  enb  <= '1';
  rstb <= '1' when (reset = '1') else '0';
  rsta <= '1' when (reset = '1') else '0';

-- Memory Pointer Process
  fifo_proc : process (CLK)
    variable Head : natural range 0 to FIFO_DEPTH - 1;
    variable Tail : natural range 0 to FIFO_DEPTH - 1;
    constant dvalid_cycles : integer := 2;
    variable dvalid_cycles_cnt : integer range 0 to dvalid_cycles := 0;
    variable dvalid_start_cnt : std_logic := '0';
    variable Looped : boolean;
  begin
    if rising_edge(CLK) then
      if reset = '1' then
        Head := 0;
        Tail := 0;
        Looped   := false;
        ProgFull <= '0';
        Full     <= '0';
        Empty    <= '1';
        DataOutValid <= '0';
        dvalid_cycles_cnt := 0;
        dvalid_start_cnt := '0';
      else
        if (ReadEn = '1') then
          dvalid_start_cnt := '1';
          DataOutValid <= '0';
          addrb <= std_logic_vector(to_unsigned(Tail, addrb'length));
          if ((Looped = true) or (Head /= Tail)) then
            -- Update Tail pointer as needed
            if (Tail = FIFO_DEPTH - 1) then
              Tail := 0;
              Looped := false;
            else
              Tail := Tail + 1;
            end if;
          end if;
        end if;

        if(dvalid_start_cnt = '1') then
          if(dvalid_cycles_cnt = dvalid_cycles) then
            dvalid_start_cnt  := '0';
            dvalid_cycles_cnt := 0;
            DataOutValid <= '1';
          else
            dvalid_cycles_cnt := dvalid_cycles_cnt + 1;
          end if;
        end if;
        
        if (WriteEn = '1') then
          if ((Looped = false) or (Head /= Tail)) then
            -- Write Data to Memory
            wea   <= '1';
            addra <= std_logic_vector(to_unsigned(Head,addra'length));
            dina  <= DataIn;
            
            -- Increment Head pointer as needed
            if (Head = FIFO_DEPTH - 1) then
              Head := 0;
              Looped := true;
            else
              Head := Head + 1;
            end if;
          end if;
        else
          wea <= '0';
        end if;

        -- Update data output
        DataOut <= doutb;
        
        -- Update Empty and Full flags
        if (Head = Tail) then
          if Looped then
            Full <= '1';
          else
            Empty <= '1';
          end if;
        else
          Empty <= '0';
          Full  <= '0';
        end if;
        
        -- Update Programable Full Flag
        if Looped then
          Occupancy <= std_logic_vector(to_unsigned((FIFO_DEPTH - Tail + Head), Occupancy'length));
          if ((FIFO_DEPTH - Tail + Head) >= PROG_FULL) then
            ProgFull <= '1';
          else
             ProgFull <= '0';
          end if;
        else
          Occupancy <= std_logic_vector(to_unsigned((Head - Tail), Occupancy'length));
          if ((Head - Tail) >= PROG_FULL) then
            ProgFull <= '1';
          else
            ProgFull <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;

  prog_full_pulse_gen : pulse_generator
  port map(
    clk     => clk,
    sig_in  => ProgFull,
    pulse_out => ProgFullPulse
    );

end Behavioral;