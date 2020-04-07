library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity two_ball_in_box is
	port(
		clk, reset : std_logic;
		video_on : in std_logic;
		speed    : in std_logic_vector(1 downto 0);
		pixel_x, pixel_y : in std_logic_vector(9 downto 0);
		graph_rgb : out std_logic_vector(2 downto 0)
	);
end two_ball_in_box;

architecture arch of two_ball_in_box is
	signal refr_tick, sq_ball1_on, sq_ball2_on, flash_on : std_logic;
	signal pix_x, pix_y : unsigned(9 downto 0);
	signal screen_on : std_logic;
	
	constant MAX_X : integer := 640;
	constant MAX_Y : integer := 480;
	constant SCREEN_SIZE : integer := 256;
	
	constant SCREEN_LEFT : integer := MAX_X/2 - SCREEN_SIZE/2;
	constant SCREEN_RIGHT : integer := MAX_X/2 + SCREEN_SIZE/2;
	constant SCREEN_TOP : integer := MAX_Y/2 - SCREEN_SIZE/2;
	constant SCREEN_BOTTOM : integer := MAX_Y/2 + SCREEN_SIZE/2;
	
	constant BALL_SIZE : integer:= 8;
	
	signal ball1_x_l, ball1_x_r : unsigned(9 downto 0);
	signal ball1_y_t, ball1_y_b : unsigned(9 downto 0);
	signal ball1_x_reg, ball1_x_next : unsigned(9 downto 0) := "0101000000";
	signal ball1_y_reg, ball1_y_next : unsigned(9 downto 0) := "0011001000";
	signal x_delta1_reg, x_delta1_next : unsigned(9 downto 0);
	signal y_delta1_reg, y_delta1_next : unsigned(9 downto 0);
	
	signal rom1_addr, rom1_col : unsigned(2 downto 0);
	signal rom1_data: std_logic_vector(7 downto 0);
	signal rom1_bit : std_logic;
	
	
	signal ball2_x_l, ball2_x_r : unsigned(9 downto 0);
	signal ball2_y_t, ball2_y_b : unsigned(9 downto 0);
	signal ball2_x_reg, ball2_x_next : unsigned(9 downto 0) := "0011110011";
	signal ball2_y_reg, ball2_y_next : unsigned(9 downto 0) := "0000111110";
	signal x_delta2_reg, x_delta2_next : unsigned(9 downto 0);
	signal y_delta2_reg, y_delta2_next : unsigned(9 downto 0);
	
	signal rom2_addr, rom2_col : unsigned(2 downto 0);
	signal rom2_data: std_logic_vector(7 downto 0);
	signal rom2_bit : std_logic;
	
	signal BALL_V_P : unsigned(9 downto 0) := to_unsigned(2, 10);
	signal BALL_V_N : unsigned(9 downto 0) := to_unsigned(-2, 10);
	
	type rom1_type is array(0 to 7) of std_logic_vector(0 to 7);
	constant BALL_ROM1 : rom1_type := 
		(
			"00111100",
			"01111110",
			"11111111",
			"11111111",
			"11111111",
			"11111111",
			"01111110",
			"00111100"
		);
	type rom2_type is array(0 to 7) of std_logic_vector(0 to 7);
	constant BALL_ROM2 : rom2_type := 
		(
			"00111100",
			"01111110",
			"11111111",
			"11111111",
			"11111111",
			"11111111",
			"01111110",
			"00111100"
		);

	signal rd_ball1_on, rd_ball2_on : std_logic;
	signal ball_rgb : std_logic_vector(2 downto 0);
