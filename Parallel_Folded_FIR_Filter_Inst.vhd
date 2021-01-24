--| |-----------------------------------------------------------| |
--| |-----------------------------------------------------------| |
--| |       _______           __      __      __          __    | |
--| |     /|   __  \        /|  |   /|  |   /|  \        /  |   | |
--| |    / |  |  \  \      / |  |  / |  |  / |   \      /   |   | |
--| |   |  |  |\  \  \    |  |  | |  |  | |  |    \    /    |   | |
--| |   |  |  | \  \  \   |  |  | |  |  | |  |     \  /     |   | |
--| |   |  |  |  \  \  \  |  |  |_|__|  | |  |      \/      |   | |
--| |   |  |  |   \  \  \ |  |          | |  |  |\      /|  |   | |
--| |   |  |  |   /  /  / |  |   ____   | |  |  | \    / |  |   | |
--| |   |  |  |  /  /  /  |  |  |__/ |  | |  |  |\ \  /| |  |   | |
--| |   |  |  | /  /  /   |  |  | |  |  | |  |  | \ \//| |  |   | |
--| |   |  |  |/  /  /    |  |  | |  |  | |  |  |  \|/ | |  |   | |
--| |   |  |  |__/  /     |  |  | |  |  | |  |  |      | |  |   | |
--| |   |  |_______/      |  |__| |  |__| |  |__|      | |__|   | |
--| |   |_/_______/	      |_/__/  |_/__/  |_/__/       |_/__/   | |
--| |                                                           | |
--| |-----------------------------------------------------------| |
--| |=============-Developed by Dimitar H.Marinov-==============| |
--|_|-----------------------------------------------------------|_|

--IP: Parallel FIR Filter
--Version: V1 - Standalone 
--Fuctionality: Generic FIR filter
--IO Description
--  clk     : system clock = sampling clock
--  reset   : resets the M registes (buffers) and the P registers (delay line) of the DSP48 blocks 
--  enable  : acts as bypass switch - bypass(0), active(1) 
--  data_i  : data input (signed)
--  data_o  : data output (signed)
--
--Generics Description
--  FILTER_TAPS  : Specifies the amount of filter taps (multiplications)
--  INPUT_WIDTH  : Specifies the input width (8-25 bits)
--  COEFF_WIDTH  : Specifies the coefficient width (8-18 bits)
--  OUTPUT_WIDTH : Specifies the output width (8-43 bits)
--
--Finished on: 30.06.2019
--Notes: the DSP attribute is required to make use of the DSP slices efficiently
-- Putting FILTER_TAPS/2 in the filter coeff array generates errors.
-- Uses only half of the coefficients normally generated by the filter coefficient tools.
--------------------------------------------------------------------
--================= https://github.com/DHMarinov =================--
--------------------------------------------------------------------



library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

Library UNISIM;
use UNISIM.vcomponents.all;

entity Parallel_Folded_FIR_Filter_Inst is
    Generic (
        FILTER_TAPS  : integer := 59;
        INPUT_WIDTH  : integer range 8 to 25 := 24; 
        COEFF_WIDTH  : integer range 8 to 18 := 16;
        OUTPUT_WIDTH : integer range 8 to 42 := 24    -- This should be < (Input+Coeff width-1) 
    );
    Port ( 
           clk    : in STD_LOGIC;
           reset  : in STD_LOGIC;
           enable : in STD_LOGIC;
           data_i : in STD_LOGIC_VECTOR (INPUT_WIDTH-1 downto 0);
           data_o : out STD_LOGIC_VECTOR (OUTPUT_WIDTH-1 downto 0)
           );
end Parallel_Folded_FIR_Filter_Inst;

architecture Behavioral of Parallel_Folded_FIR_Filter_Inst is

