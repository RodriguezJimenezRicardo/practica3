library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
----------------------------------------------------------

----------------------------------------------------------
entity alu_fetch is port(
	reset: in std_logic;
	stop_run: in std_logic;
	S0 : in std_logic;
	S1 : in std_logic;
	display: out std_logic_vector(6 downto 0);
	Pc_directo : in std_logic;
	sel: out std_logic_vector(3 downto 0)
);
end alu_fetch;

architecture behavior of alu_fetch is
----------OSCILADOR INTERNO-------------------------------
    component OSCH
        generic (NOM_FREQ: string);
        port (STDBY: in std_logic; OSC: out std_logic);
    end component;
    
    attribute NOM_FREQ: string;
    attribute NOM_FREQ of OSCinst0: label is "26.60";
----------------------------------------------------------

	component MultiplexorGeneral is port(
		S0: in std_logic;
		S1: in std_logic;
		PcOut: out std_logic_vector(7 downto 0)
		);
	end component;

	component ROM is port(
		clk: in std_logic;
		clr: in std_logic;
		enable: in std_logic;
		read_m : in std_logic; 
		address: in std_logic_vector(7 downto 0);
		data_out : out std_logic_vector(23 downto 0)
	);
	end component;
		
	component registrosPG is Port ( 
		clk      : in  STD_LOGIC;
	   reset    : in  STD_LOGIC;
	   enable   : in  STD_LOGIC;
	   data_in  : in  STD_LOGIC_VECTOR (23 downto 0);
	   selector : in  STD_LOGIC_VECTOR (1 downto 0);
	   data_out : out STD_LOGIC_VECTOR (23 downto 0));
	end component;
	
	component bcdDisplay is port(
		CLK,CLR: IN STD_LOGIC;
		E: IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		DISPLAY:INOUT STD_LOGIC_VECTOR(6 DOWNTO 0)	
		);
	end component;

	component Bin2BCD is port(
		clr: in std_logic;
        bin_in : IN STD_LOGIC_VECTOR(13 DOWNTO 0);
        bcd_out   : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
    );
	end component;
	
	component alu is port(
		clk: in std_logic;
		A,B: in std_logic_vector(11 downto 0);
		control: in std_logic_vector(3 downto 0);
		result: out std_logic_vector(11 downto 0);
		C,Z: out std_logic);
	end component;

signal clk: std_logic;
signal clk_0: std_logic:='0';
signal clk_1: std_logic:='0';
signal Q: std_logic_vector(13 downto 0);
signal Qbcd: std_logic_vector(15 downto 0);
signal temp_control: std_logic_vector(3 downto 0);
signal un,de,ce,mi: std_logic_vector(6 downto 0);
signal Rdisplay: std_logic_vector(13 downto 0);
--REGISTROS PARA DATAPATH--
signal PC: std_logic_vector(7 downto 0):="00000000";
signal MAR: std_logic_vector(7 downto 0):=(others=>'0');
signal MBR: std_logic_vector(23 downto 0);
signal IR: std_logic_vector(23 downto 0);
signal ACC: std_logic_vector(11 downto 0);


--entradas,salidas componentes
--signal address_bus: std_logic_vector(7 downto 0);
signal data_bus: std_logic_vector(23 downto 0);
signal rpg_in: std_logic_vector(23 downto 0):=(others=>'0');
signal rpg_out: std_logic_vector(23 downto 0);
signal rpg_sel: std_logic_vector(1 downto 0):=(others=>'0');
signal rpg_in2: std_logic_vector(23 downto 0):=(others=>'0');
signal rpg_out2: std_logic_vector(23 downto 0);
signal rpg_sel2: std_logic_vector(1 downto 0):=(others=>'0');
signal rpg_write: std_logic:='0';
signal A,B: std_logic_vector(11 downto 0);
signal control: std_logic_vector(3 downto 0);
signal C,Z: std_logic;
signal PcOut : std_logic_vector (7 downto 0);


type global_state_type is (reset_pc,fetch,fetch1,fetch2,fetch3,end_fetch,decode,end_decode, execute,end_execute); 
signal global_state: global_state_type;

type instruction_type is (i_add, i_addi,i_load,i_jump,i_display,i_displayi,i_halt,i_null,i_nop,i_bnz,i_dec, i_mult, i_div,  i_subb);
signal instruction: instruction_type;

type execute_instruction_type is(t0,t1,t2,t3,t4);
signal execute_instruction: execute_instruction_type;


