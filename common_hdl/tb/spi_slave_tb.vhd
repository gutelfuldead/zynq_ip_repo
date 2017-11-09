----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 08/03/2017 02:56:31 PM
-- Design Name: 
-- Module Name: spi_slave_tb - Behavioral
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity spi_slave_tb is
--  Port ( );
end spi_slave_tb;

architecture Behavioral of spi_slave_tb is

    component spi_slave is
    generic (
        INPUT_CLK_MHZ : integer := 100;
        SPI_CLK_MHZ   : integer := 10;
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
    end component spi_slave;
    
    component spi_master is
    generic (
        INPUT_CLK_MHZ : integer := 100;
        SPI_CLK_MHZ   : integer := 10;
        DSIZE         : integer := 8
    );
    Port ( clk : in STD_LOGIC;
               reset : in STD_LOGIC;
               sclk : out STD_LOGIC;
               sclk_en : out STD_LOGIC;
               mosi : out STD_LOGIC;
               din  : in std_logic_vector(DSIZE-1 downto 0);
               rdy  : out std_logic;
               dvalid : in std_logic );
    end component spi_master;
    
    
    signal clk, reset, rdy, m_dvalid, s_dvalid, sclk, sclk_en, mosi : std_logic := '0';
    constant clk_period : time := 10 ns; -- 100 MHz clock
    constant DSIZE : integer := 8;
    constant INPUT_CLK_MHZ : integer := 100;
    constant SPI_CLK_MHZ   : integer := 10;
    constant CLK_RATIO     : integer := INPUT_CLK_MHZ/SPI_CLK_MHZ/2;
    
    signal dout : std_logic_vector(DSIZE-1 downto 0) := (others => '0');
    signal din  : std_logic_vector(DSIZE-1 downto 0) := (others => '0');


begin

    DUT : spi_slave
    generic map(
        INPUT_CLK_MHZ => INPUT_CLK_MHZ,
        SPI_CLK_MHZ   => SPI_CLK_MHZ,
        DSIZE => DSIZE
    )
    port map(
        clk => clk,
        reset => reset,
        sclk => sclk,
        sclk_en => sclk_en,
        mosi => mosi,
        dout  => dout,
        dvalid => s_dvalid
    );
    
    stimulator : spi_master
    generic map(
        INPUT_CLK_MHZ => INPUT_CLK_MHZ,
        SPI_CLK_MHZ   => SPI_CLK_MHZ,
        DSIZE => DSIZE
    )
    port map(
        clk => clk,
        reset => reset,
        sclk => sclk,
        sclk_en => sclk_en,
        mosi => mosi,
        din  => din,
        rdy  => rdy,
        dvalid => m_dvalid
    );
    
    clk_gen : process
    begin
        clk <= '1';
        wait for clk_period;
        clk <= '0';
        wait for clk_period;
    end process clk_gen;
    
    rst : process(clk)
        constant RESET_CYCLES : integer := 20000;
        variable cnt : integer range 0 to RESET_CYCLES;
    begin
    if(rising_edge(clk)) then
        if(cnt = RESET_CYCLES) then
            cnt := 0;
            reset <= '1';
        else
            reset <= '0';
            cnt := cnt + 1;
        end if;
    end if;
    end process rst;
    
    tb : process(clk)
        variable cnt : integer := 0;
        type states is (ST_GO, ST_INC);
        variable fsm : states := ST_GO;
    begin
    if(rising_edge(clk)) then
        case(fsm) is
        
        when ST_GO =>
            if(rdy = '1') then
                din <= std_logic_vector(to_unsigned(cnt,din'length));
                m_dvalid <= '1';
                fsm := ST_INC;
            end if;
            
        when ST_INC =>
            din <= (others => '0');
            m_dvalid <= '0';
            if(cnt = 255) then
                cnt := 0;
            else
                cnt := cnt + 1;
            end if;
            fsm := ST_GO;
            
        end case;
    end if;
    end process tb;



end Behavioral;
