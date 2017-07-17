----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: bram_fifo_controller
-- Target Devices: Zynq7020
-- Tool Versions: Vivado 2015.4
-- Description:   Controller interface for BRAM block_memory_generator core
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

entity BRAM_FIFO_CONTROLLER is
    generic (
           BRAM_ADDR_WIDTH  : integer := 10;
           BRAM_DATA_WIDTH  : integer := 32 );
    Port ( 
           -- BRAM write port lines
           addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           dina  : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
           ena   : out STD_LOGIC;
           wea   : out STD_LOGIC;
           clka  : out std_logic;
           rsta  : out std_logic;
       
           -- BRAM read port lines
           addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
           enb   : out STD_LOGIC;
           clkb  : out std_logic;
           rstb  : out std_logic;
           
           -- Core logic
           clk        : in std_logic;
           clkEn      : in std_logic;
           write_en   : in std_logic;
           read_en    : in std_logic;
           write_ready  : out std_logic;
           read_ready   : out std_logic;
           reset      : in std_logic;
           din        : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
           dout       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
           dvalid : out std_logic;
           full  : out std_logic;
           empty : out std_logic;
           occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
           );
end BRAM_FIFO_CONTROLLER;

architecture Behavioral of BRAM_FIFO_CONTROLLER is

    constant C_EMPTY : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    constant C_FULL  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '1'); 
    signal rd_addr_next : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal wr_addr_next : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal s_occupancy  : unsigned(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal addr_full  : std_logic := '1';
    signal addr_empty : std_logic := '0';

    type fsm_states is (ST_SYNC, ST_WORK);
    constant SYNC_LEN : integer := 3;


begin 
  
  -- instantiate clock at top level with BUFR; leave this port open in instantiation
  clka <= clk;
  clkb <= clk;   
    
  ena  <= '1' when (clkEn = '1') else '0';
  enb  <= '1' when (clkEn = '1') else '0';
  rstb <= '1' when (reset = '1') else '0';
  rsta <= '1' when (reset = '1') else '0';

  ----------------------------------------------------------------------------------
  -- Loader Process  
  ----------------------------------------------------------------------------------
  -- Asynchronous Reset. Loads addresses, occupancy count, and full/empty watermarks  
  ----------------------------------------------------------------------------------
  loader : process(clk, reset)
  begin
  if(reset = '1') then
    addr_empty <= '1';
    addr_full  <= '0';
    empty <= '1';
    full  <= '0';
  elsif(rising_edge(clk)) then
      if(clkEn = '1') then
          addra <= std_logic_vector(wr_addr_next);
          addrb <= std_logic_vector(rd_addr_next);
          occupancy <= std_logic_vector(s_occupancy);
          if(s_occupancy = C_EMPTY) then
            addr_empty <= '1';
            empty      <= '1';
            addr_full  <= '0';
            full       <= '0';
          elsif(s_occupancy = C_FULL) then
            addr_full  <= '1';
            full       <= '1';
            addr_empty <= '0';
            empty      <= '0';
          else
            addr_full  <= '0';
            full       <= '0';
            addr_empty <= '0';
            empty      <= '0';
          end if;
      end if;
  end if;
  end process loader;
     

  ----------------------------------------------------------------------------------
  -- Occupancy Check Process (Async. Reset)
  ----------------------------------------------------------------------------------
  -- updates occupancy of fifo based on current read/write requests
  ----------------------------------------------------------------------------------
  occupancy_check : process(clk,reset)
  begin
  if(reset = '1') then
    s_occupancy <= (others => '0');
  elsif(rising_edge(clk)) then
    if(read_en = '1' and write_en = '0' and addr_empty = '0') then
      s_occupancy <= s_occupancy - 1;
    elsif(read_en = '0' and write_en = '1' and addr_full = '0') then
      s_occupancy <= s_occupancy + 1;
    end if;
  end if;
  end process occupancy_check;

  ----------------------------------------------------------------------------------
  -- Read Process (Async Reset)
  ----------------------------------------------------------------------------------
  -- Sets a "read ready" bit to inform top module that the fifo is in a good state
  -- and ready for a read. Once a read request is passed the data on the address
  -- line is returned and the device is resynchronized to read ready state
  -- Sync state is used to refresh address lines
  ----------------------------------------------------------------------------------
  read_proc : process(clk,reset)
    variable fsm : fsm_states := ST_WORK;
    variable cnt : integer range 0 to SYNC_LEN := 0;
  begin
  if(reset = '1') then
    fsm := ST_WORK;
    read_ready <= '0';
    cnt := 0;
    dvalid <= '0';
    rd_addr_next <= (others => '0');
  elsif(rising_edge(clk)) then
    case(fsm) is

    when ST_WORK =>
      if(addr_empty = '0') then
        read_ready <= '1';
        if(read_en = '1') then
          dout         <= doutb;
          dvalid       <= '1';
          rd_addr_next <= rd_addr_next + 1;
          fsm := ST_SYNC;
        end if;
      end if;

    when ST_SYNC =>
      read_ready   <= '0'; 
      dvalid <= '0';
      if(cnt = SYNC_LEN) then
        cnt := 0;
        fsm := ST_WORK;
      else 
        cnt := cnt + 1;
      end if;

    end case;
  end if;
  end process read_proc;

  ----------------------------------------------------------------------------------
  -- Write Process (Async. Reset)
  ----------------------------------------------------------------------------------
  -- Sets a "write ready" bit to inform top module that the fifo is in a good state
  -- and ready for a write. Once a write request is passed the data will be written
  -- to the FIFO and then resynchronized to a good state
  -- Sync state is used to refresh address lines
  ----------------------------------------------------------------------------------
  write_proc : process(clk,reset)
    variable fsm : fsm_states := ST_WORK;
    variable cnt : integer range 0 to SYNC_LEN := 0;
  begin
  if(reset = '1') then
    fsm := ST_WORK;
    write_ready <= '0';
    cnt := 0;
    wea <= '0';
    wr_addr_next <= (others => '0');
  elsif(rising_edge(clk)) then
    case(fsm) is

    when ST_WORK =>
      if(addr_full = '0') then
        write_ready <= '1'; 
        if(write_en = '1') then
          dina <= din;
          wea  <= '1';
          wr_addr_next <= wr_addr_next + 1;
          fsm := ST_SYNC;
        end if;
      end if;

    when ST_SYNC =>
      write_ready <= '0';
      wea <= '0';
      if(cnt = SYNC_LEN) then
        cnt := 0;
        fsm := ST_WORK;
      else
        cnt := cnt + 1;
      end if;

    end case;
  end if;
  end process write_proc;

end Behavioral;