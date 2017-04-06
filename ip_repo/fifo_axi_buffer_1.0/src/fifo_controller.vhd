library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity fifo_controller is
  Port (
    -- FIFO_WRITE signals
    wr_full        : in  std_logic;
    wr_din         : out std_logic_vector(15 downto 0);
    wr_en          : out std_logic;
    
    -- FIFO_READ signals
    rd_en          : out std_logic;
    rd_empty       : in  std_logic;
    rd_valid       : in std_logic;
    rd_dout        : in std_logic_vector(15 downto 0);
    
    -- Control Signals
    clk            : in  std_logic;
    srst           : out std_logic;
    
    -- optional FIFO signals
    data_count     : in std_logic_vector(9 downto 0);
    
    -- Application Specific Control Signals
    app_reset      : in std_logic;
    app_dcount     : out std_logic_vector(9 downto 0);
    
    app_rd_en      : in std_logic;
    app_rd_valid   : out std_logic;
    app_rd_empty   : out std_logic;
    app_wr_en      : in std_logic;
    app_wr_full    : out std_logic;
    
    app_dout       : out std_logic_vector(15 downto 0);
    app_din        : in std_logic_vector(15 downto 0)  
   );
end fifo_controller;

architecture Behavioral of fifo_controller is

    signal s_srst      : std_logic := '0';

    -- read signals --
    signal s_rd_en : std_logic := '0';
    signal s_app_dout  : std_logic_vector(15 downto 0) := (others => '0');
    signal s_app_rd_valid : std_logic := '0';
    
    -- write signals --
    signal s_wr_din : std_logic_vector(15 downto 0) := (others => '0');
    signal s_wr_en : std_logic := '0';
    signal s_app_wr_full : std_logic := '0';
    

begin

    -- control signals --
    app_dcount  <= data_count;
    
    -- synchronous reset
    srst        <= s_srst;
    reset : process(clk)
    begin
        if(rising_edge(clk)) then
            if(app_reset = '1') then
                s_srst <= '1';
            else
                s_srst <= '0';
            end if;
        end if;
    end process reset;
        
    -- read from fifo
    rd_en        <= s_rd_en;
    app_dout     <= s_app_dout;
    app_rd_valid <= s_app_rd_valid;
    app_rd_empty <= rd_empty;
    read : process(clk)
    begin
        if(rising_edge(clk)) then
            if(app_reset = '0') then
                if(app_rd_en = '1') then
                    s_rd_en <= '1';
                    if(rd_valid = '1') then
                        s_app_dout <= rd_dout;
                        s_app_rd_valid <= '1';
                    else
                        s_app_rd_valid <= '0';           
                    end if;
                else
                    s_rd_en <= '0';
                end if;
            end if;
        end if;
    end process read;
    
    -- write to fifo
    wr_din      <= s_wr_din;
    wr_en       <= s_wr_en;
    app_wr_full <= s_app_wr_full;
    write : process(clk)
    begin
        if(rising_edge(clk)) then
            if(app_reset = '0') then
                if(app_wr_en = '1') then
                    s_wr_en <= '1';
                    if(wr_full = '0') then
                        s_app_wr_full <= '0';
                        s_wr_din <= app_din;
                    else
                        s_app_wr_full <= '1';
                    end if;
                else
                    s_wr_en <= '0';
                end if;
            end if;
        end if;
    end process write;
    
end Behavioral;
