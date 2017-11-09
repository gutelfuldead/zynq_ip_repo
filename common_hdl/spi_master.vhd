----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Jason Gutel
-- 
-- Create Date: 08/03/2017 02:53:04 PM
-- Design Name: 
-- Module Name: spi_master - Behavioral
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

entity spi_master is
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
           dvalid : in std_logic 
           );
end spi_master;

architecture Behavioral of spi_master is

    constant CLK_RATIO    : integer := INPUT_CLK_MHZ/SPI_CLK_MHZ/2-1;
    constant SYNC_CYCLES  : integer := 10;
    
    type states is (ST_IDLE, ST_ACTIVE, ST_LEAD_IN, ST_SYNC);
    signal fsm : states := ST_IDLE;

    signal mosi_shift_reg : std_logic_vector(DSIZE-1 downto 0);
    
begin

    main : process(clk)
        variable bit_idx  : integer range 0 to DSIZE := 0;
        variable clk_cnt  : integer range 0 to CLK_RATIO := 0;
        variable sync_cnt : integer range 0 to SYNC_CYCLES := 0;
        variable sclk_tmp  : std_logic := '0';
        variable sclk_prev : std_logic := '0';
        variable transaction_done : std_logic := '0';
    begin
    if(reset = '1') then
        rdy     <= '0';
        sclk    <= '0';
        sclk_en <= '0';
        mosi    <= '0';
        bit_idx  := 0;
        clk_cnt  := 0;
        sclk_tmp := '0';
        sclk_prev := '0';
        transaction_done := '0';
        sync_cnt := 0;
        fsm <= ST_IDLE;
    elsif(rising_edge(clk)) then
    case(fsm) is
    
    when ST_IDLE =>
        rdy     <= '1';
        sclk_en <= '0';
        transaction_done := '0';
        sclk_tmp := '0';
        mosi <= '0';
        if(dvalid = '1') then
            rdy     <= '0';
            mosi_shift_reg <= din;
            fsm <= ST_LEAD_IN;
        end if;      
        
    when ST_LEAD_IN =>
        sclk_en <= '1';
        rdy <= '0';
        if(clk_cnt = CLK_RATIO/2) then
            clk_cnt := 0;
            fsm <= ST_ACTIVE;
        else
            clk_cnt := clk_cnt + 1;
        end if;
    
    when ST_ACTIVE =>
        if(bit_idx = DSIZE and sclk_tmp = '0') then
            transaction_done := '1';
        end if;
        if(clk_cnt = CLK_RATIO) then
            if(transaction_done = '1') then
                fsm <= ST_SYNC;
                clk_cnt := 0;
                bit_idx := 0;
            else
                sclk_tmp := not sclk_tmp;
                clk_cnt := 0;
                if(sclk_prev = '0') then
                    mosi <= mosi_shift_reg(bit_idx);
                    bit_idx := bit_idx + 1;
                end if;
            end if;
        else
            clk_cnt := clk_cnt + 1;
            sclk_prev := sclk_tmp;
        end if;
        
    when ST_SYNC =>
        mosi <= '0';
        sclk_en <= '0';
        if(sync_cnt = SYNC_CYCLES) then
            sync_cnt := 0;
            fsm <= ST_IDLE;
        else
            sync_cnt := sync_cnt + 1;
        end if;
    
    when others =>
        fsm <= ST_IDLE;
    
    end case;
    
    sclk <= sclk_tmp;
    
    end if;
    end process main;
         
end Behavioral;