component DSP_Block is
    Generic(
    -- Data width
    DATA_WIDTH_AREG : integer range 1 to 30 := 30;
    DATA_WIDTH_BREG : integer range 1 to 18 := 18;
    DATA_WIDTH_CREG : integer range 1 to 48 := 48;
    DATA_WIDTH_DREG : integer range 1 to 25 := 25;
    DATA_WIDTH_PREG : integer range 1 to 48 := 48;
    
    -- Port Multiplexing
    USE_ACIN  : boolean := false;
    USE_BCIN  : boolean := false;
    USE_PCIN  : boolean := false;
    USE_DPORT : boolean := true;
    
    -- Register Control Attributes: Pipeline Register Configuration
    ACASCREG      : integer range 0 to 2 := 0;    -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2), must equal or 1 less than AREG
    ADREG         : integer range 0 to 1 := 0;    -- Number of pipeline stages for pre-adder (0 or 1)
    ALUMODEREG    : integer range 0 to 1 := 0;    -- Number of pipeline stages for ALUMODE (0 or 1)
    AREG          : integer range 0 to 2 := 0;    -- Number of pipeline stages for A (0, 1 or 2)
    BCASCREG      : integer range 0 to 2 := 0;    -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
    BREG          : integer range 0 to 2 := 0;    -- Number of pipeline stages for B (0, 1 or 2), must equal or 1 less than AREG
    CARRYINREG    : integer range 0 to 1 := 0;    -- Number of pipeline stages for CARRYIN (0 or 1)
    CARRYINSELREG : integer range 0 to 1 := 0;    -- Number of pipeline stages for CARRYINSEL (0 or 1)
    CREG          : integer range 0 to 1 := 0;    -- Number of pipeline stages for C (0 or 1)
    DREG          : integer range 0 to 1 := 0;    -- Number of pipeline stages for D (0 or 1)
    INMODEREG     : integer range 0 to 1 := 0;    -- Number of pipeline stages for INMODE (0 or 1)
    MREG          : integer range 0 to 1 := 0;    -- Number of multiplier pipeline stages (0 or 1)
    OPMODEREG     : integer range 0 to 1 := 0;    -- Number of pipeline stages for OPMODE (0 or 1)
    PREG          : integer range 0 to 1 := 0     -- Number of pipeline stages for P (0 or 1)
    
    );
    Port ( 
    clk : in STD_LOGIC;
    reset : in STD_LOGIC;
    
    -- I/O Ports
    aport_i : in STD_LOGIC_VECTOR (DATA_WIDTH_AREG-1 downto 0);
    bport_i : in STD_LOGIC_VECTOR (DATA_WIDTH_BREG-1 downto 0);
    cport_i : in STD_LOGIC_VECTOR (DATA_WIDTH_CREG-1 downto 0);
    dport_i : in STD_LOGIC_VECTOR (DATA_WIDTH_DREG-1 downto 0);
    pport_o : out STD_LOGIC_VECTOR (DATA_WIDTH_PREG-1 downto 0);
    
    -- Cascade Ports
    carrycascout_i : in STD_LOGIC;
    multsignout_i  : in STD_LOGIC;
    carrycascout_o : out STD_LOGIC;
    multsignout_o  : out STD_LOGIC;
    acout_o : out STD_LOGIC_VECTOR (29 downto 0);
    bcout_o : out STD_LOGIC_VECTOR (17 downto 0);
    pcout_o : out STD_LOGIC_VECTOR (47 downto 0)
        );
end component;

-- Native Data Width
constant AREG_WIDTH : integer := 30;
constant BREG_WIDTH : integer := 18;
constant CREG_WIDTH : integer := 48;
constant DREG_WIDTH : integer := 25;
constant PREG_WIDTH : integer := 48;

-- Registers
constant ACASCREG : integer := 2;  
constant ADREG : integer := 1;        
constant ALUMODEREG : integer := 0;    
constant AREG : integer := 2;         
constant BCASCREG : integer := 0;   
constant BREG : integer := 0;         
constant CARRYINREG : integer := 0;    
constant CARRYINSELREG : integer := 0;
constant CREG : integer := 0;         
constant DREG : integer := 1;        
constant INMODEREG : integer := 0;    
constant MREG : integer := 1;        
constant OPMODEREG : integer := 0;    
constant PREG : integer := 1; 

type delay_line is array(0 to FILTER_TAPS-1) of std_logic_vector(INPUT_WIDTH-1 downto 0);
signal srl_s  : delay_line := (others=>(others=>'0'));

attribute shreg_extract : string;
attribute shreg_extract of srl_s : signal is "srl";

type input_signals is array(0 to FILTER_TAPS/2) of std_logic_vector(AREG_WIDTH-1 downto 0);
signal aport_s  : input_signals := (others=>(others=>'0'));

type coeff_registers is array(0 to FILTER_TAPS/2) of std_logic_vector(BREG_WIDTH-1 downto 0);
signal bport_s : coeff_registers := (others=>(others=>'0'));

