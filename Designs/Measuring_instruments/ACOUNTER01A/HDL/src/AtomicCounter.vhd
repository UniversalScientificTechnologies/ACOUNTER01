----------------------------------------------------------------------------------
-- Company:        www.mlab.cz
-- Based on code written by MIHO.
-- 
-- HW Design Name: S3AN01A
-- Project Name:   Atomic Counter
-- Target Devices: XC3S50AN-4
-- Tool versions:  ISE 13.3
-- Description:   Counter up to 640 MHz synchonised by GPS.
--						Output frequency is displayed on the 7seg. LED display.
--						You can choice half or full frequency by DIPSW7.	
--
-- Dependencies:   TTLPECL01A, GPS01A
--
-- Version:  $Id: gtime.vhd 3177 2013-07-17 23:48:47Z kakl $
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;

library UNISIM;
use UNISIM.vcomponents.all;

entity AtomicCounter is
	generic (
		--	Top Value for 100MHz Clock Counter
		MAXCOUNT:	integer	:=	10_000;				-- Maximum for the first counter
		MUXCOUNT:	integer	:=	100_000				--	LED Display Multiplex Clock Divider
	);
	port (
		-- Clock on PCB
		CLK100MHz:	in		std_logic;

		-- Mode Signals (usualy not used)
		M:				in		std_logic_vector(2 downto 0);
		VS:			in		std_logic_vector(2 downto 0);

		-- Dipswitch Inputs
		DIPSW:		in		std_logic_vector(7 downto 0);

		-- Push Buttons
		PB:			in		std_logic_vector(3 downto 0);

		-- LED Bar Outputs
		LED:			out	std_logic_vector(7 downto 0);

		--	LED Display (8 digit with 7 segments and ddecimal point)
		LD_A_n:		out	std_logic;
		LD_B_n:		out	std_logic;
		LD_C_n:		out	std_logic;
		LD_D_n:		out	std_logic;
		LD_E_n:		out	std_logic;
		LD_F_n:		out	std_logic;
		LD_G_n:		out	std_logic;
		LD_DP_n:		out	std_logic;
		LD_0_n:		out	std_logic;
		LD_1_n:		out	std_logic;
		LD_2_n:		out	std_logic;
		LD_3_n:		out	std_logic;
		LD_4_n:		out	std_logic;
		LD_5_n:		out	std_logic;
		LD_6_n:		out	std_logic;
		LD_7_n:		out	std_logic;

		--	VGA Video Out Port
		VGA_R:		out	std_logic_vector(1 downto 0);
		VGA_G:		out	std_logic_vector(1 downto 0);
		VGA_B:		out	std_logic_vector(1 downto 0);
		VGA_VS:		out	std_logic;
		VGA_HS:		out	std_logic;

		-- Bank 1 Pins - Inputs for this Test
		B:				inout		std_logic_vector(24 downto 0);
		
		-- PS/2 Bidirectional Port (open collector, J31 and J32)
		PS2_CLK1:	inout	std_logic;
		PS2_DATA1:	inout	std_logic;
		PS2_CLK2:	inout	std_logic;
		PS2_DATA2:	inout	std_logic;

		--	Diferencial Signals on 4 pin header (J7)
		DIF1P:		inout	std_logic;
		DIF1N:		inout	std_logic;
		DIF2P:		inout	std_logic;
		DIF2N:		inout	std_logic;
		

		--	I2C Signals (on connector J30)
		I2C_SCL:		inout	std_logic;
		I2C_SDA:		inout	std_logic;

		--	Diferencial Signals on SATA like connectors (not SATA capable, J28 and J29)
		SD1AP:		inout	std_logic;
		SD1AN:		inout	std_logic;
		SD1BP:		inout	std_logic;
		SD1BN:		inout	std_logic;
		SD2AP:		inout	std_logic;
		SD2AN:		inout	std_logic;
		SD2BP:		inout	std_logic;
		SD2BN:		inout	std_logic;

		--	Analog In Out
	   ANA_OUTD:	out	std_logic;
		ANA_REFD:	out	std_logic;
		ANA_IND:		in		std_logic;

		--	SPI Memory Interface
		SPI_CS_n:	inout	std_logic;
		SPI_DO:		inout	std_logic;
		SPI_DI:		inout	std_logic;
		SPI_CLK:		inout	std_logic;
		SPI_WP_n:	inout	std_logic
	);
