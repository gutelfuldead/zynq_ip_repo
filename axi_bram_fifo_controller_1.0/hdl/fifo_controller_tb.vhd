----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/17/2017 10:27:47 AM
-- Design Name: 
-- Module Name: fifo_controller_tb - Behavioral
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

entity fifo_controller_tb is
    generic (
       BRAM_ADDR_WIDTH  : integer := 10;
       BRAM_DATA_WIDTH  : integer := 32 );
end fifo_controller_tb;

architecture Behavioral of fifo_controller_tb is

    component FIFO_Controller is
        generic (
               BRAM_ADDR_WIDTH  : integer := 10;
               BRAM_DATA_WIDTH  : integer := 32 );
        Port ( 
               -- BRAM Control Logic
               addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
               dina : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
               douta : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
               ena : out STD_LOGIC; -- core general enable
               wea : out STD_LOGIC; -- core write enable
               clka : out std_logic;
               -- Core logic
               clk        : in std_logic;
               clkEn      : in std_logic;
               write_en   : in std_logic;
               read_en    : in std_logic;
               reset      : in std_logic;
               din        : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
               dout       : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
               dout_valid : out std_logic;
               bram_full  : out std_logic;
               bram_empty : out std_logic;
               bram_occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
               );
   end component FIFO_Controller;
    
   signal bram_full, bram_empty : std_logic := '0';
   signal addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
   signal dina : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
   signal douta : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0):= (others => '0');
   signal ena :  STD_LOGIC := '1'; -- core general enable
   signal wea :  STD_LOGIC := '0'; -- core write enable
   signal clka : std_logic := '0';
   signal clk        :  std_logic := '0';
   signal clkEn      : std_logic := '1';
   signal write_en   :  std_logic := '0';
   signal read_en    :  std_logic := '0';
   signal reset      :  std_logic := '0';
   signal din        :  std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
   signal dout       :  std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := (others => '0');
   signal dout_valid :  std_logic := '0';
   signal bram_occupancy  : std_logic_vector(BRAM_ADDR_WIDTH -1 downto 0) := (others => '0');
   
   constant NUM_OPS : integer := 10;
   constant clk_period : time := 10 ns; -- 100 MHz clock
begin

  -- generate clock
  clk_process : process
  begin
      clk <= '1';
      wait for clk_period/2;
      clk <= '0';
      wait for clk_period/2;
  end process clk_process;

  UUT : FIFO_Controller
  generic map(
      BRAM_ADDR_WIDTH  => BRAM_ADDR_WIDTH,
      BRAM_DATA_WIDTH  => BRAM_DATA_WIDTH
    )
  port map(
      addra => addra,-- out STD_LOGIC_VECTOR (BRAM_ADDR_SIZE-1 downto 0);
      dina  => dina,-- out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
      douta => douta,-- in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
      ena   => ena,-- out STD_LOGIC; -- core general enable
      wea   => wea,-- out STD_LOGIC; -- core write enable
      clka  => clka,-- out std_logic;
      -- Core logic
      bram_occupancy => bram_occupancy,
      clk        => clk,  --: in std_logic;
      clkEn      => clkEn,
      write_en   => write_en,  --: in std_logic;
      read_en    => read_en,  --: in std_logic;
      reset      => reset,  --: in std_logic;
      din        => din,  --: in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      dout       => dout,  --: out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
      dout_valid => dout_valid,  --: out std_logic
      bram_full  => bram_full,
      bram_empty => bram_empty
    );

  tb : process
  begin
    reset <= '1';
    wait for clk_period*2;
    reset <= '0';
    wait for clk_period*2;
    write_en <= '1';
    wait for clk_period*NUM_OPS;
    write_en <= '0';
    WAIT FOR CLK_PERIOD*2;
    read_en <= '1';
    wait for clk_period*NUM_OPS;
    read_en <= '0';
    wait for clk_period*2;

  end process tb;


end Behavioral;
