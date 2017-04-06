-- debug software mode
--  gps_pps input port replaced w/ signal to stimulate from ps
-- release mode
--  uncomment gps_pps port and comment out gps_pps signal
--  comment out the gps_pps <= slv_reg1(0) in tdma_slot_generator_v1_0_S00_AXI_inst.vhd

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity tdma_slot_generator_v1_0 is
	generic (
		-- Users to add parameters here
        slot_time_ms   : in integer range 10 to 333 := 25; -- time slot duration in milliseconds
        clk_freq       : in integer := 100;          -- fabric clock frequency for calculations (MHz)
        pulse_duty     : in integer range 10 to 50 := 10; -- duty cycle of the output pulse to the slot duration
		-- User parameters ends
		-- Do not modify the parameters beyond this line


		-- Parameters of Axi Slave Bus Interface S00_AXI
		C_S00_AXI_DATA_WIDTH	: integer	:= 32;
		C_S00_AXI_ADDR_WIDTH	: integer	:= 4;

		-- Parameters of Axi Slave Bus Interface S_AXI_INTR
		C_S_AXI_INTR_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_INTR_ADDR_WIDTH	: integer	:= 5;
		C_NUM_OF_INTR	: integer	:= 1;
		C_INTR_SENSITIVITY	: std_logic_vector	:= x"FFFFFFFF";
		C_INTR_ACTIVE_STATE	: std_logic_vector	:= x"FFFFFFFF";
		C_IRQ_SENSITIVITY	: integer	:= 1;
		C_IRQ_ACTIVE_STATE	: integer	:= 1
	);
	port (
		-- Users to add ports here
        clk              : in std_logic;  -- Fabric Clock
        gps_pps          : in std_logic;  -- input signal to start the timer (pps)
        tdma_slt_pulse   : out std_logic;  -- output pulse to indicate a time slot window
		-- User ports ends
		-- Do not modify the ports beyond this line


		-- Ports of Axi Slave Bus Interface S00_AXI
		s00_axi_aclk	: in std_logic;
		s00_axi_aresetn	: in std_logic;
		s00_axi_awaddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_awprot	: in std_logic_vector(2 downto 0);
		s00_axi_awvalid	: in std_logic;
		s00_axi_awready	: out std_logic;
		s00_axi_wdata	: in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_wstrb	: in std_logic_vector((C_S00_AXI_DATA_WIDTH/8)-1 downto 0);
		s00_axi_wvalid	: in std_logic;
		s00_axi_wready	: out std_logic;
		s00_axi_bresp	: out std_logic_vector(1 downto 0);
		s00_axi_bvalid	: out std_logic;
		s00_axi_bready	: in std_logic;
		s00_axi_araddr	: in std_logic_vector(C_S00_AXI_ADDR_WIDTH-1 downto 0);
		s00_axi_arprot	: in std_logic_vector(2 downto 0);
		s00_axi_arvalid	: in std_logic;
		s00_axi_arready	: out std_logic;
		s00_axi_rdata	: out std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
		s00_axi_rresp	: out std_logic_vector(1 downto 0);
		s00_axi_rvalid	: out std_logic;
		s00_axi_rready	: in std_logic;

		-- Ports of Axi Slave Bus Interface S_AXI_INTR
		s_axi_intr_aclk	: in std_logic;
		s_axi_intr_aresetn	: in std_logic;
		s_axi_intr_awaddr	: in std_logic_vector(C_S_AXI_INTR_ADDR_WIDTH-1 downto 0);
		s_axi_intr_awprot	: in std_logic_vector(2 downto 0);
		s_axi_intr_awvalid	: in std_logic;
		s_axi_intr_awready	: out std_logic;
		s_axi_intr_wdata	: in std_logic_vector(C_S_AXI_INTR_DATA_WIDTH-1 downto 0);
		s_axi_intr_wstrb	: in std_logic_vector((C_S_AXI_INTR_DATA_WIDTH/8)-1 downto 0);
		s_axi_intr_wvalid	: in std_logic;
		s_axi_intr_wready	: out std_logic;
		s_axi_intr_bresp	: out std_logic_vector(1 downto 0);
		s_axi_intr_bvalid	: out std_logic;
		s_axi_intr_bready	: in std_logic;
		s_axi_intr_araddr	: in std_logic_vector(C_S_AXI_INTR_ADDR_WIDTH-1 downto 0);
		s_axi_intr_arprot	: in std_logic_vector(2 downto 0);
		s_axi_intr_arvalid	: in std_logic;
		s_axi_intr_arready	: out std_logic;
		s_axi_intr_rdata	: out std_logic_vector(C_S_AXI_INTR_DATA_WIDTH-1 downto 0);
		s_axi_intr_rresp	: out std_logic_vector(1 downto 0);
		s_axi_intr_rvalid	: out std_logic;
		s_axi_intr_rready	: in std_logic;
		irq	: out std_logic
	);