begin
	with speed select
		BALL_V_P <= to_unsigned(2, 10) when "00",
						to_unsigned(4, 10) when "01",
						to_unsigned(6, 10) when "10",
						to_unsigned(8, 10) when others;
	with speed select
		BALL_V_N <= to_unsigned(-2, 10) when "00",
						to_unsigned(-4, 10) when "01",
						to_unsigned(-6, 10) when "10",
						to_unsigned(-8, 10) when others;
	process(clk, reset)
	begin
		if reset = '1' then
			ball1_x_reg <= "0101000000";
			ball1_y_reg <= "0011001000";
			x_delta1_reg <= to_unsigned(2, 10);
			y_delta1_reg <= to_unsigned(2, 10);
			ball2_x_reg <= "0011110011";
			ball2_y_reg <= "0000111110";
			x_delta2_reg <= to_unsigned(2, 10);
			y_delta2_reg <= to_unsigned(2, 10);
		elsif(clk'event and clk = '1') then
			ball1_x_reg <= ball1_x_next;
			ball1_y_reg <= ball1_y_next;
			x_delta1_reg <= x_delta1_next;
			y_delta1_reg <= y_delta1_next;
			ball2_x_reg <= ball2_x_next;
			ball2_y_reg <= ball2_y_next;
			x_delta2_reg <= x_delta2_next;
			y_delta2_reg <= y_delta2_next;
		end if;
	end process;
	
	pix_x <= unsigned(pixel_x);
	pix_y <= unsigned(pixel_y);
	
	refr_tick <= '1' when (pix_y = 481) and (pix_x = 0) else
					 '0';
	
	screen_on <= '1' when (SCREEN_LEFT <= pix_x) and (pix_x <= SCREEN_RIGHT) and
								 (SCREEN_TOP <= pix_y) and (pix_y <= SCREEN_BOTTOM) else
					 '0';
					 
	ball1_x_l <= ball1_x_reg;
	ball1_y_t <= ball1_y_reg;
	ball1_x_r <= ball1_x_l + BALL_SIZE-1;
	ball1_y_b <= ball1_y_t + BALL_SIZE-1;
	
	ball2_x_l <= ball2_x_reg;
	ball2_y_t <= ball2_y_reg;
	ball2_x_r <= ball2_x_l + BALL_SIZE-1;
	ball2_y_b <= ball2_y_t + BALL_SIZE-1;
	
	
	
	sq_ball1_on <= 
		'1' when (ball1_x_l <= pix_x) and (pix_x <= ball1_x_r) and	
					 (ball1_y_t <= pix_y) and (pix_y <= ball1_y_b) else
		'0';

	sq_ball2_on <= 
		'1' when (ball2_x_l <= pix_x) and (pix_x <= ball2_x_r) and	
					 (ball2_y_t <= pix_y) and (pix_y <= ball2_y_b) else
		'0';	
	
	rom1_addr <= pix_y(2 downto 0) - ball1_y_t(2 downto 0);
	rom1_col <= pix_x(2 downto 0) - ball1_x_l(2 downto 0);
	rom1_data <= BALL_ROM1(to_integer(rom1_addr));
	rom1_bit <= rom1_data(to_integer(rom1_col));
	
	rom2_addr <= pix_y(2 downto 0) - ball2_y_t(2 downto 0);
	rom2_col <= pix_x(2 downto 0) - ball2_x_l(2 downto 0);
	rom2_data <= BALL_ROM2(to_integer(rom2_addr));
	rom2_bit <= rom2_data(to_integer(rom2_col));
	
	rd_ball1_on <= 
		'1' when (sq_ball1_on = '1') and (rom1_bit = '1') else
		'0';
		
	rd_ball2_on <= 
		'1' when (sq_ball2_on = '1') and (rom2_bit = '1') else
		'0';
	
	ball_rgb <= "100";
	
	ball1_x_next <= ball1_x_reg + x_delta1_reg
							when refr_tick = '1' else
						ball1_x_reg;
	ball1_y_next <= ball1_y_reg + y_delta1_reg
							when refr_tick = '1' else
						ball1_y_reg;
						
	ball2_x_next <= ball2_x_reg + x_delta2_reg
							when refr_tick = '1' else
						ball2_x_reg;
	ball2_y_next <= ball2_y_reg + y_delta2_reg
							when refr_tick = '1' else
						ball2_y_reg;
						
	process(x_delta1_reg, y_delta1_reg, ball1_y_t, ball1_x_l, ball1_x_r,
			 ball1_y_b, ball2_y_t, ball2_x_l, ball2_x_r, ball2_y_b)
	begin
		x_delta1_next <= x_delta1_reg;
		y_delta1_next <= y_delta1_reg;
		if ball1_y_t < SCREEN_TOP + 1 then
			y_delta1_next <= BALL_V_P;
		elsif ball1_y_b > SCREEN_BOTTOM-1 then
			y_delta1_next <= BALL_V_N;
		elsif ball1_x_l < SCREEN_LEFT then
			x_delta1_next <= BALL_V_P;
		elsif ball1_x_r > SCREEN_RIGHT then
			x_delta1_next <= BALL_V_N;
		elsif ball1_x_l <= ball2_x_r and ball2_x_r <= ball1_x_r then
			if(ball1_y_t <= ball2_y_b) and ball2_y_t <= ball1_y_b then
				x_delta1_next <= BALL_V_P;
			end if;
		elsif ball2_x_l <= ball1_x_r and ball1_x_r <= ball2_x_r then
			if(ball1_y_t <= ball2_y_b) and ball2_y_t <= ball1_y_b then
				x_delta1_next <= BALL_V_N;
			end if;
		end if;
	end process;
	
	process(x_delta2_reg, y_delta2_reg, ball2_y_t, ball2_x_l, ball2_x_r,
			  ball2_y_b, ball1_y_t, ball1_x_l, ball1_x_r,ball1_y_b )
	begin
		x_delta2_next <= x_delta2_reg;
		y_delta2_next <= y_delta2_reg;
		if ball2_y_t < SCREEN_TOP + 1 then
			y_delta2_next <= BALL_V_P;
		elsif ball2_y_b > SCREEN_BOTTOM-1 then
			y_delta2_next <= BALL_V_N;
		elsif ball2_x_l < SCREEN_LEFT then
			x_delta2_next <= BALL_V_P;
		elsif ball2_x_r > SCREEN_RIGHT then
			x_delta2_next <= BALL_V_N;
		elsif ball1_x_l <= ball2_x_r and ball2_x_r <= ball1_x_r then
			if(ball1_y_t <= ball2_y_b) and ball2_y_t <= ball1_y_b then
				x_delta2_next <= BALL_V_N;
			end if;
		elsif ball2_x_l <= ball1_x_r and ball1_x_r <= ball2_x_r then
			if(ball1_y_t <= ball2_y_b) and ball2_y_t <= ball1_y_b then
				x_delta2_next <= BALL_V_P;
			end if;
		end if;
	end process;
	
	flash_on <= '1' when (ball1_y_t = SCREEN_TOP) or (ball1_y_b = SCREEN_BOTTOM-1) or
							   (ball1_x_l = SCREEN_LEFT) or (ball1_x_r = SCREEN_RIGHT- 1) or
								(ball2_y_t = SCREEN_TOP) or (ball2_y_b = SCREEN_BOTTOM-1) or
							   (ball2_x_l = SCREEN_LEFT) or (ball2_x_r = SCREEN_RIGHT- 1) else
				  '0';
	
	process(video_on, screen_on, rd_ball1_on, rd_ball2_on, flash_on)
	begin
		if video_on = '0' then
			graph_rgb <= "000";
		else
			if rd_ball1_on = '1'  then
				graph_rgb <= "100";
			elsif flash_on = '1' then
				graph_rgb <= "010";
			elsif screen_on = '1' then
				graph_rgb <= "111";
			else
				graph_rgb <= "000";
			end if;
			if rd_ball2_on = '1'  then
				graph_rgb <= "001";
			end if;
		end if;
	end process;
end arch;