type product_signals is array(0 to FILTER_TAPS/2) of std_logic_vector(PREG_WIDTH-1 downto 0);
signal cport_s : product_signals := (others=>(others=>'0'));
signal pport_s : product_signals := (others=>(others=>'0'));

signal dport_s : std_logic_vector(INPUT_WIDTH-1 downto 0) := (others=>'0');
signal data_in_s : std_logic_vector(AREG_WIDTH-1 downto 0) := (others=>'0');

signal carrycascout_s : std_logic_vector(FILTER_TAPS/2-1 downto 0) := (others=>'0');
signal multsignout_s : std_logic_vector(FILTER_TAPS/2-1 downto 0) := (others=>'0');

--type coefficients is array (0 to FILTER_TAPS/2) of std_logic_vector(COEFF_WIDTH-1 downto 0);
--signal coeff_s: coefficients :=( 
---- Blackman 500Hz LPF
--x"0005", x"0001", x"0005", x"000C", 
--x"0016", x"0025", x"0037", x"004E" 
--); --x"0069"

-- Chebyshev 1kH LPF, causes overflow at low freq. 
type coefficients is array (0 to 29) of std_logic_vector( 15 downto 0);
signal coeff_s: coefficients :=(
x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFF", x"FFFE", 
x"FFFE", x"FFFF", x"0001", x"0007", x"0011", x"0022", 
x"003B", x"005E", x"008E", x"00CD", x"011C", x"017C", 
x"01ED", x"026F", x"02FF", x"0399", x"0439", x"04D9", 
x"0573", x"0601", x"067B", x"06DD", x"0721", x"0744");

---- 500Hz Blackman LPF
--x"0000", x"0001", x"0005", x"000C", x"0016", x"0025",
--x"0037", x"004E", x"0069", x"008B", x"00B2", x"00E0", 
--x"0114", x"014E", x"018E", x"01D3", x"021D", x"026A",
--x"02BA", x"030B", x"035B", x"03AA", x"03F5", x"043B", 
--x"047B", x"04B2", x"04E0", x"0504", x"051C", x"0528";


begin  

