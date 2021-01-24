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

--IP: DSP_Block
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
--Finished on: 02.21.2020
--Notes: the DSP attribute is required to make use of the DSP slices efficiently
--Possible Imporvements: OPmode, alumode cattinmode Inputs, opmode values
--------------------------------------------------------------------
--================= https://github.com/DHMarinov =================--
--------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity DSP_Block is
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
end DSP_Block;

architecture Behavioral of DSP_Block is

attribute use_dsp : string;
attribute use_dsp of Behavioral : architecture is "yes";

--attribute USE_PATTERN_DETECT : string;
--attribute USE_PATTERN_DETECT of Behavioral : architecture is "PATDET";

constant ALUMODE : std_logic_vector(3 downto 0) := "0000";  -- Controls the adder functionality
constant CARRYINSEL : std_logic_vector(2 downto 0) := (others => '0');
constant INMODE : std_logic_vector(4 downto 0) := "00100";
-- INMODE[0] - CEA1/CEA2 
-- INMODE[1] - DREG Pre-adder Disable
-- INMODE[2] - DREG Pre-adder Enable
-- INMODE[3] - DREG +/-, 0/1
-- INMODE[4] - CEB1/CEB2

function OPMODE_SEL_FUNC(use_pcin:boolean) 
    return std_logic_vector is
begin
    if use_pcin = true then
        return "0010101";    
    else
        return "0110101";
    end if;
end function;

constant OPMODE : std_logic_vector(6 downto 0) := OPMODE_SEL_FUNC(USE_PCIN) ; -- 0110101 CREG, 0010101 PCIN
constant CARRYIN : std_logic := '0';
constant enable : std_logic := '1';
constant pattern : std_logic_vector(47 downto 0) := (others=> '0');
constant mask : std_logic_vector(47 downto 0) := ("001111111111111111111111111111111111111111111111");

function PORT_MUX_FUNC(use_cin:boolean) 
    return string is
begin
    if use_cin = true then
        return "CASCADE";    
    else
        return "DIRECT";
    end if;
end function;

constant A_PORT_SELECT : string := port_mux_func(USE_ACIN);
constant B_PORT_SELECT : string := port_mux_func(USE_BCIN);

-- Native Data Width
constant AREG_WIDTH : integer := 30;
constant BREG_WIDTH : integer := 18;
constant CREG_WIDTH : integer := 48;
constant DREG_WIDTH : integer := 25;
constant PREG_WIDTH : integer := 48;

-- Internal signals
signal aport_s : std_logic_vector(AREG_WIDTH-1 downto 0) := (others=>'0');
signal bport_s : std_logic_vector(BREG_WIDTH-1 downto 0) := (others=>'0');
signal cport_s : std_logic_vector(CREG_WIDTH-1 downto 0) := (others=>'0');
signal dport_s : std_logic_vector(DREG_WIDTH-1 downto 0) := (others=>'0');
signal pport_s : std_logic_vector(PREG_WIDTH-1 downto 0) := (others=>'0');

signal aport : std_logic_vector(AREG_WIDTH-1 downto 0) := (others=>'0');
signal bport : std_logic_vector(BREG_WIDTH-1 downto 0) := (others=>'0');
signal cport : std_logic_vector(CREG_WIDTH-1 downto 0) := (others=>'0');
signal pport : std_logic_vector(PREG_WIDTH-1 downto 0) := (others=>'0');

signal acin : std_logic_vector(AREG_WIDTH-1 downto 0) := (others=>'0');
signal bcin : std_logic_vector(BREG_WIDTH-1 downto 0) := (others=>'0');
signal pcin : std_logic_vector(PREG_WIDTH-1 downto 0) := (others=>'0');

begin

----------------------------------------------------------------------------------------------------
-- I/O Management: Bit assignment
----------------------------------------------------------------------------------------------------
-- AREG
AREG_Gen: for i in 0 to AREG_WIDTH-1 generate         -- Assigns the Data bits
    AREG_Gen: if i < DATA_WIDTH_AREG generate
        aport_s(i) <= aport_i(i);         
    end generate;
    AREG_Gen_Fill: if i > DATA_WIDTH_AREG-1 generate    -- Assigns the MSB (sign)
        aport_s(i) <= aport_i(DATA_WIDTH_AREG-1);         
    end generate;
end generate;

-- BREG
BREG_Gen: for i in 0 to BREG_WIDTH-1 generate
    BREG_Gen: if i < DATA_WIDTH_BREG generate
        bport_s(i) <= bport_i(i);         
    end generate;
    BREG_Gen_Fill: if i > DATA_WIDTH_BREG-1 generate
        bport_s(i) <= bport_i(DATA_WIDTH_BREG-1);         
    end generate;
