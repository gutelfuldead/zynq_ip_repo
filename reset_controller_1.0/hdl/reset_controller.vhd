library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_controller is
	Port ( 
	clk : in STD_LOGIC;
	reset : in std_logic;
	aresetn_viterbi : out STD_LOGIC;
	ps_reset_viterbi : in std_logic
	);
end reset_controller;

architecture imp of reset_controller is

	type fsm_states is (ST_IDLE, ST_RESET);
	constant MAXR : integer := 2;

begin

	viterbi_reset : process(clk,reset)
		variable fsm : fsm_states := ST_IDLE;
		variable cnt : integer range 0 to MAXR := 0;
	begin
	if(reset = '1') then
		fsm := ST_RESET;
		cnt := 0;
	elsif(rising_edge(clk)) then
		case(fsm) is
		when ST_IDLE =>
			aresetn_viterbi <= '1';
			if(ps_reset_viterbi = '1') then
				fsm := ST_RESET;
			end if;
		when ST_RESET =>
			aresetn_viterbi <= '0';
			if(cnt = MAXR) then
				cnt := 0;
				fsm := ST_IDLE;
			else
				cnt := cnt + 1;
			end if;
		when others =>
			fsm := ST_IDLE;
		end case;
	end if;
	end process viterbi_reset;

end imp;