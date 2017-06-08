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
           READ_SRC         : std_logic := '1';
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
    signal rdwr_hist : std_logic := '0';
    constant PS_READ : std_logic := '1';
    constant PL_READ : std_logic := '0';
    
    type state is (IDLE, READ, READ_PREP, WRITE, WRITE_PREP);
    signal fsm_state : state := IDLE;
    
begin

    -- instantiate clock at top level with BUFR; leave this port open in instantiation
    clka <= clk;
    clkb <= clk;
    ena  <= '1';
    enb  <= '1';    
    
    bram_full <= full;
    bram_empty <= empty;
    
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
    
    bram_rw_states : process(clk)
    begin
    if(rising_edge(clk)) then
        if(reset='1') then
            dout_valid <= '0';
            fsm_state <= IDLE;
            rsta <= '1';
            rstb <= '1';
        elsif(clkEn = '1') then
            rsta <= '0';
            rstb <= '0';
       
            case (fsm_state) is
            
            when IDLE =>
                wea <= '0';
                addra <= wr_addr;
                addrb <= rd_addr;
                if(READ_SRC = PL_READ) then
                    dout_valid <= '0';
                end if;
                addr_en <= '0';
                if(write_en = '1' and read_en = '0' and full = '0') then
                    fsm_state <= WRITE_PREP;
                elsif(write_en = '0' and read_en = '1' and empty = '0') then
                    fsm_state <= READ_PREP;
                end if;
                
            when WRITE_PREP =>
                fsm_state <= WRITE;
                dina <= din;
                
            when WRITE =>
                wea <= '1';
                addr_en <= '1';
                rdwr <= RDWR_WRITE;
                fsm_state <= IDLE;
                
            when READ_PREP =>
                dout_valid <= '0';
                fsm_state <= READ;
                
            when READ =>
                dout <= doutb;
                dout_valid <= '1';
                addr_en <= '1';
                rdwr <= RDWR_READ;
                fsm_state <= IDLE;
                
            when others =>
                fsm_state <= IDLE;
                
            end case;
        end if;
    end if;
    end process bram_rw_states;
                
end Behavioral;