end generate;

-- CREG
CREG_Gen: for i in 0 to CREG_WIDTH-1 generate
    CREG_Gen: if i < DATA_WIDTH_CREG generate
        cport_s(i) <= cport_i(i);         
    end generate;
    CREG_Gen_Fill: if i > DATA_WIDTH_CREG-1 generate
        cport_s(i) <= cport_i(DATA_WIDTH_CREG-1);         
    end generate;
end generate;

-- DREG
DREG_Gen: for i in 0 to DREG_WIDTH-1 generate
    DREG_Gen: if i < DATA_WIDTH_DREG generate
        dport_s(i) <= dport_i(i);         
    end generate;
    DREG_Gen_Fill: if i > DATA_WIDTH_DREG-1 generate
        dport_s(i) <= dport_i(DATA_WIDTH_DREG-1);         
    end generate;
end generate;

-- PREG
PREG_Gen: for i in 0 to PREG_WIDTH-1 generate
    PREG_Gen: if i < DATA_WIDTH_PREG generate
        pport_o(i) <= pport_s(i);         
    end generate;
--    PREG_Gen_Fill: if i > DATA_WIDTH_PREG-1 generate
--        preg_o(i) <= preg_s(DATA_WIDTH_PREG-1);         
--    end generate;
end generate;


----------------------------------------------------------------------------------------------------
-- I/O Management: Port multiplexing - Ports vs cascaded ports
----------------------------------------------------------------------------------------------------
-- Aport/ACIN
AMUX_gen_true: if USE_ACIN = true generate
    begin
        aport <= (others=>'0');
        acin <= aport_s;
end generate;
AMUX_gen_false: if USE_ACIN = false generate
    begin
        aport <= aport_s;
        acin <= (others=>'0');
end generate;

-- Bport/BCIN
BMUX_gen_true: if USE_BCIN = true generate
    begin
    bport <= (others=>'0');
    bcin <= bport_s;
end generate;
BMUX_gen_false: if USE_BCIN = false generate
    begin
    bport <= bport_s;
    bcin <= (others=>'0');
end generate;

-- Cport/PCIN
PMUX_gen_true: if USE_PCIN = true generate
    begin
    cport <= (others=>'0');
    pcin <= cport_s;
end generate;
PMUX_gen_false: if USE_PCIN = false generate
    begin
    cport <= cport_s;
    pcin <= (others=>'0');
end generate;