FILTER_LOOP_gen: for i in 0 to FILTER_TAPS/2 generate
    Input_gen: if i = 0 generate  
        DSP_Inst: DSP_Block
        Generic map(
        -- Data width
        DATA_WIDTH_AREG => INPUT_WIDTH, 
        DATA_WIDTH_BREG => COEFF_WIDTH, 
        DATA_WIDTH_CREG => CREG_WIDTH,
        DATA_WIDTH_DREG => INPUT_WIDTH,
        DATA_WIDTH_PREG => PREG_WIDTH,
        
        -- Port Multiplexing
        USE_ACIN => false, 
        USE_BCIN => false, 
        USE_PCIN => false, 
        USE_DPORT => true,
        
        -- Register Control Attributes: Pipeline Register Configuration
        ACASCREG => ACASCREG,   
        ADREG => ADREG,        
        ALUMODEREG => ALUMODEREG,    
        AREG => AREG,         
        BCASCREG => BCASCREG,   
        BREG => BREG,         
        CARRYINREG => CARRYINREG,    
        CARRYINSELREG => CARRYINSELREG,
        CREG => CREG,         
        DREG => DREG,         
        INMODEREG => INMODEREG,    
        MREG => MREG,        
        OPMODEREG => OPMODEREG,    
        PREG => PREG        
        ) 
        Port map( 
        clk => clk,
        reset => '0', 
        
        -- I/O Ports
        aport_i => data_i,
        bport_i => coeff_s(i),
        cport_i => (others=>'0'),
        dport_i => srl_s(FILTER_TAPS-1),
        pport_o => open,
        
        -- Cascade Ports
        carrycascout_i => '0', 
        multsignout_i => '0',
        carrycascout_o => carrycascout_s(i),
        multsignout_o => multsignout_s(i), 
        acout_o => aport_s(i),
        bcout_o => open,
        pcout_o => pport_s(i)
        );
    end generate;

    Body_gen: if i > 0 and i < FILTER_TAPS/2 generate
        DSP_Inst: DSP_Block
        Generic map(
        -- Data width
        DATA_WIDTH_AREG => AREG_WIDTH, 
        DATA_WIDTH_BREG => COEFF_WIDTH, 
        DATA_WIDTH_CREG => CREG_WIDTH,
        DATA_WIDTH_DREG => INPUT_WIDTH,
        DATA_WIDTH_PREG => PREG_WIDTH,
        
        -- Port Multiplexing
        USE_ACIN => true, 
        USE_BCIN => false, 
        USE_PCIN => true, 
        USE_DPORT => true,
        
        -- Register Control Attributes: Pipeline Register Configuration
        ACASCREG => ACASCREG,   
        ADREG => ADREG,        
        ALUMODEREG => ALUMODEREG,    
        AREG => AREG,         
        BCASCREG => BCASCREG,   
        BREG => BREG,         
        CARRYINREG => CARRYINREG,    
        CARRYINSELREG => CARRYINSELREG,
        CREG => CREG,         
        DREG => DREG,         
        INMODEREG => INMODEREG,    
        MREG => MREG,        
        OPMODEREG => OPMODEREG,    
        PREG => PREG      
        ) 
        Port map( 
        clk => clk,
        reset => '0', 
        
        -- I/O Ports
        aport_i => aport_s(i-1),
        bport_i => coeff_s(i),
        cport_i => pport_s(i-1),
        dport_i => srl_s(FILTER_TAPS-1),
        pport_o => open,
        
        -- Cascade Ports
        carrycascout_i => carrycascout_s(i-1), 
        multsignout_i => multsignout_s(i-1),
        carrycascout_o => carrycascout_s(i),
        multsignout_o => multsignout_s(i), 
        acout_o => aport_s(i),
        bcout_o => open,
        pcout_o => pport_s(i)
        );
    end generate;

    Output_gen: if i = FILTER_TAPS/2 generate
        DSP_Inst: DSP_Block
        Generic map(
        -- Data width
        DATA_WIDTH_AREG => AREG_WIDTH, 
        DATA_WIDTH_BREG => COEFF_WIDTH, 
        DATA_WIDTH_CREG => CREG_WIDTH,
        DATA_WIDTH_DREG => INPUT_WIDTH,
        DATA_WIDTH_PREG => PREG_WIDTH,
        
        -- Port Multiplexing
        USE_ACIN => true, 
        USE_BCIN => false, 
        USE_PCIN => true, 
        USE_DPORT => true,
        
        -- Register Control Attributes: Pipeline Register Configuration
        ACASCREG => ACASCREG,   
        ADREG => ADREG,        
        ALUMODEREG => ALUMODEREG,    
        AREG => AREG,         
        BCASCREG => BCASCREG,   
        BREG => BREG,         
        CARRYINREG => CARRYINREG,    
        CARRYINSELREG => CARRYINSELREG,
        CREG => CREG,         
        DREG => DREG,         
        INMODEREG => INMODEREG,    
        MREG => MREG,        
        OPMODEREG => OPMODEREG,    
        PREG => PREG        
        ) 
        Port map( 
        clk => clk,
        reset => '0', 
        
        -- I/O Ports
        aport_i => aport_s(i-1),
        bport_i => coeff_s(i),
        cport_i => pport_s(i-1),
        dport_i => (others=>'0'),
        pport_o => pport_s(i),
        
        -- Cascade Ports
        carrycascout_i => carrycascout_s(i-1), 
        multsignout_i => multsignout_s(i-1),
        carrycascout_o => open,
        multsignout_o => open, 
        acout_o => open,
        bcout_o => open,
        pcout_o => open
        ); 
    end generate;
end generate;

data_o <= std_logic_vector(pport_s(FILTER_TAPS/2)(INPUT_WIDTH + COEFF_WIDTH - 2 downto INPUT_WIDTH + COEFF_WIDTH - OUTPUT_WIDTH - 1));   

process(clk)
begin

    --Checks whether the FILTER_TAPS generic is even
    if (FILTER_TAPS mod 2) = 0 then
        assert (false) report "The FILTER_TAPS generic is even. Only odd values are accepted!"  severity failure;
    end if;

    if rising_edge(clk) then
        for i in 0 to FILTER_TAPS-1 loop
            if i = 0 then
                srl_s(i) <= data_i;
            elsif i > 0 then
                srl_s(i) <= srl_s(i-1);
            end if;     
        end loop;
    end if;

end process;         

end Behavioral;