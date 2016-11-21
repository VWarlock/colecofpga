-------------------------------------------------------------------[13.08.2016]
-- VGA
-------------------------------------------------------------------------------
-- Engineer: MVV <mvvproject@gmail.com>

library IEEE; 
	use IEEE.std_logic_1164.all; 
	use IEEE.std_logic_unsigned.all;
	use IEEE.numeric_std.all;
	
entity vga is
port (
	I_CLK		: in std_logic;
	I_CLK_VGA	: in std_logic;
	I_COLOR		: in std_logic_vector(3 downto 0);
	I_HCNT		: in std_logic_vector(8 downto 0);
	I_VCNT		: in std_logic_vector(8 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_COLOR		: out std_logic_vector(3 downto 0);
	O_HCNT		: out std_logic_vector(9 downto 0);
	O_VCNT		: out std_logic_vector(9 downto 0);
	O_H		: out std_logic_vector(9 downto 0);
	O_BLANK		: out std_logic);
end vga;

architecture rtl of vga is
	signal pixel_out		: std_logic_vector(3 downto 0);
	signal addr_rd			: std_logic_vector(15 downto 0);
	signal addr_wr			: std_logic_vector(15 downto 0);
	signal wren				: std_logic;
	signal picture			: std_logic;
	signal window_hcnt	: std_logic_vector(8 downto 0) := "000000000";
	signal hcnt				: std_logic_vector(9 downto 0) := "0000000000";
	signal h					: std_logic_vector(9 downto 0) := "0000000000";
	signal vcnt				: std_logic_vector(9 downto 0) := "0000000000";
	signal hsync			: std_logic;
	signal vsync			: std_logic;
	signal blank			: std_logic;

-- ModeLine "640x480@60Hz"  25,175  640  656  752  800 480 490 492 525 -HSync -VSync
	-- Horizontal Timing constants  
	constant h_pixels_across	: integer := 640 - 1;
	constant h_sync_on		: integer := 656 - 1;
	constant h_sync_off		: integer := 752 - 1;
	constant h_end_count		: integer := 800 - 1;
	-- Vertical Timing constants
	constant v_pixels_down		: integer := 480 - 1;
	constant v_sync_on		: integer := 490 - 1;
	constant v_sync_off		: integer := 492 - 1;
	constant v_end_count		: integer := 525 - 1;
	
begin
	
	altsram: entity work.framebuffer
	port map(
		clock_a		=> I_CLK,
		data_a		=> I_COLOR,
		address_a	=> addr_wr,
		wren_a		=> wren,
		q_a			=> open,
		--
		clock_b		=> I_CLK_VGA,
		data_b		=> (others => '0'),
		address_b	=> addr_rd,
		wren_b		=> '0',
		q_b			=> pixel_out
	);


	process (I_CLK_VGA)
	begin
		if I_CLK_VGA'event and I_CLK_VGA = '1' then
			if h = h_end_count then
				h <= (others => '0');
			else
				h <= h + 1;
			end if;
		
			if h = 7 then
				hcnt <= (others => '0');
			else
				hcnt <= hcnt + 1;
				if hcnt = 63 then
					window_hcnt <= (others => '0');
				else
					window_hcnt <= window_hcnt + 1;
				end if;
			end if;
			if hcnt = h_sync_on then
				if vcnt = v_end_count then
					vcnt <= (others => '0');
				else
					vcnt <= vcnt + 1;
				end if;
			end if;
		end if;
	end process;
	
	wren		<= '1' when (I_HCNT < 256) and (I_VCNT < 240) else '0';
	addr_wr	<= I_VCNT(7 downto 0) & I_HCNT(7 downto 0);
	addr_rd	<= vcnt(8 downto 1) & window_hcnt(8 downto 1);
	blank		<= '1' when (hcnt > h_pixels_across) or (vcnt > v_pixels_down) else '0';
	picture	<= '1' when (blank = '0') and (hcnt > 64 and hcnt < 576) else '0';

	O_HSYNC	<= '1' when (hcnt <= h_sync_on) or (hcnt > h_sync_off) else '0';
	O_VSYNC	<= '1' when (vcnt <= v_sync_on) or (vcnt > v_sync_off) else '0';
	O_COLOR	<= pixel_out when picture = '1' else (others => '0');
	O_BLANK	<= blank;
	O_HCNT	<= hcnt;
	O_VCNT	<= vcnt;
	O_H		<= h;
	
end rtl;
