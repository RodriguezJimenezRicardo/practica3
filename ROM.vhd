library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

entity ROM is port(
	clk: in std_logic;
	clr: in std_logic;
	enable: in std_logic;
	read_m : in std_logic; 
	address: in std_logic_vector(7 downto 0);
	data_out : out std_logic_vector(23 downto 0)
);
end ROM;

architecture a_ROM of ROM is
	
	--Control ROM
	constant OP_ADD8: std_logic_vector(5 downto 0):=  "000000";
	constant OP_SUB8: std_logic_vector(5 downto 0):=  "000001";
	constant OP_AND: std_logic_vector(5 downto 0):=   "000010";
	constant OP_AINC: std_logic_vector(5 downto 0):=  "000011";
	constant OP_ADEC: std_logic_vector(5 downto 0):=  "000100";
	constant OP_BINC: std_logic_vector(5 downto 0):=  "000101";
	constant OP_BDEC: std_logic_vector(5 downto 0):=  "000110";
	constant OP_ADD: std_logic_vector(5 downto 0):=   "000111";
	constant OP_SUB: std_logic_vector(5 downto 0):=   "001000";
	constant OP_ADDI: std_logic_vector(5 downto 0):=  "001001";
	constant OP_OR: std_logic_vector(5 downto 0):=    "001010";
	constant OP_XOR: std_logic_vector(5 downto 0):=   "001011";
	constant OP_COMP1: std_logic_vector(5 downto 0):= "001100";
	constant OP_COMP2: std_logic_vector(5 downto 0):= "001101";
	constant OP_MULT: std_logic_vector(5 downto 0):=  "001110";
	constant OP_DIV: std_logic_vector(5 downto 0):=   "001111";
	constant OP_LSL: std_logic_vector(5 downto 0):=   "010000";
	constant OP_LOAD: std_logic_vector(5 downto 0):=  "010001";
	constant OP_MOV: std_logic_vector(5 downto 0):=   "010010";
	constant OP_HALT: std_logic_vector(5 downto 0):=  "010011";
	constant OP_BNZ: std_logic_vector(5 downto 0):=   "010100";
	constant OP_BZ: std_logic_vector(5 downto 0):=    "010101";
	constant OP_NOP: std_logic_vector(5 downto 0):=   "010110";
	constant OP_JMP: std_logic_vector(5 downto 0):=   "010111";
	constant OP_DPLY: std_logic_vector(5 downto 0):=   "011000";
	constant OP_DPLYI: std_logic_vector(5 downto 0):=  "011001";

	--Control RPG
	constant RPG_A: std_logic_vector(1 downto 0):= "00";
	constant RPG_B: std_logic_vector(1 downto 0):= "01";
	constant RPG_C: std_logic_vector(1 downto 0):= "10";
	constant RPG_D: std_logic_vector(1 downto 0):= "11";

	--Control ALU
	constant ALU_: std_logic_vector(1 downto 0):= "00";

	type ROM_Array is array (0 to 255) of std_logic_vector(23 downto 0);
	constant content: ROM_Array := (
		0 => OP_LOAD&"00"&"0000000011110111",--LOAD W,RA	++++++++++++++++++++++++++++++++
		1 => OP_ADDI&"00"&"000000000101"&"0110",--ADDI RA,5 ------------------------------
		2 => OP_DPLY&"00"&"0000000000000000",--Rdisplay<- RA
		3 => OP_LOAD&"01"&"0000000011110110",--LOAD i,RB	++++++++++++++++++++++++++++++++
		4 => OP_ADEC&"01"&"000000000000"&"0011",-- DEC RB
		5 =>  OP_NOP&"000000000000000000", --NOP
		6 =>  OP_BNZ&"100000000000000011", --BNZ,-3
		7 => OP_LOAD&"00"&"0000000011111000",--LOAD X,RA	++++++++++++++++++++++++++++++++
		8 => OP_ADDI&"00"&"000000000110"&"0110",--ADDI RA,6 -------------------------------
		9 => OP_DPLY&"00"&"0000000000000000",--Rdisplay<- RA
		10 => OP_LOAD&"01"&"0000000011110110",--LOAD i,RB	++++++++++++++++++++++++++++++++
		11=> OP_ADEC&"01"&"000000000000"&"0011",-- DEC RB
		12 =>  OP_NOP&"000000000000000000",--NOP
		13 =>  OP_BNZ&"100000000000000011", --BNZ,-3
		14 => OP_LOAD&"00"&"0000000011111001",--LOAD Y,RA	++++++++++++++++++++++++++++++++
		15 => OP_ADDI&"00"&"000000000111"&"0110",--ADDI RA,7 ----------------------------
		16 => OP_DPLY&"00"&"0000000000000000",--Rdisplay<- RA
		17 => OP_LOAD&"01"&"0000000011110110",--LOAD i,RB	++++++++++++++++++++++++++++++++
		18=> OP_ADEC&"01"&"000000000000"&"0011",-- DEC RB
		19 =>  OP_NOP&"000000000000000000",--NOP
		20 =>  OP_BNZ&"100000000000000011", --BNZ,-3
		21 => OP_HALT&"000000000000000000",
		--Ecuacion a w+x+y
		23 => OP_LOAD&RPG_A&"00000000"&"11110111",--load w en RA
		24 => OP_LOAD&RPG_B&"00000000"&"11111000",--load x en RB
		25 => OP_LOAD&RPG_C&"00000000"&"11111001",--load y en RC
		26 => OP_ADD&"00"&"01"&"0000000000"&"0110", --add RA + RB, RA
		27 => OP_ADD&"00"&"10"&"0000000000"&"0110", --add RA + RC, RA
		28 => OP_DPLY&"00"&"0000000000000000",--Rdisplay<- RA
		29 => ,
		30 => ,
		31 => ,
		32 => ,
		33 => ,
		34 => ,

		46=> OP_HALT&"000000000000000000",
		--Ecuacion b m-n-o
		47 =>

		70 => OP_HALT&"000000000000000000",
		--Ecuacion c 
		71 =>

		94 => OP_HALT&"000000000000000000",
		--Ecuacion d
		95 =>


		246 => x"000012",-- 3 en decimal i
		247 => x"0003EB", -- 1003 en decimal W
		248 => x"000065", -- 101 en decimal X
		249 => x"000046", -- 70 en decimal Y 
		250 => x"000032", -- 50 en decimal Z
		251 => x"000012", -- 18 en decimal M
		252 => x"000007", -- 7 en decimal N
		253 => x"000017", -- 23 en decimal O 
		254 => x"000037", -- 55 en decimal P 
		255 => x"00004D", -- 77 en decimal Q
		others => x"FFFFFF"
	);
begin
	process(clk,clr,read_m,address)
	begin
		if(clr='1') then	
			data_out<=(others=>'Z');
		elsif(clk'event and clk='1') then
			if(enable='1') then 
				if(read_m='1') then
					data_out<=content(conv_integer(address));
				else
					data_out<=(others=>'Z');
				end if;
			end if;
		end if;
	end process;
end a_ROM;
					