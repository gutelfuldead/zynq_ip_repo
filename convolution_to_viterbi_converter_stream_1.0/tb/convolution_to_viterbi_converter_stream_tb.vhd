library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity convolution_to_viterbi_converter_stream_tb is
    
end convolution_to_viterbi_converter_stream_tb;

architecture arch_tb of convolution_to_viterbi_converter_stream_tb is

    component convolution_to_viterbi_converter_stream_v1_0 is
        port (
        AXIS_ACLK : in std_logic;
        AXIS_ARESETN    : in std_logic;
        S_AXIS_TREADY    : out std_logic;
        S_AXIS_TDATA    : in std_logic_vector(7 downto 0);
        S_AXIS_TVALID    : in std_logic;
        
        M_AXIS_TVALID : out std_logic;
        M_AXIS_TDATA  : out std_logic_vector(15 downto 0);
        M_AXIS_TREADY : in std_logic
        );
    end component convolution_to_viterbi_converter_stream_v1_0;

    constant WORD_SIZE_IN : integer := 8;
    constant WORD_SIZE_OUT : integer := 16;
    constant clk_period : time := 10 ns; -- 100 MHz clock
    constant TEST_WORD_8 : std_logic_vector(7 downto 0) := "00000011";

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';

    signal S_TREADY : std_logic := '0';
    signal S_TDATA  : std_logic_vector(WORD_SIZE_IN-1 downto 0)     := (others => '0');
    signal M_TDATA  : std_logic_vector(WORD_SIZE_OUT-1 downto 0)     := (others => '0');
    signal S_TVALID : std_logic := '0';
    signal M_TVALID : std_logic := '0';
    signal M_TREADY : std_logic := '0';

    signal new_msg : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');

begin

    DUT : convolution_to_viterbi_converter_stream_v1_0
    port map(
        AXIS_ACLK    => clk,
        AXIS_ARESETN => reset,
        S_AXIS_TREADY  => S_TREADY,
        S_AXIS_TDATA   => S_TDATA,
        S_AXIS_TVALID  => S_TVALID,
        M_AXIS_TVALID  => M_TVALID,
        M_AXIS_TDATA   => M_TDATA,
        M_AXIS_TREADY  => M_TREADY
        );

    clk_process : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_process;
    
    rst_proc : process(clk)
       constant rst_cnt : integer := 2000;
       variable cnt : integer range 0 to rst_cnt := rst_cnt;
    begin
       if(rising_edge(clk)) then
           if (cnt = rst_cnt) then
               reset <= '0';
               cnt := 0;
           else
               reset <= '1';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

   slave_proc_tb : process(clk,reset)
        type fsm_states is (ST_NEW_MSG, ST_WORKING);
        variable fsm : fsm_states := ST_NEW_MSG;
        variable roll : integer := 0;
   begin
   if(reset = '0') then
        fsm := ST_NEW_MSG;
        S_TVALID <= '0';
        S_TDATA  <= (others => '0');
   elsif(rising_edge(clk)) then
        case(fsm) is
            when ST_NEW_MSG =>
                S_TDATA  <= std_logic_vector(rotate_left(unsigned(TEST_WORD_8),roll));
                S_TVALID <= '1';
                fsm := ST_WORKING;

            when ST_WORKING =>
                if(S_TREADY = '1') then
                    S_TVALID <= '0';
                    S_TDATA  <= (others => '0');
                    fsm := ST_NEW_MSG;
                    roll := roll + 1;
                end if;

        end case;
    end if;
   end process slave_proc_tb;


   mstr_proc_tb : process(clk,reset)
    type fsm_mstr_states is (ST_WORK, ST_RESET);
    variable fsm : fsm_mstr_states := ST_RESET;
   begin
   if(reset = '0') then
        M_TREADY <= '0';
        fsm := ST_RESET;
   elsif(rising_edge(clk)) then

        case(fsm) is
        when ST_RESET =>
            fsm := ST_WORK;
            M_TREADY <= '0';

        when ST_WORK =>
            if(M_TVALID = '1') then
                M_TREADY <= '1';
                new_msg <= M_TDATA;
                fsm := ST_RESET;
            end if;
        end case;
    end if;
   end process mstr_proc_tb;


end arch_tb;
