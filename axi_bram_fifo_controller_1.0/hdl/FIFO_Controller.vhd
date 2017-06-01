----------------------------------------------------------------------------------
-- Company: Space Micro 
-- Engineer: Jason Gutel
-- 
-- Create Date: 05/17/2017 09:20:37 AM
-- Design Name: 
-- Module Name: FIFO_Controller - Behavioral
-- Project Name: MDA Cubesat Network
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
           bram_empty : out std_logic;
           bram_occupancy  : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0)
           );
end FIFO_Controller;

architecture Behavioral of FIFO_Controller is

    component addr_gen is
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
    end component addr_gen;

    signal rd_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal wr_addr : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal addr_en, rdwr : std_logic := '0';
    constant RDWR_READ  : std_logic := '1';
    constant RDWR_WRITE : std_logic := '0';
    signal full, empty : std_logic := '0';
    
begin

    -- instantiate clock at top level with BUFR; leave this port open in instantiation
    clka <= clk;
    bram_full <= full;
    bram_empty <= empty;
--    bram_occupancy <= std_logic_vector(occupancy);
    
    fifo_addr_gen : addr_gen
    generic map ( BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH )
    port map(
        clk => clk,
        en  => addr_en,
        rst => reset,
        rdwr => rdwr,
        rd_addr => rd_addr,
        wr_addr => wr_addr,
        fifo_empty => empty,
        fifo_full => full,
        fifo_occupancy => bram_occupancy
    );
            
    bram_rw_ops : process(clk)
    begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            dout_valid <= '0';
        elsif(clkEn = '1') then
            ena <= '1';
            
            if(write_en = '1' and read_en = '0' and full = '0') then
                    dina <= din;
                    addra <= wr_addr; 
                    wea <= '1';
                    dout_valid <= '0';
                    addr_en <= '1';
                    rdwr <= RDWR_WRITE;
                    
            elsif(read_en = '1' and write_en = '0' and empty = '0') then
                    addra <= rd_addr; 
                    wea <= '0';
                    dout <= douta;
                    dout_valid <= '1';
                    addr_en <= '1';
                    rdwr <= RDWR_READ;
            else
                addr_en <= '0';
                wea <= '0';
            end if;
        else
            ena <= '0';
        end if;
    end if;
    end process bram_rw_ops;
    
--    pointer_arithmetic : process(clk)
--    begin
--    if(rising_edge(clk)) then
--        if(reset = '1') then
--            rd_addr <= (others => '0');
--            wr_addr <= (others => '0');
--            occupancy <= (others => '0');
--        elsif(clkEn = '1') then
--            if(write_en = '0' and read_en = '1') then
--                rd_addr <= rd_addr + 1;
--                if(occupancy > ZERO_OCCUPANCY) then
--                    occupancy <= occupancy - 1;
--                end if;
--            elsif(write_en = '1' and read_en = '0') then
--                wr_addr <= wr_addr + 1;
--                if(occupancy < MAX_OCCUPANCY) then
--                    occupancy <= occupancy + 1;
--                end if;
--            end if;
--            if(occupancy = ZERO_OCCUPANCY) then
--                bram_empty <= '1';
--            elsif(occupancy = MAX_OCCUPANCY) then
--                bram_full <= '1';
--            else   
--                bram_full <= '0';
--                bram_empty <= '0';
--            end if;
--        end if;
--    end if;
--    end process pointer_arithmetic;
        
--    bram_rw_ops : process(clk)
--    begin
--    if(rising_edge(clk)) then
--        if(reset = '1') then
--            dout_valid <= '0';
--        elsif(clkEn = '1') then
--            ena <= '1';
--            if(write_en = '1' and read_en = '0') then
--                    dina <= din;
--                    addra <= std_logic_vector(wr_addr); 
--                    wea <= '1';
--                    dout_valid <= '0';
--                    bram_full <= '0';
--            elsif(read_en = '1' and write_en = '0') then
--                    addra <= std_logic_vector(rd_addr); 
--                    wea <= '0';
--                    dout <= douta;
--                    dout_valid <= '1';
--                    bram_empty <= '0';
--            else
--                wea <= '0';
--            end if;
--        else
--            ena <= '0';
--        end if;
--    end if;
--    end process bram_rw_ops;

end Behavioral;