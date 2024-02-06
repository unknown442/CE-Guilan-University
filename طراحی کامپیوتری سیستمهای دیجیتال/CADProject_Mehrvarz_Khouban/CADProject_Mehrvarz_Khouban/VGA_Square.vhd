library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity VGA_Square is
  port ( CLK_24MHz		: in std_logic;
			RESET				: in std_logic;
			BtnUp          : in std_logic_vector(3 downto 0);  --use Key(0) to BtnUP
			end_game       : in bit;
			score          : out integer;
			lose           : out bit;
			ColorOut			: out std_logic_vector(5 downto 0); -- RED & GREEN & BLUE
			SQUAREWIDTH		: in std_logic_vector(7 downto 0);
			ScanlineX		: in std_logic_vector(10 downto 0);
			ScanlineY		: in std_logic_vector(10 downto 0)
  );
end VGA_Square;

architecture Behavioral of VGA_Square is
  
  signal ColorOutput: std_logic_vector(5 downto 0);
  signal SquareX: std_logic_vector(9 downto 0):="1111111111";  
  signal SquareY: std_logic_vector(9 downto 0):="1111111111";  
  signal SquareXMoveDir, SquareYMoveDir: std_logic := '0';
  --constant SquareWidth: std_logic_vector(4 downto 0) := "11001";
  constant SquareXmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareXmax: std_logic_vector(9 downto 0); -- := "1010000000"-SquareWidth;
  constant SquareYmin: std_logic_vector(9 downto 0) := "0000000001";
  signal SquareYmax: std_logic_vector(9 downto 0); -- := "0111100000"-SquareWidth;
  signal ColorSelect: std_logic_vector(2 downto 0) := "001";
  signal Prescaler: std_logic_vector(30 downto 0); 
  --location of wall first
  signal wallX1: std_logic_vector(9 downto 0):="1111111111";
  signal wallY1: std_logic_vector(9 downto 0):="1111111111";
  --location of wall second
  signal wallX2: std_logic_vector(9 downto 0):="1111111111";
  signal wallY2: std_logic_vector(9 downto 0):="1111111111";
  --use in random function 
  signal pseudo_rand: std_logic_vector(31 downto 0) :=(others => '0');
  signal p_rand1: std_logic_vector(9 downto 0);
  signal p_rand2: std_logic_vector(9 downto 0);
  signal score_signal: integer range 0 to 11 :=0;
  
begin
	 
   process(CLK_24MHz, RESET)
		-- maximal length 32-bit xnor LFSR
		function lfsr32(x : std_logic_vector(31 downto 0)) return std_logic_vector is
		begin
		return x(30 downto 0) & (x(0) xnor x(1) xnor x(21) xnor x(31));
		end function;
		variable flag_rst : bit :='0';
		variable flag_wall1 : bit := '0';
		variable flag_wall2 : bit := '0';
		begin
		if RESET='1' then
	    	pseudo_rand <= lfsr32(pseudo_rand);
	      p_rand1 <= "00"&pseudo_rand(7 downto 0);
	   	p_rand2 <= "00"&pseudo_rand(31 downto 24);
         flag_rst := '1';			
			flag_wall1 := '0';
			flag_wall2 := '0';
		elsif rising_edge(CLK_24MHz) then
		  if (end_game = '0') then
		  if(flag_rst = '1') then
		  if (flag_wall1 = '1') then
		   pseudo_rand <= lfsr32(pseudo_rand);
	      p_rand1 <= "00"&pseudo_rand(7 downto 0); -- generate random for first wall
			flag_wall1 := '0';
		  end if;
		  if (flag_wall2 = '1') then
		   pseudo_rand <= lfsr32(pseudo_rand);
	      p_rand2 <= "00"&pseudo_rand(31 downto 24);-- generate random for second wall
			flag_wall2 := '0';
		  end if;
		  end if;
		end if;
		if (wallX1+SquareWidth+SquareWidth = "0000000000" ) then
		   flag_wall1 := '1';
		end if;
		if (wallX2+SquareWidth+SquareWidth = "0000000000") then
		   flag_wall2 := '1';
		end if;
		end if;
		end process;
		
	square: process(CLK_24MHz, RESET)
	variable flag_btn : bit := '0';
	variable lock_key: integer range 0 to 3 :=2;
	variable timer_up_key : integer range 0 to 6 :=0;
	begin
	--initialization
		if RESET = '1' then
			Prescaler <= (others => '0');
			SquareX <= "0001111000";  
         SquareY <= "0011100000";
			flag_btn := '0';
			lock_key := 2;
			timer_up_key := 0;
		elsif rising_edge(CLK_24MHz) then
		   if (end_game = '0') then
			Prescaler <= Prescaler + 1;	 
			if Prescaler = "0111010100110000000" then  -- Activated every 0,01 sec
			--wall moves upward when player pushes button
			if(BtnUp(0) = '0') then  
			   flag_btn := '1';
				lock_key := 1;
			end if;
			
			
			if (lock_key = 1) then
			   timer_up_key := timer_up_key + 1;
			end if;
			
			if (timer_up_key = 5) then
			   timer_up_key := 0;
			   lock_key := 0;
		   end if;
			 
				if( lock_key = 1 )then
				   
					if SquareY > SquareYmin then
						SquareY <= SquareY - 1;
					
					else
				       SquareY <= SquareY;
					end if;
				elsif( lock_key = 0 and flag_btn = '1') then
					if SquareY < SquareYmax then
						SquareY <= SquareY + 1; -- in default square moves downward
					else
				      SquareY <= SquareY;
			   	end if;	 
		   end if;		  
				Prescaler <= (others => '0');
			end if;
			end if;
		end if;
	end process square; 

