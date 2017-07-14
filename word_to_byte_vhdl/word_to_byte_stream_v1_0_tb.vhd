library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity word_to_byte_stream_v1_0_tb is
    
end word_to_byte_stream_v1_0_tb;

architecture arch_tb of word_to_byte_stream_v1_0_tb is

    component word_to_byte_stream_v1_0 is
    generic (
    C_M_AXIS_TDATA_WIDTH  : integer := 8;
    C_S_AXIS_TDATA_WIDTH  : integer := 32;
    ENDIAN                : string := "BIG" -- "LITTLE"
    );
    port (
    clk : in std_logic;
    reset : in std_logic;

    S_AXIS_ACLK : in std_logic;
    S_AXIS_ARESETN    : in std_logic;
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0);
    S_AXIS_TSTRB    : in std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0);
    S_AXIS_TLAST    : in std_logic;
    S_AXIS_TVALID    : in std_logic;
    
    M_AXIS_ACLK : in std_logic;
    M_AXIS_ARESETN  : in std_logic;
    M_AXIS_TVALID : out std_logic;
    M_AXIS_TDATA  : out std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    M_AXIS_TSTRB  : out std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    M_AXIS_TLAST  : out std_logic;
    M_AXIS_TREADY : in std_logic
    );
    end component;

    constant C_M_AXIS_TDATA_WIDTH  : integer := 8;
    constant C_S_AXIS_TDATA_WIDTH  : integer := 32;
    constant clk_period : time := 10 ns; -- 100 MHz clock
    constant TEST_WORD : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0) := x"AABBCCDD";

    signal clk           : std_logic := '0';
    signal reset         : std_logic := '0';

    signal S_TREADY : std_logic := '0';
    signal S_ACLK : std_logic := '0';
    signal M_ACLK : std_logic := '0';
    signal S_ARESETN : std_logic := '0';
    signal M_ARESETN : std_logic := '0';
    signal S_TDATA  : std_logic_vector(C_S_AXIS_TDATA_WIDTH-1 downto 0)     := (others => '0');
    signal S_TSTRB  : std_logic_vector((C_S_AXIS_TDATA_WIDTH/8)-1 downto 0) := (others => '0');
    signal M_TDATA  : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0)     := (others => '0');
    signal M_TSTRB  : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0) := (others => '0');
    signal S_TLAST  : std_logic := '0';
    signal S_TVALID : std_logic := '0';
    signal M_TVALID : std_logic := '0';
    signal M_TLAST  : std_logic := '0';
    signal M_TREADY : std_logic := '0';

    signal new_msg : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');

begin

    DUT : word_to_byte_stream_v1_0
    generic map(ENDIAN => "BIG",
    C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH,
    C_S_AXIS_TDATA_WIDTH => C_S_AXIS_TDATA_WIDTH
    )
    port map(
        clk            => clk,
        reset          => reset,
        S_AXIS_ACLK    => S_ACLK,
        S_AXIS_ARESETN => S_ARESETN,
        S_AXIS_TREADY  => S_TREADY,
        S_AXIS_TDATA   => S_TDATA,
        S_AXIS_TSTRB   => S_TSTRB,
        S_AXIS_TLAST   => S_TLAST,
        S_AXIS_TVALID  => S_TVALID,
        M_AXIS_ACLK    => M_ACLK,
        M_AXIS_ARESETN => M_ARESETN,
        M_AXIS_TVALID  => M_TVALID,
        M_AXIS_TDATA   => M_TDATA,
        M_AXIS_TSTRB   => M_TSTRB,
        M_AXIS_TLAST   => M_TLAST,
        M_AXIS_TREADY  => M_TREADY
        );
    S_ACLK <= clk;
    M_ACLK <= clk;
    S_ARESETN <= not reset;
    M_ARESETN <=  not reset;

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
               reset <= '1';
               cnt := 0;
           else
               reset <= '0';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;

   slave_proc_tb : process(clk,reset)
        type fsm_states is (ST_NEW_MSG, ST_WORKING);
        variable fsm : fsm_states := ST_NEW_MSG;
        variable roll : integer := 0;
   begin
   if(reset = '1') then
        fsm := ST_NEW_MSG;
        S_TVALID <= '0';
        S_TDATA  <= (others => '0');
   elsif(rising_edge(clk)) then
        case(fsm) is
            when ST_NEW_MSG =>
                S_TDATA  <= std_logic_vector(rotate_left(unsigned(TEST_WORD),8*roll));
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
   begin
   if(reset = '1') then
        M_TREADY <= '0';
   elsif(rising_edge(clk)) then
        if(M_TVALID = '1') then
            M_TREADY <= '1';
            new_msg <= M_TDATA;
        end if;
    end if;
   end process mstr_proc_tb;


end arch_tb;