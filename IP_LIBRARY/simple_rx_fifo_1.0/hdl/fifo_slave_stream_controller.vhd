library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.generic_pkg.all;

entity FIFO_SLAVE_STREAM_CONTROLLER is
	generic (
        BRAM_ADDR_WIDTH  : integer := 10;
        BRAM_DATA_WIDTH  : integer := 32
		);
	port (
        -- BRAM write port lines
        addra : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
        dina  : out STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
        ena   : out STD_LOGIC;
        wea   : out STD_LOGIC;
        clka  : out std_logic;
        rsta  : out std_logic;
        
        -- BRAM read port lines
        addrb : out STD_LOGIC_VECTOR (BRAM_ADDR_WIDTH-1 downto 0);
        doutb : in STD_LOGIC_VECTOR (BRAM_DATA_WIDTH-1 downto 0);
        enb   : out STD_LOGIC;
        clkb  : out std_logic;
        rstb  : out std_logic;
        
        --AXIL Read Control Ports
        axil_dvalid    : out std_logic; -- assert to axi4-lite interface data is ready
        axil_read_done : in std_logic;  -- acknowledgment from axi4-lite iface data has been read
        
        -- AXIS Slave Stream Ports
        S_AXIS_TREADY   : out std_logic;
        S_AXIS_TDATA    : in std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        S_AXIS_TVALID   : in std_logic;

        -- fifo control lines
        clk            : in std_logic;
        clkEn          : in std_logic;
        reset          : in std_logic;
        fifo_full      : out std_logic;
        fifo_empty     : out std_logic;
        fifo_occupancy : out std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        fifo_read_en   : in  std_logic;
        fifo_dout      : out std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);
        irq_set_value  : in std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0);
        irq_out_pulse  : out std_logic;
        irq_en         : in std_logic
		);
end FIFO_SLAVE_STREAM_CONTROLLER;

architecture Behavorial of FIFO_SLAVE_STREAM_CONTROLLER is
    
    -- fifo signals
    signal sig_fifo_empty     : std_logic := '0';
    signal sig_fifo_full      : std_logic := '0';
    signal sig_fifo_occupancy : std_logic_vector(BRAM_ADDR_WIDTH-1 downto 0) := (others => '0');
    signal WriteEn :   STD_LOGIC;
    signal DataIn  :   STD_LOGIC_VECTOR (BRAM_DATA_WIDTH - 1 downto 0);
    signal s_irq_pulse : std_logic := '0';
    signal s_read_en, s_dvalid : std_logic := '0';
    signal s_dout : std_logic_vector(BRAM_DATA_WIDTH-1 downto 0);

begin

    fifo_full      <= sig_fifo_full;
    fifo_empty     <= sig_fifo_empty;
    fifo_occupancy <= sig_fifo_occupancy;
    irq_out_pulse <= '0' when irq_en = '0' else s_irq_pulse;

	-- Instantiation of FIFO Controller
  bram_fifo_controller_v2_inst : bram_fifo_controller_v2
      generic map( 
          BRAM_ADDR_WIDTH => BRAM_ADDR_WIDTH,
          BRAM_DATA_WIDTH => BRAM_DATA_WIDTH)
      port map (
          addra => addra,
          dina  => dina,
          ena   => ena,
          wea   => wea,
          rsta  => rsta,
          addrb => addrb,
          doutb => doutb,
          enb   => enb,
          rstb  => rstb,
          
          clk        => clk,
          reset      => reset,
          WriteEn    => WriteEn,
          DataIn     => DataIn,
          ReadEn     => s_read_en,
          DataOut    => s_dout,
          DataOutValid => s_dvalid,
          Empty      => sig_fifo_empty,
          Full       => sig_fifo_full,
          ProgFullEn => irq_en,
          SetProgFull => irq_set_value,
          ProgFullPulse => s_irq_pulse,
          Occupancy => sig_fifo_occupancy
      );

    read_controller : process(clk,reset)
        type state is (ST_IDLE, ST_NEW_READ, ST_READ_CLEAR);
        variable fsm : state := ST_IDLE;
    begin
    if(reset = '1') then
      fsm := ST_IDLE;
      s_read_en <= '0';
      axil_dvalid <= '0';
    elsif(rising_edge(clk)) then
    case (fsm) is

      when ST_IDLE =>
        if(fifo_read_en = '1' and sig_fifo_empty = '0') then
          s_read_en <= '1';
          fsm := ST_NEW_READ;
        end if;

      when ST_NEW_READ =>
        s_read_en <= '0';
        if(s_dvalid = '1') then
          axil_dvalid <= '1';
          fifo_dout <= s_dout; 
          fsm := ST_READ_CLEAR;
        end if;

      when ST_READ_CLEAR =>
        if(axil_read_done = '1') then
          axil_dvalid <= '0';
          fifo_dout <= (others => '1');
          fsm := ST_IDLE;
        end if;

      when others =>
        fsm := ST_IDLE;
        axil_dvalid <= '0';
        s_read_en   <= '0';

    end case;
    end if;
    end process read_controller;
	    
    --------------------------------------------------------------------
    -- Stream and FIFO write controller (Async. Reset)
    --------------------------------------------------------------------
    -- Waits for the AXI-Stream module to be ready and for the FIFO
    -- to be ready to accept new data. Will then enable the AXI-Stream
    -- and wait for the valid data to be returned. The data will then be
    -- written to the FIFO
    --------------------------------------------------------------------
    fifo_write : process(clk, reset)
        type state is (ST_IDLE, ST_SYNC);
        variable fsm : state := ST_IDLE;
    begin
    if(reset = '1') then
        fsm           := ST_IDLE;
        S_AXIS_TREADY <= '0';
        WriteEn       <= '0';
    elsif(rising_edge(clk)) then
        if(clkEn = '1') then
            case(fsm) is

            when ST_IDLE =>
                if(S_AXIS_TVALID = '1' and sig_fifo_full = '0') then
                    DataIn  <= S_AXIS_TDATA;
                    WriteEn <= '1';
                    S_AXIS_TREADY <= '1';
                    fsm           := ST_SYNC;
                end if;
            
            when ST_SYNC =>
                WriteEn       <= '0';
                S_AXIS_TREADY <= '0';
                fsm           := ST_IDLE;
            
            when others =>
                fsm := ST_IDLE;
            end case;
        end if;
    end if;
    end process fifo_write;

end Behavorial;