begin
-----------IMPLEMENTACION OSCILADOR INTERNO---------------
OSCinst0: OSCH generic map("26.60") port map('0', clk);
----------------------------------------------------------

imp_binBCD: bin2bcd port map(reset,Q,Qbcd);
--clk_0
unidades: bcdDisplay port map(clk_0,reset,Qbcd(3 downto 0),un);
decenas: bcdDisplay port map(clk_0,reset,Qbcd(7 downto 4),de);
centenas: bcdDisplay port map(clk_0,reset,Qbcd(11 downto 8),ce);
millar: bcdDisplay port map(clk_0,reset,Qbcd(15 downto 12),mi);

--clk
ROM_imp: ROM port map(clk_0,reset,'1','1',MAR,data_bus);
RPG : registrosPG port map(clk_0,reset,rpg_write,rpg_in,rpg_sel,rpg_out);
RPG : registrosPG2 port map(clk_0,reset,rpg_write,rpg_in2,rpg_sel2,rpg_out2);
ALU_imp : alu port map(clk_0,A,B,control,ACC(11 downto 0),C,Z); 
Multi_general : MultiplexorGeneral port map(S0,S1,PcOut);

	process(clk_0, reset, stop_run,PcOut)
	begin
		if (reset = '1') then
			global_state <= reset_pc;
			execute_instruction<=t0;
			PC<=PcOut;
			MAR<=(others=>'0');
			MBR<=(others=>'0');
			IR<=(others=>'0');
		elsif (rising_edge(clk_0) and stop_run='0') then			
			case global_state is
				when reset_pc=>
					global_state<=fetch;
				when fetch =>
					MAR<=PC;
					global_state<=fetch1;
				when fetch1 =>
					global_state<=fetch2;--sincronizar data_bus 
				when fetch2 => 
					MBR<=data_bus;
					global_state<=fetch3;
				when fetch3=>
					PC<=PC+1;
					IR<=MBR;
					global_state<=end_fetch;
				when end_fetch=>
					global_state<=decode;
				when decode =>
					case IR(23 downto 18) is
						when "000111" =>instruction <= i_add;
						when "001001" =>instruction <= i_addi;
						when "010001" =>instruction <= i_load;
						when "010111" =>instruction <= i_jump;
						when "011000" =>instruction <= i_display;
						when "011001" =>instruction <= i_displayi;
						when "010011" =>instruction <= i_halt;
						when "010100" =>instruction <= i_bnz;
						when "010110" =>instruction <= i_nop;
						when "000100" =>instruction <= i_dec;
						when "001110" =>instruction <= i_mult;
						when "001111" =>instruction <= i_div;
						when "001000" =>instruction <= i_subb;
						when others =>
							instruction <= i_null;
					end case;
					global_state<=end_decode;
				when end_decode=>
					global_state<=execute;
				when execute =>
					case instruction is
						when i_add =>
							case execute_instruction is
								when t0 => 
									execute_instruction <= t1;
								when t1 =>
									rpg_sel <= IR(17 downto 16);
									rpg_sel2 <=IR(15 downto 14);
									execute_instruction <= t2;
								when t2 =>
									control <= IR(3 downto 0);
									A<=rpg_out(11 downto 0);
									B<=rpg_out2(11 downto 0);
									execute_instruction <= t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="00000000000"&C&ACC;
									else
										rpg_in<="000000000000"&ACC;
									end if;
									execute_instruction <= t4;
								when t4 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_state;
							end case;
						when i_subb =>
							case execute_instruction is
								when t0 => 
									execute_instruction <= t1;
								when t1 =>
									rpg_sel <= IR(17 downto 16);
									rpg_sel2 <=IR(15 downto 14);
									execute_instruction <= t2;
								when t2 =>
									control <= IR(3 downto 0);
									A<=rpg_out(11 downto 0);
									B<=rpg_out2(11 downto 0);
									execute_instruction <= t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="00000000000"&C&ACC;
									else
										rpg_in<="000000000000"&ACC;
									end if;
									execute_instruction <= t4;
								when t4 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_state;
							end case;
						when i_addi =>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>
									control<=IR(3 downto 0);
									A<=rpg_out(11 downto 0);
									B<=IR(15 downto 4);
									execute_instruction<=t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="00000000000"&C&ACC;
									else
										rpg_in<="000000000000"&ACC;
									end if;
									execute_instruction<=t4;
								when t4 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
						when i_mult =>
							case execute_instruction is
								when t0 => 
									execute_instruction <= t1;
								when t1 =>
									rpg_sel <= IR(17 downto 16);
									rpg_sel2 <=IR(15 downto 14);
									execute_instruction <= t2;
								when t2 =>
									control <= IR(3 downto 0);
									A<=rpg_out(5 downto 0);
									B<=rpg_out2(5 downto 0);
									execute_instruction <= t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="00000000000"&C&ACC;
									else
										rpg_in<="000000000000"&ACC;
									end if;
									execute_instruction <= t4;
								when t4 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_state;
							end case;
						when i_div =>
							case execute_instruction is
								when t0 => 
									execute_instruction <= t1;
								when t1 =>
									rpg_sel <= IR(17 downto 16);
									rpg_sel2 <=IR(15 downto 14);
									execute_instruction <= t2;
								when t2 =>
									control <= IR(3 downto 0);
									A<=rpg_out(5 downto 0);
									B<=rpg_out2(5 downto 0);
									execute_instruction <= t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="00000000000"&C&ACC;
									else
										rpg_in<="000000000000"&ACC;
									end if;
									execute_instruction <= t4;
								when t4 =>
									rpg_write <= '0';
									execute_instruction <= t0;
									global_state <= end_state;
							end case;
						when i_load =>
							case execute_instruction is 
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									MAR<=IR(7 downto 0);
									execute_instruction<=t2;
								when t2 =>
									execute_instruction<=t3;--sincronizar data_bus
								when t3 =>
									rpg_write<='1';
									rpg_sel<=IR(17 downto 16);
									rpg_in<=data_bus;
									execute_instruction<=t4;
								when t4 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
						when i_display=>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>--sincronizar  data_out;
									execute_instruction<=t3;
								when t3 =>
									Rdisplay<=rpg_out(13 downto 0);
									execute_instruction<=t0;
									global_state<=end_execute;
								when others =>
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
						when i_displayi=>
							Rdisplay<=IR(13 downto 0);
							global_state<=end_execute;
						when i_halt =>
							if(Pc_directo = '1') then
								Pc <= PcOut;
							else
								PC<=PC-1;
							end if;
							global_state<=end_execute;
						when i_jump =>
							PC<=IR(7 downto 0);
							global_state<=end_execute;
						when i_nop =>
							global_state<=end_execute;
						when i_dec =>
							case execute_instruction is
								when t0 =>
									execute_instruction<=t1;
								when t1 =>
									rpg_sel<=IR(17 downto 16);
									execute_instruction<=t2;
								when t2 =>
									control<=IR(3 downto 0);
									A<=rpg_out(11 downto 0);
									execute_instruction<=t3;
								when t3 =>
									rpg_write<='1';
									if(C = '1') then
										rpg_in<="00000000000"&C&ACC;
									else
										rpg_in<="000000000000"&ACC;
									end if;
									execute_instruction<=t4;
								when t4 =>
									rpg_write<='0';
									execute_instruction<=t0;
									global_state<=end_execute;
							end case;
						when i_bnz =>
							if(Z = '0') then
								if(IR(17) = '0') then
									PC<=PC+IR(7 downto 0);
								else
									PC<=PC-IR(7 downto 0);
								end if;
								global_state<=end_execute;
							else
								global_state<=end_execute;
							end if;
						when others =>
							global_state<=end_execute;
					end case;
				when end_execute=>
					global_state<=fetch;
				when others =>
					global_state<=reset_pc;
			end case;
		end if;
	end process;

	Q<=Rdisplay;
	process(clk_0, reset)
	begin
		if (reset = '1') then
			temp_control <= "0000";
		elsif (rising_edge(clk_0)) then
			case temp_control is
				when "0000"=>
					temp_control <= "0001";
				when "0001"=> 
					temp_control <= "0010";
					display <= mi;
				when "0010"=> 
					temp_control <= "0100";
					display <= ce;
				when "0100"=> 
					temp_control <= "1000";
					display <= de;
				when "1000"=> 
					temp_control <= "0001";
					display <= un;
				when others=>
					temp_control <= "0000";
			end case;
			sel <= temp_control;
		end if;
end process;

process(clk, reset)
	variable count: integer range 0 to 250000;
	variable count1: integer range 0 to 2500000;
	begin
		if (reset = '1') then
			clk_0<= '0';
			clk_1<= '0';
		elsif (rising_edge(clk)) then
			if (count < 100000) then
				count := count + 1;
			else
				count := 0;
				clk_0 <= not clk_0;
			end if;
			
			if (count1 < 1000000) then
				count1 := count1 + 1;
			else
				count1 := 0;
				clk_1 <= not clk_1;
			end if;
		end if;
end process;
end behavior;
