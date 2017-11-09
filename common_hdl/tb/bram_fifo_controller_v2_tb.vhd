library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library work;
use work.generic_pkg.all;

entity bram_fifo_controller_v2_tb is
end bram_fifo_controller_v2_tb;

architecture Behavioral of bram_fifo_controller_v2_tb is

  constant clk_period : time    := 10 ns; -- 100 MHz clock
  constant BRAM_ADDR_WIDTH  : integer := 10;    
  constant BRAM_DATA_WIDTH  : integer := 32;
  constant RESET_WAIT : integer := 400000;
  constant BRAM_MAX_SZ : integer := 1023;

  -- BRAM write port lines
  signal addra : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
  signal dina  : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
  signal ena   : STD_LOGIC;
  signal wea   : STD_LOGIC;
  signal rsta  : std_logic;
  
  -- BRAM read port lines
  signal addrb : STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
  signal doutb : STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
  signal enb   : STD_LOGIC;
  signal rstb  : std_logic;
  
  -- Core logic
  signal clk        : std_logic;
  signal reset      : std_logic;
  signal WriteEn :   STD_LOGIC;
  signal DataIn  :   STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);
  signal ReadEn  :   STD_LOGIC;
  signal DataOut,rx :  STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);
  signal Empty   :  STD_LOGIC;
  signal Full    :  STD_LOGIC;
  signal ProgFullPulse :  STD_LOGIC;
  signal DataOutValid : std_logic;
  signal SetProgFull, Occupancy :  std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);

  type fsm_states is (ST_IDLE, ST_ACTV);
  type bram_array_type is array (0 to BRAM_MAX_SZ) of std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
  constant DEADBEEF : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0) := x"DEADBEEF";  
  signal bram_array : bram_array_type;

  signal read_rate_slow : boolean := false;
  signal write_rate_slow : boolean := true;

  component BRAM_FIFO_CONTROLLER_v2 is
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
             reset     : in  STD_LOGIC;
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
  end component BRAM_FIFO_CONTROLLER_v2;

begin

  DUT : BRAM_FIFO_CONTROLLER_v2
      generic map( 
          BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
          BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
      port map (
          addra => addra,
          dina  => dina,
          ena   => ena,
          wea   => wea,
          rsta  => rsta,
          addrb => addrb,
          doutb => doutb,
          enb   => enb,
          rstb  => rstb,
          
          clk        => clk,
          reset      => reset,
          WriteEn    => WriteEn,
          DataIn     => DataIn,
          ReadEn     => ReadEn,
          DataOut    => DataOut,
          DataOutValid => DataOutValid,
          Empty      => Empty,
          Full       => Full,
          SetProgFull => SetProgFull,
          ProgFullPulse => ProgFullPulse,
          Occupancy => Occupancy
      );


    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;
    
    rst_proc : process(clk)
       variable cnt : integer range 0 to RESET_WAIT := RESET_WAIT;
       variable speed_case : integer range 0 to 3 := 0;
    begin
       if(rising_edge(clk)) then
           if (cnt = RESET_WAIT) then
               cnt := 0;
               reset <= '1';
               case (speed_case) is
                  when 0 =>
                    read_rate_slow  <= true;
                    write_rate_slow <= true;
                    speed_case := speed_case + 1;

                  when 1 =>
                    read_rate_slow  <= true;
                    write_rate_slow <= false;
                    speed_case := speed_case + 1;

                  when 2 =>
                    read_rate_slow  <= false;
                    write_rate_slow <= true;
                    speed_case := 0;

                  when others =>
                    speed_case := 0;

                end case;
           else
               reset <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

  bram_process : process(clk, reset)
  begin
  if(rising_edge(clk)) then
    if(wea = '1') then
      bram_array(to_integer(unsigned(addra))) <= dina;
    end if;
    doutb <= bram_array(to_integer(unsigned(addrb)));
  end if;
  end process bram_process;

   write_test : process(clk,reset)
      constant write_cnt_max : integer := 10;
      variable write_cnt : integer range 0 to write_cnt_max := 0;
      variable data : integer := 1;
      type states is (ST_WRITE, ST_WAIT);
      variable fsm : states := ST_WRITE;
   begin
   if(reset = '1') then
      WriteEn <= '0';
      fsm := ST_WRITE;
      data := 1;
      write_cnt := 0;
      SetProgFull <= std_logic_vector(to_unsigned(8,SetProgFull'length));
   elsif(rising_edge(clk)) then
   case (fsm) is
      when ST_WRITE =>
        if(full = '0') then
          DataIn <= std_logic_vector(to_unsigned(data, DataIn'length));
          WriteEn <= '1';
          fsm := ST_WAIT;
        end if;

      when ST_WAIT =>
        WriteEn <= '0';
        if(write_rate_slow = true) then
          if(write_cnt = write_cnt_max) then
            fsm := ST_WRITE;
            write_cnt := 0;
            data := data + 1;
          else
            write_cnt := write_cnt + 1;
          end if;
        else
          data := data + 1;
          fsm := ST_WRITE;
        end if;

   end case;
   end if;
   end process write_test;
   
   read_test : process(clk,reset)
      constant wait_cnt_max : integer := 10;
      variable wait_cnt : integer range 0 to wait_cnt_max := 0;
      type states is (ST_READ, ST_WAIT, ST_VALID);
      variable fsm : states := ST_READ;
   begin
   if(reset = '1') then
           fsm := ST_READ;
           ReadEn <= '0';
           wait_cnt := 0;
   elsif(rising_edge(clk)) then
        case(fsm) is
            when ST_READ =>
              if(empty = '0') then
                readEn <= '1';
                fsm := ST_VALID;
              end if;

            when ST_VALID =>
              readEn <= '0';
              if(DataOutValid = '1') then
                rx <= DataOut;
                fsm := ST_WAIT;
              end if;
            
            when ST_WAIT => 
              if(read_rate_slow = true) then
                if(wait_cnt = wait_cnt_max) then
                  wait_cnt := 0;
                  fsm := ST_READ;
                else
                  wait_cnt := wait_cnt + 1;
                end if;
              else
                  fsm := ST_READ;
              end if;

        end case;
   end if;
   end process read_test;

end Behavioral;
