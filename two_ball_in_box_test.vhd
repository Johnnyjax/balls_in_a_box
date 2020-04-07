library ieee;
use ieee.std_logic_1164.all;

entity two_ball_in_box_test is
	port(
		CLOCK_50 : in std_logic;
		KEY      : in std_logic_vector(0 downto 0);
		VGA_HS, VGA_VS : out std_logic;
		SW             : in std_logic_vector(1 downto 0);
		VGA_R, VGA_B, VGA_G : out std_logic_vector(2 downto 0)
	);
end two_ball_in_box_test;

architecture arch of two_ball_in_box_test is
	signal pixel_x, pixel_y : std_logic_vector(9 downto 0);
	signal video_on, pixel_tick : std_logic;
	signal rgb_reg, rgb_next : std_logic_vector(2 downto 0);
begin
	vga_sync_unit : entity work.vga_sync
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					video_on => video_on, p_tick => pixel_tick,
					hsync => VGA_HS, vsync => VGA_VS, 
					pixel_x => pixel_x, pixel_y => pixel_y);
	two_ball_in_a_box_unit : entity work.two_ball_in_box
		port map(clk => CLOCK_50, reset => not(KEY(0)),
					video_on => video_on, speed => SW,
					pixel_x => pixel_x, pixel_y => pixel_y, graph_rgb => rgb_next);
	process(CLOCK_50)
	begin
		if(CLOCK_50'event and CLOCK_50 = '1') then
			if(pixel_tick = '1') then
				rgb_reg <= rgb_next;
			end if;
		end if;
	end process;
	VGA_R <= (others => rgb_reg(2));
	VGA_G <= (others => rgb_reg(1));
	VGA_B <= (others => rgb_reg(0));
end arch;