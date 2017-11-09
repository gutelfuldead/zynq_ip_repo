library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity interleaver_data_buffer_v1_0_tb is
    
end interleaver_data_buffer_v1_0_tb;

architecture arch_tb of interleaver_data_buffer_v1_0_tb is

    component interleaver_data_buffer_v1_0 is
    generic (
        C_S_AXIS_TDATA_WIDTH    : integer   := 8;
        C_US_AXIS_TDATA_WIDTH   : integer   := 8;
        C_M_AXIS_TDATA_WIDTH    : integer   := 8
    );
    port (
    AXIS_ACLK   : in std_logic;
    AXIS_ARESETN : in std_logic;
    -- data slave interface
    S_AXIS_TREADY   : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TVALID   : in std_logic;
    -- user data slave interface
    US_AXIS_TREADY  : out std_logic;
    US_AXIS_TDATA   : in std_logic_vector(C_US_AXIS_TDATA_WIDTH-1 downto 0);
    US_AXIS_TVALID  : in std_logic;
    -- master interface
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TREADY : in std_logic
    );
    end component interleaver_data_buffer_v1_0;

    constant WORD_SIZE_OUT  : integer := 8;
    constant WORD_SIZE_IN  : integer := 8;
    constant clk_period : time := 10 ns; -- 100 MHz clock

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';

    signal S_TREADY  : std_logic := '0';
    signal S_TVALID  : std_logic := '0';
    signal US_TREADY : std_logic := '0';
    signal US_TVALID : std_logic := '0';
    signal M_TVALID  : std_logic := '0';
    signal M_TREADY  : std_logic := '0';
    signal US_TDATA  : std_logic_vector(WORD_SIZE_IN-1 downto 0)  := (others => '0');
    signal S_TDATA   : std_logic_vector(WORD_SIZE_IN-1 downto 0)  := (others => '0');
    signal M_TDATA   : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');

    constant READY : std_logic_vector(WORD_SIZE_IN-1 downto 0) := "00000010";
    constant NOT_READY : std_logic_vector(WORD_SIZE_IN-1 downto 0) := (others => '0');
    constant TEST_WORD : std_logic_vector(WORD_SIZE_IN-1 downto 0) := "10100110";
    signal new_msg : std_logic_vector(WORD_SIZE_OUT-1 downto 0) := (others => '0');

begin

    DUT : interleaver_data_buffer_v1_0
    generic map (
        C_S_AXIS_TDATA_WIDTH    => WORD_SIZE_IN,
        C_US_AXIS_TDATA_WIDTH   => WORD_SIZE_IN,
        C_M_AXIS_TDATA_WIDTH    => WORD_SIZE_OUT )
    port map (
    AXIS_ACLK    => clk,
    AXIS_ARESETN => reset,
    -- data slave interface
    S_AXIS_TREADY => S_TREADY,
    S_AXIS_TDATA  => S_TDATA,
    S_AXIS_TVALID => S_TVALID,
    -- user data slave interface
    US_AXIS_TREADY => US_TREADY, 
    US_AXIS_TDATA  => US_TDATA,
    US_AXIS_TVALID => US_TVALID,
    -- master interface
    M_AXIS_TVALID => M_TVALID,
    M_AXIS_TDATA  => M_TDATA,
    M_AXIS_TREADY => M_TREADY
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
                S_TDATA  <= std_logic_vector(rotate_left(unsigned(TEST_WORD),roll));
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

   user_slave_proc_tb : process(clk,reset)
        type fsm_states is (ST_NEW_MSG, ST_WORKING);
        variable fsm : fsm_states := ST_NEW_MSG;
        constant RDY_CNT : integer := 5;
        variable cnt : integer range 0 to RDY_CNT := 0;
   begin
   if(reset = '0') then
        cnt := 0;
        fsm := ST_NEW_MSG;
        US_TVALID <= '0';
        US_TDATA  <= (others => '0');
   elsif(rising_edge(clk)) then
        case(fsm) is
            when ST_NEW_MSG =>
                if(cnt = RDY_CNT) then
                    US_TDATA  <= READY;
                    cnt := 0;
                else
                    US_TDATA  <= NOT_READY;
                    cnt := cnt + 1;
                end if;
                US_TVALID <= '1';
                fsm := ST_WORKING;

            when ST_WORKING =>
                if(US_TREADY = '1') then
                    US_TVALID <= '0';
                    US_TDATA  <= (others => '0');
                    fsm := ST_NEW_MSG;
                end if;
        end case;
    end if;
   end process user_slave_proc_tb;

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
