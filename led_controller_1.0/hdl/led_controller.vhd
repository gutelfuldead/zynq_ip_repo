library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity led_controller is
	generic(
		NUM_LEDS : integer := 7;
		CYCLES_ON : integer := 250000
		);
	port(
		clk : in std_logic;
		en  : in std_logic;
		rst : in std_logic;
		led_ctrl : in  std_logic_vector(NUM_LEDS-1 downto 0);
        led_out  : out std_logic_vector(NUM_LEDS-1 downto 0)
        );
end led_controller;

architecture behavorial of led_controller is

	signal sig_start_led : std_logic_vector(NUM_LEDS-1 downto 0) := (others => '0');
	type int_array is array (0 to NUM_LEDS-1) of integer;

begin

	pulse_duration : process(clk) is
        variable width_cnt : int_array;
        variable v_go : std_logic_vector(NUM_LEDS-1 downto 0) := (others => '0');	
    begin
	if(rising_edge(clk)) then
		if(rst = '1') then
			led_out <= (others => '0');
			v_go    := (others => '0');
			for i in 0 to NUM_LEDS-1 loop
				width_cnt(i) := 0;
			end loop;
		else
			for i in 0 to NUM_LEDS-1 loop
				if(sig_start_led(i) = '1' or v_go(i) = '1') then
					if(width_cnt(i) < CYCLES_ON) then
						v_go(i) := '1';
						width_cnt(i) := width_cnt(i) + 1;
						led_out(i) <= '1';
					else
						width_cnt(i) := 0;
						v_go(i) := '0';
					end if;		
                end if;
			end loop;
		end if;
	end if;
	end process pulse_duration;

    pulse_capture : process(clk) is
    begin
    if(rising_edge(clk)) then
    	if(rst = '1') then
            sig_start_led <= (others => '0');
		else
	    	for i in 0 to NUM_LEDS-1 loop
	    		if(led_ctrl(i) = '1') then
	    			sig_start_led(i) <= '1';
				else
					sig_start_led(i) <= '0';
	    		end if;
	    	end loop;
        end if;
    end if;
    end process pulse_capture;

end behavorial;