----------------------------------------------------------------------------------------------------
-- DSP Block Definition and Mapping
----------------------------------------------------------------------------------------------------
   DSP48E1_inst : DSP48E1
   generic map (
      -- Feature Control Attributes: Data Path Selection
      A_INPUT   => A_PORT_SELECT,               -- Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
      B_INPUT   => B_PORT_SELECT,               -- Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
      USE_DPORT => USE_DPORT,                   -- Select D port usage (TRUE or FALSE)
      USE_MULT  => "MULTIPLY",                  -- Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
      USE_SIMD  => "ONE48",                     -- SIMD selection ("ONE48", "TWO24", "FOUR12")
      
      -- Pattern Detector Attributes: Pattern Detection Configuration
      AUTORESET_PATDET   => "NO_RESET",         -- "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
      MASK               => X"01ffffffffff",    -- 48-bit mask value for pattern detect (1=ignore)
      PATTERN            => X"000000000000",    -- 48-bit pattern match for pattern detect
      SEL_MASK           => "C",                -- "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2", used for the pattern detector
      SEL_PATTERN        => "C",                -- Select pattern value ("PATTERN" or "C")
      USE_PATTERN_DETECT => "NO_PATDET",        -- Enable pattern detect ("PATDET" or "NO_PATDET")
      
      -- Register Control Attributes: Pipeline Register Configuration
      ACASCREG      => ACASCREG,                -- Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
      ADREG         => ADREG,                   -- Number of pipeline stages for pre-adder (0 or 1)
      ALUMODEREG    => ALUMODEREG,              -- Number of pipeline stages for ALUMODE (0 or 1)
      AREG          => AREG,                    -- Number of pipeline stages for A (0, 1 or 2)
      BCASCREG      => BCASCREG,                -- Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
      BREG          => BREG,                    -- Number of pipeline stages for B (0, 1 or 2)
      CARRYINREG    => CARRYINREG,              -- Number of pipeline stages for CARRYIN (0 or 1)
      CARRYINSELREG => CARRYINSELREG,           -- Number of pipeline stages for CARRYINSEL (0 or 1)
      CREG          => CREG,                    -- Number of pipeline stages for C (0 or 1)
      DREG          => DREG,                    -- Number of pipeline stages for D (0 or 1)
      INMODEREG     => INMODEREG,               -- Number of pipeline stages for INMODE (0 or 1)
      MREG          => MREG,                    -- Number of multiplier pipeline stages (0 or 1)
      OPMODEREG     => OPMODEREG,               -- Number of pipeline stages for OPMODE (0 or 1)
      PREG          => PREG                     -- Number of pipeline stages for P (0 or 1)
   )
   port map (
      -- Cascade: 30-bit (each) output: Cascade Ports
      ACOUT         => acout_o,                 -- 30-bit output: A port cascade output
      BCOUT         => bcout_o,                 -- 18-bit output: B port cascade output
      CARRYCASCOUT  => CARRYCASCOUT_o,          -- 1-bit output: Cascade carry output
      MULTSIGNOUT   => MULTSIGNOUT_o,           -- 1-bit output: Multiplier sign cascade output
      PCOUT         => PCOUT_o,                 -- 48-bit output: Cascade output
      
      -- Control: 1-bit (each) output: Control Inputs/Status Bits
      OVERFLOW       => open,                   -- 1-bit output: Overflow in add/acc output
      PATTERNBDETECT => open,                   -- 1-bit output: Pattern bar detect output
      PATTERNDETECT  => open,                   -- 1-bit output: Pattern detect output
      UNDERFLOW      => open,                   -- 1-bit output: Underflow in add/acc output
      
      -- Data: 4-bit (each) output: Data Ports
      CARRYOUT => open,                         -- 4-bit output: Carry output
      P        => pport_s,                      -- 48-bit output: Primary data output
      
      -- Cascade: 30-bit (each) input: Cascade Ports
      ACIN        => acin,                      -- 30-bit input: A cascade data input
      BCIN        => bcin,                      -- 18-bit input: B cascade input
      CARRYCASCIN => '0',                       -- 1-bit input: Cascade carry input
      MULTSIGNIN  => '0',                       -- 1-bit input: Multiplier sign input
      PCIN        => pcin,                      -- 48-bit input: P cascade input
      
      -- Control: 4-bit (each) input: Control Inputs/Status Bits
      ALUMODE    => ALUMODE,                    -- 4-bit input: ALU control input
      CARRYINSEL => CARRYINSEL,                 -- 3-bit input: Carry select input
      CLK        => CLK,                        -- 1-bit input: Clock input
      INMODE     => INMODE,                     -- 5-bit input: INMODE control input
      OPMODE     => OPMODE,                     -- 7-bit input: Operation mode input
      
      -- Data: 30-bit (each) input: Data Ports
      A       => aport,                         -- 30-bit input: A data input
      B       => bport,                         -- 18-bit input: B data input
      C       => cport,                         -- 48-bit input: C data input
      CARRYIN => CARRYIN,                       -- 1-bit input: Carry input signal
      D       => dport_s,                       -- 25-bit input: D data input
      
      -- Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
      CEA1          => enable,                   -- 1-bit input: Clock enable input for 1st stage AREG
      CEA2          => '1',                      -- 1-bit input: Clock enable input for 2nd stage AREG
      CEAD          => enable,                   -- 1-bit input: Clock enable input for ADREG
      CEALUMODE     => enable,                   -- 1-bit input: Clock enable input for ALUMODE
      CEB1          => enable,                   -- 1-bit input: Clock enable input for 1st stage BREG
      CEB2          => '1',                      -- 1-bit input: Clock enable input for 2nd stage BREG
      CEC           => enable,                   -- 1-bit input: Clock enable input for CREG
      CECARRYIN     => enable,                   -- 1-bit input: Clock enable input for CARRYINREG
      CECTRL        => enable,                   -- 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
      CED           => enable,                   -- 1-bit input: Clock enable input for DREG
      CEINMODE      => enable,                   -- 1-bit input: Clock enable input for INMODEREG
      CEM           => enable,                   -- 1-bit input: Clock enable input for MREG
      CEP           => '1',                      -- 1-bit input: Clock enable input for PREG
      RSTA          => reset,                    -- 1-bit input: Reset input for AREG
      RSTALLCARRYIN => reset,                    -- 1-bit input: Reset input for CARRYINREG
      RSTALUMODE    => reset,                    -- 1-bit input: Reset input for ALUMODEREG
      RSTB          => reset,                    -- 1-bit input: Reset input for BREG
      RSTC          => reset,                    -- 1-bit input: Reset input for CREG
      RSTCTRL       => reset,                    -- 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
      RSTD          => reset,                    -- 1-bit input: Reset input for DREG and ADREG
      RSTINMODE     => reset,                    -- 1-bit input: Reset input for INMODEREG
      RSTM          => reset,                    -- 1-bit input: Reset input for MREG
      RSTP          => reset                     -- 1-bit input: Reset input for PREG
   );


end Behavioral;
