library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity axi_master_stream_tb is
--port();
end axi_master_stream_tb;

architecture tb of axi_master_stream_tb is

    constant C_M_AXIS_TDATA_WIDTH  : integer := 32


     -- AXI Master Stream Ports
    signal M_AXIS_TVALID   : std_logic;
    signal M_AXIS_TDATA    : std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0);
    signal M_AXIS_TSTRB    : std_logic_vector((C_M_AXIS_TDATA_WIDTH/8)-1 downto 0);
    signal M_AXIS_TLAST    : std_logic;
    signal M_AXIS_TREADY   : std_logic;
    signal M_AXIS_ACLK : in std_logic;
    signal M_AXIS_ARESETN  : in std_logic;

	constant clk_period : time := 10 ns; -- 100 MHz clock
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';

    signal user_din    : in std_logic_vector(C_M_AXIS_TDATA_WIDTH-1 downto 0) := (others => '0');
    signal user_dvalid : in std_logic  := '0'; 
    signal user_txdone : out std_logic := '0';
    signal axis_rdy    : out std_logic := '0';
    signal axis_last   : in std_logic  := '0';

begin    

    DUT : axi_master_stream
    generic map( C_M_AXIS_TDATA_WIDTH => C_M_AXIS_TDATA_WIDTH )
    port map(
        user_din => user_din,
        user_dvalid => user_dvalid,
        user_txdone => user_txdone,
        axis_rdy => axis_rdy,
        axis_last => axis_last,
        M_AXIS_TVALID => M_AXIS_TVALID,
        M_AXIS_TDATA => M_AXIS_TDATA,
        M_AXIS_TSTRB => M_AXIS_TSTRB,
        M_AXIS_TLAST => M_AXIS_TLAST,
        M_AXIS_TREADY => M_AXIS_TREADY,
        M_AXIS_ACLK  => M_AXIS_ACLK,
        M_AXIS_ARESETN => M_AXIS_ARESETN
        );

    M_AXIS_ACLK <= clk;
    M_AXIS_ARESETN <= not reset;

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

   mstr_tb : process(clk,reset)
        type fsm_states is (ST_IDLE, ST_WAIT);
        variable fsm : fsm_states := ST_IDLE;
        variable last : std_logic := '0';
        constant last_len : integer := 10;
        variable cnt : integer range 0 to last_len := 0;
   begin
   if (reset = '1') then
        last := '0';
        cnt  := 0;
        fsm := ST_IDLE;
        user_din <= (others => '0');
        axis_last <= '0';
        user_dvalid <= '0';
   elsif(rising_edge(clk)) then
   case(fsm) is
        when ST_IDLE =>
            if(axis_rdy = '1') then
                user_dvalid <= '1';
                user_din <= (others => '1');
                axis_last <= last;
                ST_WAIT;
            end if;

        when ST_WAIT =>
            user_dvalid <= '0';
            fsm := ST_IDLE;
            if(cnt = last_len)
                cnt := 0;
                last := '1';
            else
                cnt := cnt + 1;
            end if;

   end case;
   end if;
   end process mstr_tb;

end tb;