end tdma_slot_generator_v1_0;

architecture arch_imp of tdma_slot_generator_v1_0 is

	-- component declaration
	component tdma_slot_generator_v1_0_S00_AXI is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 4
		);
		port (
        TDMA_EN              : out std_logic; -- enable signal for device
        TDMA_RESET           : out std_logic; -- reset signal for device
        TDMA_DUTY            : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        TDMA_DURATION        : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
        PULSE_TYPE           : in std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0);
--        gps_pps              : out std_logic; -- comment out in release
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic
		);
	end component tdma_slot_generator_v1_0_S00_AXI;

	component tdma_slot_generator_v1_0_S_AXI_INTR is
		generic (
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		C_S_AXI_ADDR_WIDTH	: integer	:= 5;
		C_NUM_OF_INTR	: integer	:= 1;
		C_INTR_SENSITIVITY	: std_logic_vector	:= x"FFFFFFFF";
		C_INTR_ACTIVE_STATE	: std_logic_vector	:= x"FFFFFFFF";
		C_IRQ_SENSITIVITY	: integer	:= 1;
		C_IRQ_ACTIVE_STATE	: integer	:= 1
		);
		port (
        TDMA_INTERRUPT : in std_logic;
		S_AXI_ACLK	: in std_logic;
		S_AXI_ARESETN	: in std_logic;
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		S_AXI_AWVALID	: in std_logic;
		S_AXI_AWREADY	: out std_logic;
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID	: in std_logic;
		S_AXI_WREADY	: out std_logic;
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		S_AXI_BVALID	: out std_logic;
		S_AXI_BREADY	: in std_logic;
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		S_AXI_ARVALID	: in std_logic;
		S_AXI_ARREADY	: out std_logic;
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		S_AXI_RVALID	: out std_logic;
		S_AXI_RREADY	: in std_logic;
		irq	: out std_logic
		);
	end component tdma_slot_generator_v1_0_S_AXI_INTR;

type t_fsm is (
     ST_RST,    -- clear everything --> st_new_pps
     ST_ENA,    -- begin counting from PPS signal
     ST_NEW_PPS -- clear enable and start new pulse
     );

     -- internal signals
     signal s_state_present : t_fsm := ST_RST;
     signal s_state_next    : t_fsm := ST_RST;
     signal s_pulse         : std_logic := '0'; -- '0' pulse off, '1' pulse on
     signal s_irq           : std_logic := '0'; -- active high interrupt
     signal s_duty_en       : std_logic := '0'; -- enables duty cycle generator
     signal s_en            : std_logic := '0'; -- general master enable
     signal s_reset         : std_logic := '0'; -- general master reset
     signal s_dur           : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) -- send pulse_duty value to ps via axi
        := std_logic_vector(to_unsigned(slot_time_ms, C_S00_AXI_DATA_WIDTH));
     signal s_duty          : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) -- send slot_time_ms to ps via axi
        := std_logic_vector(to_unsigned(pulse_duty,C_S00_AXI_DATA_WIDTH));
     signal s_pulse_type    : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) 
        := (others => '0'); -- indicates interrupt type (111111=0x3f new gps pps, 101010=0x2a mid frame slot)

     -- calculation constants
     -- verbose calculations (not synthesizable):
     --     c_freq           := clk_freq * 1000000; -- MHz
     --     c_cycles         := c_freq * slot_time_ms / 1000; 
     --     c_full_frame_cnt := 1000 / slot_time_ms;            
     --     c_pulse_duration := c_cycles * pulse_duty / 100;    
     constant c_cycles         : natural := integer(clk_freq * 1000 * slot_time_ms);   -- number of cycles between slots
     constant c_full_frame_cnt : natural := integer(floor(real(1000 / slot_time_ms))); -- how many cycles per slot (1s/time in ms)
     constant c_pulse_duration : natural := integer(clk_freq * 10 * pulse_duty * slot_time_ms); -- duty cycle (on)
     constant c_zeros          : std_logic_vector(C_S00_AXI_DATA_WIDTH-1 downto 0) := (others => '0');

     -- version 1
