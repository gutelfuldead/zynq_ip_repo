library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity axis_to_spi_v1_0_tb is
end axis_to_spi_v1_0_tb;

architecture Behavioral of axis_to_spi_v1_0_tb is

    component axis_to_spi_v1_0 is
	generic (
    INPUT_CLK_MHZ : integer := 100;
    SPI_CLK_MHZ   : integer := 10;
    DATA_WIDTH    : integer := 8
	);
	port (
	sclk : out STD_LOGIC;
    sclk_en : out STD_LOGIC;
    mosi : out STD_LOGIC;
    S_AXIS_ACLK	: in std_logic;
    S_AXIS_ARESETN    : in std_logic;
    S_AXIS_TREADY    : out std_logic;
    S_AXIS_TDATA    : in std_logic_vector(DATA_WIDTH-1 downto 0);
    S_AXIS_TVALID    : in std_logic
	);
    end component axis_to_spi_v1_0;
    
    constant INPUT_CLK_MHZ : integer := 100;
    constant SPI_CLK_MHZ   : integer := 10;
    constant DATA_WIDTH    : integer := 8;
    signal sclk, sclk_en, mosi, clk, aresetn, tready, tvalid : std_logic := '0';
    signal tdata : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    constant clk_period : time := 10 ns; -- 100 MHz clock

    
begin

    DUT : axis_to_spi_v1_0
    generic map(
        INPUT_CLK_MHZ => INPUT_CLK_MHZ,
        SPI_CLK_MHZ   => SPI_CLK_MHZ,
        DATA_WIDTH    => DATA_WIDTH
    )
    port map(
        sclk => sclk,
        sclk_en => sclk_en,
        mosi => mosi,
        S_AXIS_ACLK => clk,
        S_AXIS_ARESETN => aresetn,
        S_AXIS_TREADY => tready,
        S_AXIS_TDATA => tdata,
        S_AXIS_TVALID => tvalid
    );
    
    clk_proc : process
    begin
        clk <= '1';
        wait for clk_period/2;
        clk <= '0';
        wait for clk_period/2;
    end process clk_proc;
        
    rst_proc : process(clk)
       constant rst_cnt : integer := 200000;
       variable cnt : integer range 0 to rst_cnt := rst_cnt;
    begin
       if(rising_edge(clk)) then
           if (cnt = rst_cnt) then
               aresetn <= '0';
               cnt := 0;
           else
               aresetn <= '1';
               cnt := cnt + 1;
           end if;
       end if;
   end process rst_proc;
   
   axis_sim : process(clk, aresetn)
        variable cnt : integer := 0;
        type states is (ST_IDLE, ST_ACTIV);
        variable fsm : states := ST_IDLE;
   begin
   if(aresetn = '0') then
        cnt := 0;
        fsm := ST_IDLE;
        tdata <= (others => '0');
        tvalid <= '0';
   elsif(rising_edge(clk)) then
   case(fsm) is
        when ST_IDLE =>
            tvalid <= '1';
            tdata  <= std_logic_vector(to_unsigned(cnt, tdata'length));
            fsm := ST_ACTIV;
        
        when ST_ACTIV =>
            if(tready = '1') then
                tvalid <= '0';
                tdata <= (others => '0');
                fsm := ST_IDLE;
                cnt := cnt + 1;
            end if;
        
        when others =>
            fsm := ST_IDLE;
   
   end case;
   end if;
   end process axis_sim;


end Behavioral;
