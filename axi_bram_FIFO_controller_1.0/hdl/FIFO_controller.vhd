----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: FIFO_Controller - Behavioral
-- Target Devices: CSP -- Zynq7020
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

entity FIFO_Controller is
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
           bram_empty : out std_logic
           );
end FIFO_Controller;

architecture Behavioral of FIFO_Controller is

    component addr_gen is
    generic ( BRAM_ADDR_WIDTH  : integer := 10 );
    Port ( clk : in STD_LOGIC;
           en : in STD_LOGIC;
           rst : in STD_LOGIC;
           direction : in STD_LOGIC;
           addr : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
           empty : out std_logic;
           full  : out std_logic);
    end component addr_gen;

    -- signals for addr_gen core
    signal addr_en, addr_rst, addr_dir, addr_empty, addr_full : std_logic := '0';
    constant count_down : std_logic := '0';
    constant count_up   : std_logic := '1';
    signal s_addr, s_addr_delay : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
    signal rdwr_hist, goread : std_logic := '0';
    
    -- signals for control logic

begin
    
    clka <= clk;
    bram_full <= addr_full;
    bram_empty <= addr_empty;
    addra <= s_addr;  
    
--    dff_s_addr : process(clk)
--    begin
--    if(rising_edge(clk)) then
--        s_addr_delay <= s_addr;
--    end if;
--    end process;
--    addra <= s_addr_delay;  
        
    address_generator : addr_gen
    generic map( BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH )
    port map(
        clk => clk,
        en  => addr_en,
        rst => addr_rst,
        direction => addr_dir,
        addr => s_addr,
        empty => addr_empty,
        full  => addr_full
        );
        
    process(clk)
    begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            addr_rst <= '1';
            dout_valid <= '0';
            goread <= '0';
            rdwr_hist <= '0';
        elsif(clkEn = '1') then
            ena <= '1';
            addr_rst <= '0';
            if(write_en = '1' and read_en = '0' and addr_full = '0') then
                addr_dir <= count_up;
                addr_en  <= '1';
                dina <= din;
                wea <= '1';
                dout_valid <= '0';
                rdwr_hist <= '1';
            elsif(write_en = '0' and read_en = '1' and rdwr_hist = '1' and addr_empty = '0') then
                addr_dir <= count_down;
                addr_en <= '1';
                rdwr_hist <= '0';
                goread <= '1';
            elsif(goread = '1' or (write_en = '0' and read_en = '1' and addr_empty = '0')) then
                addr_dir <= count_down;
                addr_en <= '1';
                wea <= '0';
                dout <= douta;
                dout_valid <= '1';
                goread <= '0';
            else -- no op
                addr_en <= '0';
                wea <= '0';
            end if;
        else
            ena <= '0';
        end if;
    end if;
    end process;


end Behavioral;
