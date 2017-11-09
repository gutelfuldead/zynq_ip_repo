library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity axis_to_spi_v1_0 is
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
end axis_to_spi_v1_0;

architecture arch_imp of axis_to_spi_v1_0 is

   -- spi control signals
   signal spi_din    : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
   signal spi_rdy    : std_logic := '0';
   signal spi_dvalid : std_logic := '0'; 
   signal reset      : std_logic := '0';
   
   -- axis control signals
   signal user_rdy    : std_logic := '0';
   signal user_dvalid : std_logic := '0';
   signal user_data   : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
   signal axis_rdy    : std_logic := '0';
   
   -- iface control signals
   signal new_word : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
   signal new_word_rdy, new_word_accessed : std_logic := '0';

begin

    reset <= not S_AXIS_ARESETN;

    spi_master_inst : spi_master
    generic map (
        INPUT_CLK_MHZ => INPUT_CLK_MHZ,
        SPI_CLK_MHZ   => SPI_CLK_MHZ,
        DSIZE         => DATA_WIDTH
    )
    Port map(
           clk     => S_AXIS_ACLK,
           reset   => reset,
           sclk    => sclk,
           sclk_en => sclk_en,
           mosi    => mosi,
           din     => spi_din,
           rdy     => spi_rdy,
           dvalid  => spi_dvalid 
           );
           
   axi_slave_stream_inst : axi_slave_stream
   generic map( C_S_AXIS_TDATA_WIDTH => DATA_WIDTH)
   port map(
       user_rdy    => user_rdy,
       user_dvalid => user_dvalid, 
       user_data   => user_data,
       axis_rdy    => axis_rdy,
       axis_last   => open,
       S_AXIS_ACLK    => S_AXIS_ACLK,
       S_AXIS_ARESETN => S_AXIS_ARESETN,
       S_AXIS_TREADY  => S_AXIS_TREADY,
       S_AXIS_TDATA   => S_AXIS_TDATA,
       S_AXIS_TSTRB   => (others => '1'),
       S_AXIS_TLAST   => '0',
       S_AXIS_TVALID  => S_AXIS_TVALID
   );
   
   -- axi slave controller
   axis_ctrl : process(S_AXIS_ACLK,reset)
       type states is (ST_IDLE, ST_WAIT, ST_SYNC);
       variable fsm : states := ST_IDLE;
   begin
   if(reset = '1') then
       user_rdy <= '0';
       new_word <= (others => '0');
       new_word_rdy <= '0';
       fsm := ST_IDLE;
   elsif(rising_edge(S_AXIS_ACLK)) then
   case(fsm) is
       when ST_IDLE =>
            if(axis_rdy = '1') then
                user_rdy <= '1';
                fsm := ST_WAIT;
            end if;
       
       when ST_WAIT =>
            user_rdy <= '0';
            if(user_dvalid = '1') then
                new_word <= user_data;
                new_word_rdy <= '1';
                fsm := ST_SYNC;
            end if;
       
       when ST_SYNC =>
            if(new_word_accessed = '1') then
                new_word_rdy <= '0';
                fsm := ST_IDLE;
            end if;
       
       when others =>
            fsm := ST_IDLE;
   end case;
   end if;
   end process axis_ctrl;

   -- spi controller
   spi_ctrl : process(S_AXIS_ACLK,reset)
        type states is (ST_IDLE, ST_ACTIVE);
        variable fsm : states := ST_IDLE;
   begin
   if(reset = '1') then
        new_word_accessed <= '0';
        spi_dvalid <= '0';
        spi_din <= (others => '0');
        fsm := ST_IDLE;
   elsif(rising_edge(S_AXIS_ACLK)) then
   case(fsm) is
   
        when ST_IDLE =>
            spi_dvalid <= '0';
            if(new_word_rdy = '1') then
                spi_din <= new_word;
                new_word_accessed <= '1';
                fsm := ST_ACTIVE;
            end if;
            
        when ST_ACTIVE =>
            new_word_accessed <= '0';
            if(spi_rdy = '1') then
                spi_dvalid <= '1';
                fsm := ST_IDLE;
            end if;
        
        when others =>
            fsm := ST_IDLE;
            
   end case;
   end if;
   end process spi_ctrl;


end arch_imp;
