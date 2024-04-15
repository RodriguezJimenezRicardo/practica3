library ieee;
use ieee.std_logic_1164.all;

entity alu is port(
	clk: in std_logic;
	A,B: in std_logic_vector(11 downto 0);
	control: in std_logic_vector(3 downto 0);
	result: out std_logic_vector(11 downto 0);
	C,Z: out std_logic
);
end alu;

architecture a_alu of alu is
	component SumRest12Bits is Port (
			A : in STD_LOGIC_VECTOR(11 downto 0);
			B : in STD_LOGIC_VECTOR(11 downto 0);
			Op : in STD_LOGIC;
			CarryIn : in STD_LOGIC;
			SumRest : out STD_LOGIC_VECTOR(11 downto 0);
			CarryOut : out STD_LOGIC);
    end component;
	
	component multi6 is port(
        A, B: in std_logic_vector(11 downto 0);
        result: out std_logic_vector(11 downto 0)
    );
	end component;

	constant two : std_logic_vector(11 downto 0):="000000000010";
	constant one : std_logic_vector(11 downto 0):="000000000001";
	constant zero: std_logic_vector(11 downto 0):="000000000000";
	
	signal substract: std_logic;
	signal sum_result: std_logic_vector(11 downto 0);
	signal logic_result: std_logic_vector(11 downto 0);
	signal multi_result: std_logic_vector(11 downto 0);
	signal div_result: std_logic_vector(11 downto 0);
	signal all_results: std_logic_vector(11 downto 0);
	signal A_temp,B_temp: std_logic_vector(11 downto 0);

begin
	imp_add_sub_12: SumRest12Bits port map(A_temp,B_temp,substract,'0',sum_result,C);
	imp_multi: multi6 port map(A_temp,B_temp,multi_result);
	--imp_div: divi6 port map(clk,A_temp,B_temp,div_result);
	input_process:process(A,B,control)
	begin
		case control is
			when "0000"=>--A+B  1 BYTE
			A_temp<="0000"&A(7 downto 0);
			B_temp<="0000"&B(7 downto 0);
			substract<='0';
			when "0001"=>--A-B 1 BYTE
			A_temp<="0000"&A(7 downto 0);
			B_temp<="0000"&B(7 downto 0);
			substract<='1';
			when "0010"=>--A+1
			A_temp<=A;
			B_temp<=one;
			substract<='0';
			when "0011"=>--A-1
			A_temp<=A;
			B_temp<=one;
			substract<='1';
			when "0100"=>--B+1
			A_temp<=one;
			B_temp<=B;
			substract<='0';
			when "0101"=>--B-1
			A_temp<=one;
			B_temp<=B;
			substract<='1';
			when "0110"=>--A+B 12 BITS
			A_temp<=A;
			B_temp<=B;
			substract<='0';
			when "0111"=>--A-B 12 BITS
			A_temp<=A;
			B_temp<=B;
			substract<='1';
			when "1000"=>--AND
			logic_result<=A and B;
			when "1001"=>--OR
			logic_result<=A or B;
			when "1010"=>--XOR
			logic_result<=A xor B;
			when "1011"=>--COMP A 1
			A_temp<=not A;
			B_temp<=zero;
			substract<='0';
			when "1100"=>--COMP A 2
			A_temp<=zero;
			B_temp<=B;
			substract<='1';
			when "1101"=>--A*B 6 BITS
			A_temp<="000000"&A(5 downto 0);
			B_temp<="000000"&B(5 downto 0);
			when "1110"=>--A/B 6 BITS
			A_temp<="000000"&A(5 downto 0);
			B_temp<="000000"&B(5 downto 0);
			when "1111"=>--A LSL
			A_temp<=A;
			B_temp<=A;
			when others=>
				A_temp<=zero;
				B_temp<=zero;
		end case;
	end process input_process;
	
	process(all_results)
    begin
        if all_results = zero then
            Z <= '1'; -- Si el resultado es cero, la flag de Zero se establece en '1'
        else
            Z <= '0'; -- Si el resultado no es cero, la flag de Zero se establece en '0'
        end if;
    end process;
	
	with control select
		all_results<=sum_result   when "0000",
					sum_result   when "0001",
					sum_result   when "0010",
					sum_result   when "0011",
					sum_result   when "0100",
					sum_result   when "0101",
					sum_result   when "0110",
					sum_result   when "0111",
					logic_result when "1000",
					logic_result when "1001",
					logic_result when "1010",
					sum_result   when "1011",
					sum_result   when "1100",
					multi_result when "1101",
					div_result  when "1110",
					sum_result when "1111";
	
	result <= all_results;
end a_alu;