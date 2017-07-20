library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

library work;
use work.generic_pkg.all;

use IEEE.NUMERIC_STD.ALL;

entity bram_fifo_controller_tb is
end bram_fifo_controller_tb;

architecture Behavioral of bram_fifo_controller_tb is

  constant BRAM_ADDR_WIDTH  : integer := 10;    
  constant BRAM_DATA_WIDTH  : integer := 32;

  -- BRAM write port lines
  signal addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
  signal dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
  signal ena   : STD_LOGIC;
  signal wea   : STD_LOGIC;
  signal clka  : std_logic;
  signal rsta  : std_logic;
  
  -- BRAM read port lines
  signal addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
  signal doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
  signal enb   : STD_LOGIC;
  signal clkb  : std_logic;
  signal rstb  : std_logic;
  
  -- Core logic
  signal clk        : std_logic;
  signal clkEn      : std_logic;
  signal write_en   : std_logic;
  signal read_en    : std_logic;
  signal reset      : std_logic;
  signal din        : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal dout       : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  signal dvalid     : std_logic;
  signal full       : std_logic;
  signal empty      : std_logic;
  signal occupancy  : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
  signal read_ready : std_logic;
  signal write_ready : std_logic;

  constant clk_period : time    := 10 ns; -- 100 MHz clock
  constant WRITE_WAIT : integer := 0;
  constant READ_WAIT : integer  := 0;
  constant RESET_WAIT : integer := 4000;
  constant BRAM_MAX_SZ : integer := 1023;
  
  type fsm_states is (ST_IDLE, ST_ACTV);
  type bram_array_type is array (0 to BRAM_MAX_SZ) of std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  constant DEADBEEF : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := x"DEADBEEF";  
  signal bram_array : bram_array_type;

begin

  DUT : BRAM_FIFO_CONTROLLER
      generic map( 
          BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
          BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
      port map (
          addra => addra,
          dina  => dina,
          ena   => ena,
          wea   => wea,
          clka  => clka, -- instantiated with BUFR top level
          rsta  => rsta,
          addrb => addrb,
          doutb => doutb,
          enb   => enb,
          clkb  => clkb, -- instantiated with BUFR top level
          rstb  => rstb,
          
          clk        => clk,
          clkEn      => clkEn,
          write_en   => write_en,
          reset      => reset,
          din        => din,
          read_en    => read_en,
          dout       => dout,
          read_ready  => read_ready,
          write_ready  => write_ready,
          dvalid     => dvalid,
          full       => full,
          empty      => empty,
          occupancy  => occupancy 
      );

  clkEn <= '1';

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;
    
    rst_proc : process(clk)
       variable cnt : integer range 0 to RESET_WAIT := RESET_WAIT;
    begin
       if(rising_edge(clk)) then
           if (cnt = RESET_WAIT) then
               reset <= '1';
               cnt := 0;
           else
               reset <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

   write_test : process(clk,reset)
      variable data : integer := 1;
      variable data_sent_asserted : std_logic := '0';
      variable cnt : integer range 0 to WRITE_WAIT := 0;
   begin
   if(reset = '1') then
      data := 1;
      cnt := 0;
      data_sent_asserted := '0';
      write_en <= '0';
      for i in 0 to BRAM_MAX_SZ loop
        bram_array(i) <= DEADBEEF;
      end loop;
   elsif(rising_edge(clk)) then
    if(full = '0' and data_sent_asserted = '0' and write_ready = '1') then
      bram_array(to_integer(unsigned(addra))) <= std_logic_vector(to_unsigned(data,BRAM_DATA_WIDTH));
      din <= std_logic_vector(to_unsigned(data,BRAM_DATA_WIDTH));
      write_en <= '1';
      data_sent_asserted := '1';
    elsif(data_sent_asserted = '1') then
      write_en <= '0';
      if(cnt = WRITE_WAIT) then
        cnt := 0;
        data_sent_asserted := '0';
        data := data + 1;
      else
        cnt := cnt + 1;
      end if;
    else
      write_en <= '0';
    end if;

   end if;
   end process write_test;
   
   read_test : process(clk,reset)
           variable data_read_asserted : std_logic := '0';
           variable rd_fsm : fsm_states := ST_IDLE;
           variable cnt : integer range 0 to READ_WAIT := 0;
   begin
   if(reset = '1') then
           rd_fsm := ST_IDLE;
           cnt := 0;
           data_read_asserted := '0';
           read_en <= '0';
   elsif(rising_edge(clk)) then
        case(rd_fsm) is
            when ST_IDLE =>
                if(cnt = READ_WAIT) then
                    rd_fsm := ST_ACTV;
                    cnt := 0;
                else
                    cnt := cnt + 1;
                end if;
                
            when ST_ACTV => 
                if(empty = '0' and data_read_asserted = '0' and read_ready = '1') then
                   doutb <= bram_array(to_integer(unsigned(addrb)));
                   read_en <= '1';
                   data_read_asserted := '1';
                elsif(data_read_asserted = '1') then
                    read_en <= '0';
                    if(dvalid = '1') then
                        data_read_asserted := '0';
                        rd_fsm := ST_IDLE;
                    end if;
                else
                    read_en <= '0';
                end if;
        end case;
   end if;
   end process read_test;

end Behavioral;
