library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.generic_pkg.all;

use IEEE.NUMERIC_STD.ALL;

entity fifo_addr_gen_tb is
end fifo_addr_gen_tb;

architecture Behavioral of fifo_addr_gen_tb is


   constant BRAM_ADDR_WIDTH  : integer := 10;      
   signal clk       : STD_LOGIC;
   signal en        : STD_LOGIC;
   signal rst       : STD_LOGIC;
   signal rden      : STD_LOGIC;
   signal wren      : STD_LOGIC;
   signal rd_addr   : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
   signal wr_addr   : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
   signal empty     : std_logic;
   signal full      : std_logic;
   signal occupancy : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
   constant clk_period : time := 10 ns; -- 100 MHz clock

   constant write_wait : integer := 10;
   constant read_wait  : integer := write_wait + write_wait;
   constant OCC_WAIT   : integer := 10;


begin

    DUT : FIFO_ADDR_GEN
    generic map ( BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH )
    port map(
        clk       => clk,
        en        => en,
        rst       => rst,
        rden      => rden,
        wren      => wren,
        rd_addr   => rd_addr,
        wr_addr   => wr_addr,
        empty     => empty,
        full      => full,
        occupancy => occupancy
    );

    en <= '1';

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;
    
    rst_proc : process(clk)
       constant rst_cnt : integer := 200;
       variable cnt : integer range 0 to rst_cnt := rst_cnt;
    begin
       if(rising_edge(clk)) then
           if (cnt = rst_cnt) then
               rst <= '1';
               cnt := 0;
           else
               rst <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

   write_test : process(clk, rst)
        variable write_asserted : std_logic := '0';
        variable cnt : integer range 0 to write_wait := 0;
   begin
   if(rst = '1') then
        cnt := 0;
        write_asserted := '0';
   elsif(rising_edge(clk)) then
        if(write_asserted = '0' and full = '0') then
            wren <= '1';
            write_asserted := '1';
        else
            wren <= '0';
            if(cnt = write_wait) then
                write_asserted := '0';
                cnt := 0;
            else
                cnt := cnt + 1;
            end if;
        end if;
   end if;
   end process write_test;

   read_test : process(clk, rst)
        variable read_asserted : std_logic := '0';
        variable cnt : integer range 0 to read_wait := 0;
    begin
    if(rst = '1') then
        cnt := 0;
        read_asserted := '0';
    elsif(rising_edge(clk)) then
        if (read_asserted = '0' and empty = '0' and occupancy = std_logic_vector(to_unsigned(OCC_WAIT, BRAM_ADDR_WIDTH))) then
            rden <= '1';
            read_asserted := '1';
        else
            rden <= '0';
            if(cnt = read_wait) then
                read_asserted := '0';
                cnt := 0;
            else
                cnt := cnt + 1;
            end if;
        end if;
    end if;
    end process read_test;

end Behavioral;
