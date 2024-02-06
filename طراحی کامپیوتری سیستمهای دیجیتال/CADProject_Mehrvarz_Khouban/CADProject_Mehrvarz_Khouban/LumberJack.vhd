library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity LumberJack is
    Port(
        CLOCK_24     : in std_logic;
        RESET_N      : in std_logic;
        VGA_B        : out std_logic_vector(1 downto 0);
        VGA_G        : out std_logic_vector(1 downto 0);
        VGA_HS       : out std_logic;
        VGA_R        : out std_logic_vector(1 downto 0);
        VGA_VS       : out std_logic;
        Key          : in std_logic_vector(3 downto 0);
        SW           : in std_logic_vector(7 downto 0);
        Leds         : out std_logic_vector(7 downto 0);
        outseg       : out bit_vector(3 downto 0); -- Enable of segments to choose one
        sevensegments: out bit_vector(7 downto 0)
    );
end LumberJack;

architecture LumberJack of LumberJack is
    -- Components declaration
    Component VGA_controller
        port (
            CLK_24MHz : in std_logic;
            VS        : out std_logic;
            HS        : out std_logic;
            RED       : out std_logic_vector(1 downto 0);
            GREEN     : out std_logic_vector(1 downto 0);
            BLUE      : out std_logic_vector(1 downto 0);
            RESET     : in std_logic;
            ColorIN   : in std_logic_vector(5 downto 0);
            ScanlineX : out std_logic_vector(10 downto 0);
            ScanlineY : out std_logic_vector(10 downto 0)
        );
    end Component;

    Component DeBounce
        port (
            Clock      : in std_logic;
            Reset      : in std_logic;
            button_in  : in std_logic;
            pulse_out  : out std_logic
        );
    end Component;

    -- Signals and variables declaration
    signal ScanlineX, ScanlineY    : std_logic_vector(10 downto 0);
    signal ColorTable              : std_logic_vector(5 downto 0);
    signal seg0, seg1, seg2, seg3  : bit_vector(7 downto 0);
    signal seg_selectors           : bit_vector(3 downto 0) := "1110";
    signal output                  : bit_vector(7 downto 0) := x"c0";
    signal input                   : Integer range 0 to 100 := 0;
    signal leds_signal             : std_logic_vector(7 downto 0) := "10101010";
    -- Game variables
    signal timer_game              : Integer range 0 to 100 := 30;
    signal end_game                : bit := '0';
    signal score                   : integer range 0 to 80 := 0;
    signal lose                    : bit := '0';
    signal current_level           : integer range 0 to 4 := 0;
    signal eat_trophy              : bit := '0';
    signal player_moved            : bit := '0';

    type position is record
        x : integer;
        y : integer;
    end record position;

    type branch_position_t is array(4 downto 0) of position;

    constant LEFT_X : integer := 240;
    constant RIGHT_X : integer := 330;

    signal pseudo_rand : std_logic_vector(31 downto 0) := (others => '0');
    signal Key0_Out    : STD_LOGIC := '0';
    signal Key1_Out    : STD_LOGIC := '0';

