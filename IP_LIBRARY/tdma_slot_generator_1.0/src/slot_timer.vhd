----------------------------------------------------------------------------------
-- Engineer: Jason Gutel
--
-- Create Date: 03/17/2017 09:01:05 AM
-- Design Name:
-- Module Name: slot_timer - Behavioral
-- Project Name:
-- Target Devices: Zynq 7020
-- Tool Versions:  Vivado 2015.4
-- Description:
--    this core takes an input GPS PPS signal to generate the time slots for a
--    tdma system. The core outputs a pulse indicating the begining of every new
--    time slot with a controllable duty cycle.
--    
--    The core will generate new output pulses (based on the input length (in ms)
--    until a full second has elapsed. If no new PPS is recieved the core goes
--    to a standby mode and waits for a new signal outputing nothing.
-- 
--    The output signal and input pps signal are configured to be active-high.
--
-- Using the core:
--    stimulating data transfer to a modem for tx by using the output signal
--    of this core ANDed with a tx_data_ready signal to indicate transfer ready.
--    Setting the duty cycle of the core to be the maximum delay possible
--    for processing overhead to ensure the full frame can be transferred
--    WITHOUT overlapping into the next frame (this is dependent on the
--    size of the data frame to be transferred and the latency/throughput
--    to the modem itself).
--
-- Dependencies:
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.ALL;

entity slot_timer is
    generic (
        slot_time_ms   : in integer range 10 to 333 := 25; -- time slot duration in milliseconds
        clk_freq       : in integer := 100000000;          -- fabric clock frequency for calculations
        pulse_duty     : in integer range 10 to 50 := 10); -- duty cycle of the output pulse to the slot duration
    Port (
        clk              : in std_logic;  -- Fabric Clock
        reset            : in std_logic;  -- Reset Signal
        en               : in std_logic;  -- Enable signal
        gps_pps          : in std_logic;  -- input signal to start the timer (pps)
        tdma_slt_pulse   : out std_logic;  -- output pulse to indicate a time slot window
        irq              : out std_logic
        
--         debug ports (comment out in production)
        ;
        d_count : out integer;
        d_pulse_cnt : out integer;
        d_cycles : out integer;
        d_full_frame_cnt : out integer;
        d_pulse_duration : out integer;
        d_fsm : out std_logic_vector(1 downto 0)
    );
end slot_timer;

architecture Behavioral of slot_timer is

    type fsm is (
        ST_RST,    -- clear everything --> st_new_pps
        ST_ENA,    -- begin counting from PPS signal
        ST_NEW_PPS -- clear enable and start new pulse
        );

     signal state_present  : fsm       := ST_RST; 
     signal state_next     : fsm       := ST_RST;
     signal cycles         : integer   := clk_freq * slot_time_ms / 1000; -- number of cycles to count to (500 = 1000 ms / 2 clock)
     signal full_frame_cnt : integer   := 1000/slot_time_ms; -- how many cycles per slot (1s/time in ms)
     signal count          : integer   := 0; -- internal count up to full_frame_cnt
     signal cnt_out        : integer   := 0; -- total number of pulses generated from this PPS
     signal pulse          : std_logic := '0'; -- '0' pulse off, '1' pulse on
     signal pulse_duration : integer   := cycles * pulse_duty / 100; -- number of cycles for pulse's duty cycle     
     signal s_en : std_logic := '0';
     signal s_interrupt : std_logic := '0';

begin

    s_en <= en;
---------------------------------------------------
    -- debug signals (comment out in production)
    d_count <= count;
    d_cycles <= cycles;
    d_full_frame_cnt <= full_frame_cnt;
    d_pulse_duration <= pulse_duration;   
    with state_present select
        d_fsm <= "00" when ST_RST,
                 "01" when ST_ENA,
                 "10" when ST_NEW_PPS,
                 "11" when others;    
---------------------------------------------------
    -- internal wire from signal pulse to output pulse and irq lines
    tdma_slt_pulse <= pulse;
    irq <= s_interrupt;
---------------------------------------------------
    -- state updates
    fsm_state : process(clk, state_next, reset)
        begin
            if(rising_edge(clk)) then   
                    if(reset = '1') then  -- synchronous reset
                        state_present <= ST_RST;     
                    else
                        state_present <= state_next;
                    end if;
            end if;
         end process fsm_state;
---------------------------------------------------
    -- process for present states
    main_fsm : process(clk, gps_pps, state_present, s_en)
       begin
           if(rising_edge(clk)) then
               if (s_en = '1') then
                   case state_present is
   
                       -- reset's all signals and waits for input pulse
                       when ST_RST =>
                           count <= 0;
                           cnt_out <= 0;
                           pulse <= '0';
                           s_interrupt <= '0';
                           if(gps_pps = '1') then -- synchronous start
                               s_interrupt <= '1';
                               state_next <= ST_NEW_PPS;
                           end if;
   
                       -- active pulse cycles
                       when ST_ENA =>
                           s_interrupt <= '0';
                           count <= count + 1;       -- increment counter
                           if(gps_pps = '1') then    -- reset the counter
                               state_next <= ST_NEW_PPS;
                               s_interrupt <= '1';
                           elsif(count >= cycles) then   -- generate interrupt here and reset the counter
                               cnt_out <= cnt_out + 1;
                               if(cnt_out >= full_frame_cnt - 1) then -- completed frame wait for new PPS
                                   state_next <= ST_RST;
                               else
                                   s_interrupt <= '1';
                                   pulse <= '1';
                                   count <= 0;
                               end if;
                           end if;
   
                           -- keep pulse high for pulse_duration
                           if(pulse = '1' and count >= pulse_duration) then
                               pulse <= '0';
                           end if;
                           
                        -- clear current operations and configure for new pulse
                        -- wait until the current pulse ends before starting ST_ENA   
                        when ST_NEW_PPS =>
                           count <= 0;
                           s_interrupt <= '0';
                           if(gps_pps = '0') then
                               pulse <= '1';
                               state_next <= ST_ENA;
                           end if;
                           
                        when others =>
                           state_next <= ST_RST;                        
                   end case;
               else -- if s_en = '0' key reset and clear pulse
                   state_next <= ST_RST;
                   pulse <= '0';
               end if;
           end if;
       end process main_fsm;  
       
end Behavioral;