--     signal gps_pps : std_logic := '0';

begin

    -- Instantiation of Axi Bus Interface S00_AXI
    tdma_slot_generator_v1_0_S00_AXI_inst : tdma_slot_generator_v1_0_S00_AXI
        generic map (
            C_S_AXI_DATA_WIDTH	=> C_S00_AXI_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH	=> C_S00_AXI_ADDR_WIDTH
        )
        port map (
            TDMA_EN        => s_en, 
            TDMA_RESET     => s_reset, 
            TDMA_DUTY      => s_duty,
            TDMA_DURATION  => s_dur, 
            PULSE_TYPE     => s_pulse_type,
--            gps_pps        => gps_pps,
            S_AXI_ACLK	=> s00_axi_aclk,
            S_AXI_ARESETN	=> s00_axi_aresetn,
            S_AXI_AWADDR	=> s00_axi_awaddr,
            S_AXI_AWPROT	=> s00_axi_awprot,
            S_AXI_AWVALID	=> s00_axi_awvalid,
            S_AXI_AWREADY	=> s00_axi_awready,
            S_AXI_WDATA	=> s00_axi_wdata,
            S_AXI_WSTRB	=> s00_axi_wstrb,
            S_AXI_WVALID	=> s00_axi_wvalid,
            S_AXI_WREADY	=> s00_axi_wready,
            S_AXI_BRESP	=> s00_axi_bresp,
            S_AXI_BVALID	=> s00_axi_bvalid,
            S_AXI_BREADY	=> s00_axi_bready,
            S_AXI_ARADDR	=> s00_axi_araddr,
            S_AXI_ARPROT	=> s00_axi_arprot,
            S_AXI_ARVALID	=> s00_axi_arvalid,
            S_AXI_ARREADY	=> s00_axi_arready,
            S_AXI_RDATA	=> s00_axi_rdata,
            S_AXI_RRESP	=> s00_axi_rresp,
            S_AXI_RVALID	=> s00_axi_rvalid,
            S_AXI_RREADY	=> s00_axi_rready
        );

    -- Instantiation of Axi Bus Interface S_AXI_INTR
    tdma_slot_generator_v1_0_S_AXI_INTR_inst : tdma_slot_generator_v1_0_S_AXI_INTR
        generic map (
            C_S_AXI_DATA_WIDTH	=> C_S_AXI_INTR_DATA_WIDTH,
            C_S_AXI_ADDR_WIDTH	=> C_S_AXI_INTR_ADDR_WIDTH,
            C_NUM_OF_INTR	=> C_NUM_OF_INTR,
            C_INTR_SENSITIVITY	=> C_INTR_SENSITIVITY,
            C_INTR_ACTIVE_STATE	=> C_INTR_ACTIVE_STATE,
            C_IRQ_SENSITIVITY	=> C_IRQ_SENSITIVITY,
            C_IRQ_ACTIVE_STATE	=> C_IRQ_ACTIVE_STATE
        )
        port map (
            TDMA_INTERRUPT => s_irq, --: in std_logic;
            S_AXI_ACLK	=> s_axi_intr_aclk,
            S_AXI_ARESETN	=> s_axi_intr_aresetn,
            S_AXI_AWADDR	=> s_axi_intr_awaddr,
            S_AXI_AWPROT	=> s_axi_intr_awprot,
            S_AXI_AWVALID	=> s_axi_intr_awvalid,
            S_AXI_AWREADY	=> s_axi_intr_awready,
            S_AXI_WDATA	=> s_axi_intr_wdata,
            S_AXI_WSTRB	=> s_axi_intr_wstrb,
            S_AXI_WVALID	=> s_axi_intr_wvalid,
            S_AXI_WREADY	=> s_axi_intr_wready,
            S_AXI_BRESP	=> s_axi_intr_bresp,
            S_AXI_BVALID	=> s_axi_intr_bvalid,
            S_AXI_BREADY	=> s_axi_intr_bready,
            S_AXI_ARADDR	=> s_axi_intr_araddr,
            S_AXI_ARPROT	=> s_axi_intr_arprot,
            S_AXI_ARVALID	=> s_axi_intr_arvalid,
            S_AXI_ARREADY	=> s_axi_intr_arready,
            S_AXI_RDATA	=> s_axi_intr_rdata,
            S_AXI_RRESP	=> s_axi_intr_rresp,
            S_AXI_RVALID	=> s_axi_intr_rvalid,
            S_AXI_RREADY	=> s_axi_intr_rready,
            irq	=> irq
        );