wall: process(CLK_24MHz, RESET)
   variable flag_btn : bit:= '0';
	variable time_wall :  std_logic_vector(20 downto 0):= "001110101001100000000";   --0.02s
	variable counter_15s : integer := 360000000;
	variable Prescaler_wall: std_logic_vector(26 downto 0):= (others => '0');
	begin
	--initialization
		if RESET = '1' then
			Prescaler_wall := (others => '0');
         flag_btn := '0';
			time_wall := "001110101001100000000";
         wallX1 <= "0111111000";
         wallY1 <= "0001110000";
			wallX2 <= "1111100000";
         wallY2 <= "0001110000";
		elsif rising_edge(CLK_24MHz) then
		if (end_game = '0') then
		if( BtnUp(0) = '0' )then
		    flag_btn := '1';
		end if;
		if(flag_btn = '1') then
			Prescaler_wall := Prescaler_wall + 1;
			if( counter_15s = 0 )then
				counter_15s := 360000000;--15 x 24MHz
				time_wall := time_wall - ('0' & time_wall(20 downto 1));-- this formula helps to move walls faster (every 15 second)
			end if;
			counter_15s := counter_15s - 1;
			
			if( Prescaler_wall = time_wall )then  -- Activated every time_wall sec, dynamic clock divider
				if(flag_btn = '1') then
					wallX1 <= wallX1 - 1;
					wallX2 <= wallX2 - 1;
			   end if;	 
				Prescaler_wall := (others => '0');
			end if;
		end if;
		end if;
		end if;
	end process wall;
	
	--this process detects conflict to walls
	process( CLK_24MHz, RESET)
	begin
	if RESET = '1' then
		lose <= '0';
	elsif( rising_edge(CLK_24MHz))then -- conflict to first wall
		if (((wallX1 <= SquareX+ SquareWidth AND wallX1 >= SquareX) OR (wallX1+ SquareWidth >= SquareX AND wallX1 <= SquareX))
			AND (SquareY <= p_rand1 OR SquareY + squareWidth >= p_rand1 + squareWidth+ squareWidth+ squareWidth+SquareWidth )) then
			lose <= '1';
		end if;
		--conflict to second wall
		if (((wallX2 <= SquareX+ SquareWidth AND wallX2 >= SquareX) OR (wallX2+ SquareWidth >= SquareX AND wallX2 <= SquareX))
			AND (SquareY <= p_rand2 OR SquareY + squareWidth >= p_rand2 + squareWidth+ squareWidth+ squareWidth+SquareWidth )) then
			lose <= '1';
		end if;
	end if;	
	end process;
	
	--flag_plus : 0-> initial state, 1 -> must increment score , 2 -> scre is incremented and we are in area after wall
	process(CLK_24MHz, RESET)
	variable flag_rst : bit:= '0';
	variable flag_plus1 : integer range 0 to 3 := 0;
	variable flag_plus2 : integer range 0 to 3:= 0;
	begin
	if(RESET = '1')then
		flag_rst := '1';
		score_signal <= 0;
		flag_plus1 := 0;
	   flag_plus2 := 0;
	elsif rising_edge(CLK_24MHz)then 
		if( flag_rst = '1') then 
		if( flag_plus1 = 1) then
			score_signal <= score_signal + 1;
			flag_plus1 := 2;
		end if;
		if( flag_plus2 = 1) then
			score_signal <= score_signal + 1;
			flag_plus2 := 2;
		end if;
		if( wallX1 + squareWidth < squareX  AND wallX2 > squareX AND flag_plus1 /= 2 )then
			flag_plus1 := 1;
		end if;
		if( wallX2 + squarewidth < squareX AND flag_plus2 /= 2 ) then
			flag_plus2 := 1;
		end if;
		if( wallX1+SquareWidth+SquareWidth = "0000000000" )then
			flag_plus1 := 0;
		end if;
		if( wallX2+SquareWidth+SquareWidth = "0000000000" )then
			flag_plus2 := 0;
		end if;
		end if;
	end if;
	end process;
	score <= score_signal;

   --display: 1.square, 2.perimeter, 3.first wall, 4.second wall, 5.background
	ColorOutput <=	   "000000" when  (ScanlineX=SquareX+7 and ScanlineY=SquareY+7) or (ScanlineX=SquareX+8 and  ScanlineY=SquareY+7) or (ScanlineX=SquareX+7 and  ScanlineY=SquareY+8) or (ScanlineX=SquareX+8 and  ScanlineY=SquareY+8)
					else  "000000" when  (ScanlineX=SquareX+SquareWidth-7 and ScanlineY=SquareY+7) or (ScanlineX=SquareX+SquareWidth-8 and  ScanlineY=SquareY+7) or (ScanlineX=SquareY+SquareWidth-7 and  ScanlineX=SquareY+8) or (ScanlineX=SquareY+SquareWidth-8 and  ScanlineX=SquareY+8)
					else  "000000" when   ScanlineY=SquareY+SquareWidth-7 and (ScanlineX>SquareX+7 and ScanlineX<SquareX+SquareWidth-7)
					else  "000000" when   (ScanlineX=SquareX+7 or ScanlineX=SquareX+SquareWidth-7) and (ScanlineY>SquareY+SquareWidth-12 and ScanlineY<SquareY+SquareWidth-7)	
	            else  "001100" when  (score_signal=0) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "110000" when  (score_signal=1) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "000011" when  (score_signal=2) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "110011" when  (score_signal=3) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "001111" when  (score_signal=4) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "001110" when  (score_signal=5) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "111011" when  (score_signal=6) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "001111" when  (score_signal=7) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "111100" when  (score_signal=8) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "110001" when  (score_signal=9) and (ScanlineX > SquareX AND ScanlineY > SquareY AND ScanlineX < SquareX+SquareWidth AND ScanlineY < SquareY+SquareWidth)
					else  "111111" when  (ScanlineX = SquareX AND ScanlineY > SquareY AND ScanlineY < SquareY+SquareWidth) OR (ScanlineY = SquareY AND ScanlineX > SquareX AND ScanlineX < SquareX+SquareWidth)
					OR (ScanlineX = SquareX+SquareWidth AND ScanlineY > SquareY AND ScanlineY < SquareY+SquareWidth) OR (ScanlineY = SquareY+SquareWidth AND ScanlineX > SquareX AND ScanlineX < SquareX+SquareWidth)
				   else  "111000" when  ScanlineX >= wallX1  AND ScanlineX < wallX1+SquareWidth AND (ScanlineY < p_rand1 OR ScanlineY > p_rand1+SquareWidth+SquareWidth+SquareWidth+SquareWidth)
					else  "111100" when  ScanlineX >= wallX2  AND ScanlineX < wallX2+SquareWidth AND (ScanlineY < p_rand2 OR ScanlineY > p_rand2+SquareWidth+SquareWidth+SquareWidth+SquareWidth)
					else  "000000" when  score_signal = 10
					else  "111111" when  (ScanlineY>"1111101" and ScanlineY<"10010110" and ScanlineX>"1100100" and ScanlineX<"10001100")
					or (ScanlineY>="10010110" and ScanlineY<="10101111"and ScanlineX>"1001011" and ScanlineX<"11001000")
					or (ScanlineY>"10101111" and ScanlineY<"11001000" and ScanlineX>"110010" and ScanlineX<"11111010")				
					or (ScanlineY> ("11001000") and ScanlineY< ("11100001") and ScanlineX>("100101100") and ScanlineX< ("101011110"))
					or (ScanlineY>=("11100001") and ScanlineY<=("11111010" )and ScanlineX>("100010011") and ScanlineX<("110010000"))
					or (ScanlineY> ("11111010") and ScanlineY< ("100010011") and ScanlineX> ("11111010") and ScanlineX<("111000010"))
					else	"000011";

	ColorOut <= ColorOutput;
	
	SquareXmax <= "1010000000"-SquareWidth; -- (640 - SquareWidth)
	SquareYmax <= "0111100000"-SquareWidth;	-- (480 - SquareWidth)
end Behavioral;