end entity AtomicCounter;


architecture AtomicCounter_a of AtomicCounter is

function to_bcd ( bin : std_logic_vector(31 downto 0) ) return std_logic_vector is
variable i : integer:=0;
variable mybcd : std_logic_vector(35 downto 0) := (others => '0');
variable bint : std_logic_vector(31 downto 0) := bin;
begin
	for i in 0 to 31 loop  -- repeating 16 times.
		mybcd(35 downto 1) := mybcd(34 downto 0);  --shifting the bits.
		mybcd(0) := bint(31);
		bint(31 downto 1) := bint(30 downto 0);
		bint(0) :='0';


		if(i < 31 and mybcd(3 downto 0) > "0100") then --add 3 if BCD digit is greater than 4.
		mybcd(3 downto 0) := std_logic_vector(unsigned(mybcd(3 downto 0)) + 3);
		end if;

		if(i < 31 and mybcd(7 downto 4) > "0100") then --add 3 if BCD digit is greater than 4.
		mybcd(7 downto 4) := std_logic_vector(unsigned(mybcd(7 downto 4)) + 3);
		end if;

		if(i < 31 and mybcd(11 downto 8) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(11 downto 8) := std_logic_vector(unsigned(mybcd(11 downto 8)) + 3);
		end if;

		if(i < 31 and mybcd(15 downto 12) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(15 downto 12) := std_logic_vector(unsigned(mybcd(15 downto 12)) + 3);
		end if;

		if(i < 31 and mybcd(19 downto 16) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(19 downto 16) := std_logic_vector(unsigned(mybcd(19 downto 16)) + 3);
		end if;

		if(i < 31 and mybcd(23 downto 20) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(23 downto 20) := std_logic_vector(unsigned(mybcd(23 downto 20)) + 3);
		end if;

		if(i < 31 and mybcd(27 downto 24) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(27 downto 24) := std_logic_vector(unsigned(mybcd(27 downto 24)) + 3);
		end if;

		if(i < 31 and mybcd(31 downto 28) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(31 downto 28) := std_logic_vector(unsigned(mybcd(31 downto 28)) + 3);
		end if;

		if(i < 31 and mybcd(35 downto 32) > "0100") then  --add 3 if BCD digit is greater than 4.
		mybcd(35 downto 32) := std_logic_vector(unsigned(mybcd(35 downto 32)) + 3);
		end if;

	end loop;
	
	return mybcd;
end to_bcd;


	-- Counters
	--	----------------

	signal Counter:			unsigned(31 downto 0)	:= X"00000000";		--	Main Counter 1 Hz, max. 9.999 kHz (binary)


	--	LED Display
	--	-----------

	signal Number:			std_logic_vector(35 downto 0) :=	X"000000000";				--	LED Display Input
	signal Freq:			std_logic_vector(31 downto 0) :=	X"00000000";				--	Measured Frequency
	signal MuxCounter:	unsigned(31 downto 0)	:=	(others => '0');	--	LED Multiplex - Multiplex Clock Divider
	signal Enable:			std_logic;
	signal Digits:			std_logic_vector(7 downto 0)	:=	X"01";	--	LED Multiplex - Digit Counter - LED Digit Output
	signal Segments:		std_logic_vector(0 to 7);						--	LED Segment Output
	signal Code:			std_logic_vector(3 downto 0);					--	BCD to 7 Segment Decoder Output

	
	signal LO_CLOCK:	std_logic;		-- Frequency divided by 2
	signal EXT_CLOCK:	std_logic;		-- Input Frequency

	signal Decko:	std_logic;												-- D flip-flop
	signal State:	unsigned(2 downto 0)	:=	(others => '0');		-- Inner states of automata
 	
begin

	-- Input divider by 2
	process (EXT_CLOCK)
	begin
		if rising_edge(EXT_CLOCK) then
			LO_CLOCK <= not LO_CLOCK;
		end if;
	end process;


	-- Counter
	process (LO_CLOCK)
	begin
	
		if rising_edge(LO_CLOCK) then
		
			if (State = 3) or (State = 0) then
				if DIPSW(7) = '0' then		-- Half/Full frequency
					Counter <= Counter + 1;
				else
					Counter <= Counter + 2;
				end if;
			end if;
			if (State = 1) then
				Freq(31 downto 0) <= std_logic_vector(Counter);
			end if;
			if (State = 2) then
				Counter <= (others => '0');
			end if;
		end if;

	end process;	


	-- Sampling 1PPS signal
	process (LO_CLOCK)
	begin
		if rising_edge(LO_CLOCK) then
			Decko <= B(22);
		end if;
	end process;

	-- Automata for controlling the Counter
	process (LO_CLOCK)
	begin
		if rising_edge(LO_CLOCK) then
			if (Decko = '1') then
				if (State < 3) then
					State <= State + 1;
				end if;
			else
				State <= (others => '0');
			end if;
		end if;
	end process;

	-- Coding to BCD for LED Display 

	process (Decko)
   begin
		if falling_edge(Decko) then
			Number(35  downto 0) <= to_bcd(Freq(31 downto 0));	
		end if;
	end process;

--	Number(35 downto 0) <=	NumberPom(35 downto 0);
	
	LED(7) <= Decko; -- Disply 1PPS pulse on LEDbar
	LED(6 downto 4) <= (others => '0');
	LED(3 downto 0) <= Number(35 downto 32); --	Disply 100-th of MHz on LEDbar

	--	LED Display (multiplexed)
	--	=========================

	--	Connect LED Display Output Ports (negative outputs)
	LD_A_n	<=	not (Segments(0) and Enable);
	LD_B_n	<=	not (Segments(1) and Enable);
	LD_C_n	<=	not (Segments(2) and Enable);
	LD_D_n	<=	not (Segments(3) and Enable);
	LD_E_n	<=	not (Segments(4) and Enable);
	LD_F_n	<=	not (Segments(5) and Enable);
	LD_G_n	<=	not (Segments(6) and Enable);
	LD_DP_n	<=	not (Segments(7) and Enable);

	LD_0_n	<=	not Digits(0);
	LD_1_n	<=	not Digits(1);
	LD_2_n	<=	not Digits(2);
	LD_3_n	<=	not Digits(3);
	LD_4_n	<=	not Digits(4);
	LD_5_n	<=	not Digits(5);
	LD_6_n	<=	not Digits(6);
	LD_7_n	<=	not Digits(7);

	--	Time Multiplex
	process (CLK100MHz)
	begin
		if rising_edge(CLK100MHz) then
			if MuxCounter < MUXCOUNT-1 then
				MuxCounter <= MuxCounter + 1;
			else
				MuxCounter <= (others => '0');
				Digits(7 downto 0) <= Digits(6 downto 0) & Digits(7);	--	Rotate Left
				Enable <= '0';
			end if;
			if MuxCounter > (MUXCOUNT-4) then
				Enable <= '1';
			end if;
		end if;
	end process;

	--	HEX to 7 Segmet Decoder
	--	 --     A
	--	|  |  F   B
	--	 --     G
	--	|  |  E   C
	--	 --     D   H
	--              ABCDEFGH
	Segments		<=	"11111100"	when	Code="0000"	else	--	Digit 0
						"01100000"	when	Code="0001"	else	--	Digit 1
						"11011010"	when	Code="0010"	else	--	Digit 2
						"11110010"	when	Code="0011"	else	--	Digit 3
						"01100110"	when	Code="0100"	else	--	Digit 4
						"10110110"	when	Code="0101"	else	--	Digit 5
						"10111110"	when	Code="0110"	else	--	Digit 6
						"11100000"	when	Code="0111"	else	--	Digit 7
						"11111110"	when	Code="1000"	else	--	Digit 8
						"11110110"	when	Code="1001"	else	--	Digit 9
						"11101110"	when	Code="1010"	else	--	Digit A
						"00111110"	when	Code="1011"	else	--	Digit b
						"10011100"	when	Code="1100"	else	--	Digit C
						"01111010"	when	Code="1101"	else	--	Digit d
						"10011110"	when	Code="1110"	else	--	Digit E
						"10001110"	when	Code="1111"	else	--	Digit F
						"00000000";

	Code 			<=	Number( 3 downto  0)	when	Digits="00000001"	else
						Number( 7 downto  4)	when	Digits="00000010"	else
						Number(11 downto  8)	when	Digits="00000100"	else
						Number(15 downto 12)	when	Digits="00001000"	else
						Number(19 downto 16)	when	Digits="00010000"	else
						Number(23 downto 20)	when	Digits="00100000"	else
						Number(27 downto 24)	when	Digits="01000000"	else
						Number(31 downto 28)	when	Digits="10000000"	else
						"0000";



	-- Diferencial In/Outs
	-- ========================
   DIFbuffer1 : IBUFGDS
   generic map (
      DIFF_TERM => FALSE, -- Differential Termination 
      IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer, 
                               -- "0"-"16" 
      IOSTANDARD => "LVPECL_33")
   port map (
      I => SD1AP,  -- Diff_p buffer input (connect directly to top-level port)
      IB => SD1AN, -- Diff_n buffer input (connect directly to top-level port)
      O => EXT_CLOCK  -- Buffer output - Counter INPUT
   );

	OBUFDS_inst : OBUFDS
   generic map (
      IOSTANDARD => "LVDS_33")
   port map (
      O => SD2AP,     -- Diff_p output (connect directly to top-level port)
      OB => SD2AN,   -- Diff_n output (connect directly to top-level port)
      I => EXT_CLOCK      -- Buffer input are connected directly to IBUFGDS
   );
	
	--	Output Signal on SATA Connector
--	SD1AP			<=	'Z';	-- Counter INPUT
--	SD1AN			<=	'Z';
	SD1BP			<=	'Z';
	SD1BN			<=	'Z';

	--	Input Here via SATA Cable
--	SD2AP			<=	'Z';	-- Counter OUTPUT
--	SD2AN			<=	'Z';
	SD2BP			<=	'Z';
	SD2BN			<=	'Z';


	--	Unused Signals
	--	==============

	-- Differential inputs onn header
	DIF1N <= 'Z';
	DIF1P <= 'Z';
	DIF2N <= 'Z';
	DIF2P <= 'Z';

	--	I2C Signals (on connector J30)
	I2C_SCL		<=	'Z';
	I2C_SDA		<=	'Z';

	--	SPI Memory Interface
	SPI_CS_n		<=	'Z';
	SPI_DO		<=	'Z';
	SPI_DI		<=	'Z';
	SPI_CLK		<=	'Z';
	SPI_WP_n		<=	'Z';

	-- A/D
   ANA_OUTD	<= 'Z';
	ANA_REFD <= 'Z';

	-- VGA
	VGA_R	<= "ZZ";
	VGA_G	<= "ZZ";
	VGA_B	<= "ZZ";
	VGA_VS	<= 'Z';
	VGA_HS	<= 'Z';

	-- PS2
	PS2_DATA2 <= 'Z';
	PS2_CLK2 <='Z';

end architecture AtomicCounter_a;