---------------------------------------------------

  -- internal wire from signal pulse to output pulse
  tdma_slt_pulse <= s_pulse;

---------------------------------------------------

    -- update state machine 
    fsm_state : process(clk)
        begin
            if(rising_edge(clk)) then
                if(s_en = '1') then
                    if(s_reset = '1') then  -- synchronous reset
                        s_state_present <= ST_RST;
                    else
                        s_state_present <= s_state_next;
                    end if;
                else -- en = '0'
                    s_state_present <= ST_RST;
                end if;
            end if;
         end process fsm_state;


---------------------------------------------------

    -- generate output pulse duty cycle
    -- uses the s_irq signal to start a new pulse
    duty_cycle_generator : process(clk)
            variable v_duty_cnt  : natural range 0 to c_pulse_duration + 1 := c_pulse_duration + 1;  -- counts the duty cycles
        begin
        if(rising_edge(clk)) then
            if(s_duty_en = '1') then
            
              if(s_irq = '1') then
                  v_duty_cnt := 0;
              end if;
              
              if(v_duty_cnt < c_pulse_duration) then
                v_duty_cnt := v_duty_cnt + 1;
                s_pulse <= '1';
              else
                s_pulse <= '0';
              
              end if;
            else -- s_duty_en = '0'
                s_pulse <= '0';
                v_duty_cnt := c_pulse_duration + 1;
            end if;
        end if;
    end process duty_cycle_generator;

---------------------------------------------------

    -- fsm operations
  main_fsm : process(clk)
      variable v_cycle_cnt : natural range 0 to c_cycles := 0; -- counts cycles for new pulse
      variable v_pulse_cnt : natural range 0 to c_full_frame_cnt := 0; -- counts number of pulses emitted
   begin
       if(rising_edge(clk)) then
           if (s_en = '1') then
               case s_state_present is

                   -- reset's all signals and waits for external pps signal
                   when ST_RST =>
                       v_cycle_cnt := 0;
                       v_pulse_cnt := 0;
                       s_duty_en <= '0';
                       s_pulse_type <= (others => '0');
                       s_irq <= '0';
                       if(gps_pps = '1') then  -- synchronous start
                           s_state_next <= ST_NEW_PPS;
                       end if;

                   -- active pulse cycles
                   -- generates an irq at the begining of every new pulse and enables
                   -- the duty cycle generator. Checks for external pulse or goes to 
                   -- reset if all slots are populated and no new pps
                   when ST_ENA =>
                       s_duty_en <= '1';
                       
                       -- update state if gps_pps asserted
                       if(gps_pps = '1') then        -- reset the counter
                           s_state_next <= ST_NEW_PPS;
                       end if;
                       
                       -- assert irq on new slot
                       if(v_cycle_cnt = 0) then 
                          s_irq <= '1';
                          v_cycle_cnt := v_cycle_cnt + 1;
                       else
                          s_irq <= '0';
                          v_cycle_cnt := v_cycle_cnt + 1;
                       end if;
                       
                       -- keep track of number of pulses
                       -- update state when all pulses have finished
                       if(v_cycle_cnt >= c_cycles) then   -- new pulse
                           if(v_pulse_cnt < c_full_frame_cnt - 1) then
                              v_pulse_cnt := v_pulse_cnt + 1;
                              v_cycle_cnt := 0;
                              s_pulse_type <= c_zeros(C_S00_AXI_DATA_WIDTH-1 downto 6) & "101010";
                           else -- reset state
                               s_state_next <= ST_RST;
                           end if;
                       end if;

                    -- clear current operations and configure for new pulse
                    -- when pps signal goes low start new slot pulses
                    when ST_NEW_PPS =>
                       v_cycle_cnt := 0;
                       v_pulse_cnt := 0;
                       s_irq <= '0';
                       s_duty_en <= '0';
                       if(gps_pps = '0') then
                           s_state_next <= ST_ENA;
                           s_pulse_type <= c_zeros(C_S00_AXI_DATA_WIDTH-1 downto 6) & "111111";
                       end if;

                    when others =>
                       s_state_next <= ST_RST;
               end case;
           else -- en = '0'
              s_irq   <= '0';
              s_duty_en <= '0';
              s_state_next <= ST_RST;
           end if;
       end if;
   end process main_fsm;

 

end arch_imp;
