library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DeBounce is
    port(   Clock : in std_logic;
            Reset : in std_logic;
            button_in : in std_logic;
            pulse_out : out std_logic
        );
end DeBounce;

architecture behav of DeBounce is

--the below constants decide the working parameters.
--the higher this is, the more longer time the user has to press the button.
constant COUNT_MAX : integer := 1500000; 
--set it '1' if the button creates a high pulse when its pressed, otherwise '0'.
constant BTN_ACTIVE : std_logic := '1';

signal count : integer := 0;
type state_type is (idle,wait_time, wait_time2); --state machine
signal state : state_type := idle;

begin
  
process(Reset,Clock)
begin
    if(Reset = '1') then
        state <= idle;
        pulse_out <= '0';
   elsif(rising_edge(Clock)) then
        case (state) is
            when idle =>
                if(button_in = BTN_ACTIVE) then  
                    state <= wait_time;
                else
                    state <= idle; --wait until button is pressed.
                end if;
                pulse_out <= '0';
            when wait_time =>
                if(count = COUNT_MAX) then
                    count <= 0;
                    if(button_in = BTN_ACTIVE) then
                        pulse_out <= '1';
                    end if;
                    state <= wait_time2;  
                else
                    count <= count + 1;
                end if; 
			  when wait_time2 =>
			       pulse_out <= '0';
					 if(button_in = not BTN_ACTIVE) then
							state <= idle;
                end if;
        end case;       
    end if;        
end process;                  
                                                                                
end architecture behav;