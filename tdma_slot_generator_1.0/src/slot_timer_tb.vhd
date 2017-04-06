----------------------------------------------------------------------------------
-- test bench for slot_timer.vhd
-- Make sure to uncomment core debug ports before running testbench
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity slot_timer_tb is
--  Port ( );
end slot_timer_tb;

architecture Behavioral of slot_timer_tb is

    component slot_timer is
        generic (
            slot_time_ms   : integer := 25;        -- 25 ms
            clk_freq    : integer := 100000000;
            pulse_duty  : integer := 10);   -- fabric clock frequency
        Port (
            clk              : in STD_LOGIC;  -- Fabric Clock
            reset            : in STD_LOGIC;  -- Reset Signal
            en               : in STD_LOGIC; -- enable pin
            gps_pps       : in  STD_LOGIC; -- START TIMER
            tdma_slt_pulse     : out STD_LOGIC; -- TIMER END OUTPUT PULSE
            irq                : out std_logic;
            
            -- debug ports
            d_count : out integer;
            d_cycles : out integer;
            d_full_frame_cnt : out integer;
            d_pulse_duration : out integer;
            d_fsm : out std_logic_vector(1 downto 0)
            );
    end component slot_timer;

    signal slot_time    : integer := 333;
    signal clk_freq     : integer := 100000000; -- 100 MHz
    signal en           : std_logic := '0';
    signal clk          : std_logic;
    signal reset        : std_logic := '0';
    signal gps_pps      : std_logic := '0';
    signal tdma_slt_pulse : std_logic;
    signal pulse_duty   : integer := 15;
    signal s_irq : std_logic := '0';
    
    signal d_count : integer;
    signal d_cycles : integer;
    signal d_full_frame_cnt : integer;
    signal d_pulse_duration : integer;
    signal d_fsm : std_logic_vector(1 downto 0);

    constant clk_period : time := 10 ns; -- 100 MHz clock

begin

    -- generate clock
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process clk_process;

    -- connect device
    timer : slot_timer
    generic map(
        slot_time_ms => slot_time,
        clk_freq  => clk_freq,
        pulse_duty => pulse_duty
        )
    port map(
        irq => s_irq,
        clk              => clk,
        reset            => reset,
        en => en,
        gps_pps            => gps_pps,
        tdma_slt_pulse     => tdma_slt_pulse,
        d_count => d_count,
        d_cycles => d_cycles,
        d_full_frame_cnt => d_full_frame_cnt,
        d_pulse_duration => d_pulse_duration,
        d_fsm => d_fsm
        );

    tb : process
    begin
    
        -- test enable
         wait for 100 ns;
         en <= '0';
         reset <= '1';
         wait for 100 ns;
         reset <= '0';
         wait for 100 ns;
         gps_pps <= '1';
         wait for 1000 ns;
         gps_pps <= '0';
         wait for 100 ns;
         en <= '1';
         wait for 100 ns;
         gps_pps <= '1';
         wait for 100 ns;
         gps_pps <= '0';
         wait for 100 ns;
         en <= '0';

        -- test to see if counter overflow will send to reset state
        wait for 100 ns;
        en <= '1';
        reset <= '1';
        wait for 100 ns;
        reset <= '0';
        wait for 100 ns;
        gps_pps <= '1';
        wait for 100 ns;
        gps_pps <= '0';
        wait for 1000000000 ns; -- wait for one second
        wait for 50000000 ns; -- wait for 50 ms

        -- start new pps and interrupt it midway with another
--        reset <= '1';
--        wait for 100 ns;
--        reset <= '0';
--        wait for 100 ns;
--        gps_pps <= '1';
--        wait for 100 ns;
--        gps_pps <= '0';
--        wait for 80000000 ns; -- wait for 80 ms
--        gps_pps <= '1';
--        wait for 100 ns; 
--        gps_pps <= '0';
--        wait for 80000000 ns; -- wait for 80 ms
        
        -- dont turn pps signal off (should never start until pps goes low)
--        reset <= '1';
--        wait for 100 ns;
--        reset <= '0';
--        gps_pps <= '1';
--        wait for 50000000 ns; -- wait for 50 ms
--        gps_pps <= '0';
--        wait for 50000000 ns; -- wait for 50 ms
        
        reset <= '0';

        

    end process tb;

end Behavioral;
