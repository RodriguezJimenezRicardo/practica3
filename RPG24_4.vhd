library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; -- Para operaciones numéricas con std_logic_vector

entity registrosPG is
    Port ( clk      : in  STD_LOGIC;
           reset    : in  STD_LOGIC;
           enable   : in  STD_LOGIC;
           data_in  : in  STD_LOGIC_VECTOR (23 downto 0);
           selector : in  STD_LOGIC_VECTOR (1 downto 0);
           data_out : out STD_LOGIC_VECTOR (23 downto 0));
end registrosPG;

architecture Behavioral of registrosPG is
    type registro_array is array (0 to 3) of STD_LOGIC_VECTOR(23 downto 0);
    signal registros : registro_array := (others => (others => '0'));
begin

    -- Proceso de escritura con reset asincrónico
    process(clk, reset)
    begin
        if reset = '1' then
            registros <= (others => (others => '0'));
        elsif rising_edge(clk) then
            if enable = '1' then
                case selector is
                    when "00" =>
                        registros(0) <= data_in;
                    when "01" =>
                        registros(1) <= data_in;
                    when "10" =>
                        registros(2) <= data_in;
                    when "11" =>
                        registros(3) <= data_in;
                    when others =>
                        null; -- No hacer nada para casos no definidos
                end case;
            end if;
        end if;
    end process;

    -- Asignación de data_out basada en selector
    data_out <= registros(TO_INTEGER(unsigned(selector)));

end Behavioral;