begin
    -- LFSR process for pseudo-random number generation
    process (CLOCK_24)
    begin
        function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
        begin
            return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
        end function;
    begin
        if rising_edge(CLOCK_24) then
            if RESET_N = '0' then
                pseudo_rand <= (others => '0');
            else
                pseudo_rand <= lfsr32(pseudo_rand);
            end if;
        end if;
    end process;

    -- Instantiate VGA Controller
    VGA_Control : VGA_controller
        port map(
            CLK_24MHz => CLOCK_24,
            VS        => VGA_VS,
            HS        => VGA_HS,
            RED       => VGA_R,
            GREEN     => VGA_G,
            BLUE      => VGA_B,
            RESET     => not RESET_N,
            ColorIN   => ColorTable,
            ScanlineX => ScanlineX,
            ScanlineY => ScanlineY
        );

    -- Instantiate DeBounce for Key0
    Debounder_Key0 : DeBounce
        port map(
            Clock     => CLOCK_24,
            Reset     => not RESET_N,
            button_in => not Key(0),
            pulse_out => Key0_Out
        );

    -- Instantiate DeBounce for Key1
    Debounder_Key1 : DeBounce
        port map(
            Clock     => CLOCK_24,
            Reset     => not RESET_N,
            button_in => not Key(1),
            pulse_out => Key1_Out
        );

    -- Game loop process
    process (CLOCK_24, RESET_N, ScanlineX, ScanlineY)
        variable flag_key       : bit := '0';
        variable x_1            : integer := 270;
        variable x_2            : integer := 350;
        variable current_x      : integer := x_1;
        variable score_variable : integer range 0 to 80 := 0;
        variable branch_positions: branch_position_t :=
            (0 => (x => LEFT_X, y => 50),
             1 => (x => RIGHT_X, y => 120),
             2 => (x => LEFT_X, y => 240),
             3 => (x => LEFT_X, y => 300),
             4 => (x => RIGHT_X, y => 0));
        variable trophy_position : position := (x => 666, y => 666);

        -- Add trophy to a branch
        procedure add_trophy is
        begin
            if trophy_position.x >= 666 and trophy_position.y >= 666 then
                for i in 0 to branch_positions'length - 1 loop
                    if branch_positions(i).y <= 400 then
                        trophy_position.x := branch_positions(i).x;
                        trophy_position.y := branch_positions(i).y + 10;
                    end if;
                end loop;
            end if;
        end procedure;

        -- Check if a new branch should be added
        impure function should_add_branch(branchs : branch_position_t) return std_logic is
        begin
            for i in 0 to branchs'length - 1 loop
                if branchs(i).y <= 50 then
                    return '0';
                end if;
            end loop;
            return '1';
        end function;

    begin
        if RESET_N = '0' then
            -- Reset game state
            ColorTable := (others => '0');
            trophy_position := (x => 666, y => 666);
            branch_positions :=
                (0 => (x => LEFT_X, y => 50),
                 1 => (x => RIGHT_X, y => 120),
                 2 => (x => LEFT_X, y => 240),
                 3 => (x => LEFT_X, y => 300),
                 4 => (x => RIGHT_X, y => 0));
            score := 0;
            score_variable := 0;
            lose := '0';
        elsif rising_edge(CLOCK_24) then
            player_moved <= '0';

            if end_game = '0' then
                -- Check key inputs for player movement
                if Key0_Out = '1' then
                    current_x := x_1;
                    flag_key := '1';
                    player_moved <= '1';
                elsif Key1_Out = '1' then
                    current_x := x_2;
                    flag_key := '1';
                    player_moved <= '1';
                end if;

                -- Add trophy if conditions are met
                if timer_game <= 5 and eat_trophy = '0' and trophy_position.y >= 666 and trophy_position.x >= 666 then
                    add_trophy;
                end if;

                -- Generate new branches if needed
                for i in 0 to branch_positions'length - 1 loop
                    if branch_positions(i).y >= 666 then
                        if pseudo_rand(0) = '1' then
                            branch_positions(i).x := LEFT_X;
                        else
                            branch_positions(i).x := RIGHT_X;
                        end if;
                        if should_add_branch(branch_positions) = '1' then
                            branch_positions(i).y := 0;
                        end if;
                    end if;
                end loop;

                -- Collision check
                lose := '0';
                if trophy_position.y >= 450 and trophy_position.y < 666 then
                    trophy_position.x := 666;
                    trophy_position.y := 666;
                end if;

                eat_trophy <= '0';
                if trophy_position.y >= 420 and trophy_position.y < 666 then
                    if ( (trophy_position.x = LEFT_X and current_x = x_1) or
                         (trophy_position.x = RIGHT_X and current_x = x_2) ) then
                        trophy_position.x := 666;
                        trophy_position.y := 666;
                        eat_trophy <= '1';
                    end if;
                end if;

                for i in 0 to branch_positions'length - 1 loop
                    if branch_positions(i).y >= 450 and branch_positions(i).y < 666 then
                        if ( (branch_positions(i).x = LEFT_X and current_x = x_2) or
                             (branch_positions(i).x = RIGHT_X and current_x = x_1) ) then
                            branch_positions(i).y := 666;
                        else
                            lose := '1';
                        end if;
                    end if;
                end loop;

                ColorTable <= "000000";

                -- Draw Lumber Jack
                if (ScanlineX >= current_x and ScanlineX <= current_x + 20) and
                   (ScanlineY >= 450 and ScanlineY <= 480) then
                    ColorTable <= "110000";
                end if;

                -- Draw Tree body
                if (ScanlineX >= 310 and ScanlineX <= 330) and (ScanlineY > 0 and ScanlineY < 480) then
                    ColorTable <= "110100";
                end if;

                -- Draw Trophy
                if ( (ScanlineX >= trophy_position.x and ScanlineX <= trophy_position.x + 20) and
                     (ScanlineY >= trophy_position.y and ScanlineY <= trophy_position.y + 40) ) then
                    ColorTable <= "001100";
                end if;

                -- Draw Branches
                for i in 0 to branch_positions'length - 1 loop
                    if ( (ScanlineX >= branch_positions(i).x and ScanlineX <= branch_positions(i).x + 70) and
                         (ScanlineY >= branch_positions(i).y and ScanlineY <= branch_positions(i).y + 10) ) then
                        ColorTable <= "110100";
                    end if;
                end loop;

                -- Branch movement + score management
                if flag_key = '1' then
                    eat_trophy <= '0';
                    flag_key := '0';
                    score_variable := score_variable + 1;
                    for i in 0 to branch_positions'length - 1 loop
                        branch_positions(i).y := branch_positions(i).y + 20;
                    end loop;

                    if trophy_position.x < 666 and trophy_position.y < 666 then
                        trophy_position.y := trophy_position.y + 20;
                    end if;
                end if;

                score <= score_variable;
            end if;
        end if;
    end process;

    -- Control game time process
    process (CLOCK_24, RESET_N)
        variable flag_key : bit := '0';
        variable flag_rst : bit := '0';
        variable counter  : integer range 0 to 24000000 := 0;
    begin
        if RESET_N = '0' then
            flag_key := '0';
            flag_rst := '1';
            counter := 0;
            timer_game <= 8;
        elsif rising_edge(CLOCK_24) then
            if key(0) = '0' and flag_rst = '1' then
                flag_key := '1';
            end if;

            if flag_key = '1' then
                if eat_trophy = '1' then
                    timer_game <= timer_game + 20;
                end if;

                if player_moved = '1' then
                    timer_game <= timer_game + 1;
                end if;

                counter := counter + 1;
                if counter = 23999999 - ( (score / 20) * 4799999 ) then
                    counter := 0;

                    if end_game = '1' then
                        timer_game <= timer_game;
                    else
                        timer_game <= timer_game - 1; -- Add timer after 24000000 clk edge
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Switch between seven segments process
    process (CLOCK_24)
        variable counter : integer range 0 to 5000 := 0;
    begin
        if rising_edge(CLOCK_24) then
            counter := counter + 1;
            if counter = 4999 then
                counter := 0;
                seg_selectors <= seg_selectors(0) & seg_selectors(3 downto 1);
            end if;
        end if;
    end process;

    outseg <= seg_selectors;

    process (seg_selectors, seg0, seg1, seg2, seg3)
    begin
        case seg_selectors is
            when "1110" =>
                sevenSegments <= seg0;
            when "0111" =>
                sevenSegments <= seg3;
            when "1011" =>
                sevenSegments <= seg2;
            when "1101" =>
                sevenSegments <= seg1;
            when others =>
                sevenSegments <= x"c0";
        end case;
    end process;

    -- Control seven segments & LEDs process
    process (CLOCK_24, RESET_N)
        variable flag_key : bit := '0';

        -- Convert integer to seven segment output
        function SevenSegmentValue(Digit: integer) return bit_vector is
            variable SSOutput : bit_vector(7 downto 0) := x"C0";
        begin
            case Digit is
                when 0 =>
                    SSOutput := x"c0";
                when 1 =>
                    SSOutput := x"F9";
                when 2 =>
                    SSOutput := x"A4";
                when 3 =>
                    SSOutput := x"B0";
                when 4 =>
                    SSOutput := x"99";
                when 5 =>
                    SSOutput := x"92";
                when 6 =>
                    SSOutput := x"82";
                when 7 =>
                    SSOutput := x"F8";
                when 8 =>
                    SSOutput := x"80";
                when others =>
                    SSOutput := x"98";
            end case;
            return SSOutput;
        end function;

    begin
        if RESET_N = '0' then
            -- Initialize seven segment and LED values
            seg0 <= SevenSegmentValue(5);
            seg1 <= SevenSegmentValue(6);
            seg2 <= SevenSegmentValue(0);
            seg3 <= SevenSegmentValue(2);
            Leds <= "00000000";
            flag_key := '0';
        elsif rising_edge(CLOCK_24) then
            if Key(0) = '0' then
                flag_key := '1';
            end if;

            if flag_key = '1' then
                if end_game = '0' then
                    -- Show time and score on seven segments
                    seg1 <= SevenSegmentValue(timer_game mod 10);
                    seg0 <= SevenSegmentValue(timer_game / 10);
                    seg3 <= SevenSegmentValue(score mod 10);
                    seg2 <= SevenSegmentValue(score / 10);

                    -- Update LEDs based on the score
                    case (score / 20) is
                        when 0 =>
                            Leds <= "00000001";
                        when 1 =>
                            Leds <= "00000011";
                        when 2 =>
                            Leds <= "00000111";
                        when 3 =>
                            Leds <= "00001111";
                        when others =>
                            Leds <= "00000000";
                    end case;
                else
                    -- End game scenario
                    Leds <= (others => '1');
                    if score >= 80 then
                        seg0 <= x"92";
                        seg1 <= x"c1";
                        seg2 <= x"c6";
                        seg3 <= x"c6";
                    else
                        seg0 <= x"c7";
                        seg1 <= x"c0";
                        seg2 <= x"92";
                        seg3 <= x"86";
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- Determine if the game has ended
    process (timer_game, score, lose)
    begin
        end_game <= '0';
        if timer_game = 0 or score >= 80 or lose = '1' then
            end_game <= '1';
        end if;
    end process;

end LumberJack;
