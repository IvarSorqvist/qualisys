library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Task:
-- Arrives row by row and start top left corner
-- Have a width and height. 
-- Remove salt and pepper noise from image

-- Solution:
-- Assuming width is dividable by 8 and describes number of pixels in 8 bit format
-- Assume that height and width is divisible by 8
-- Have a two values set to determine if to be considered as <salt, pepper, normal>
-- Average new value from the value closest to the right and left.
-- If edge => choose only value on opposite side.
-- If next value too are salt/pepper, take one more step

-- Another solution had been to save previous line and next line to make an avarage
-- of all the dots around the grain.
entity noise_reduction is
    port(
        rst         : in std_logic;
        clk         : in std_logic;
        -- settings
        image_width     : in std_logic_vector(9 downto 0);
        image_height    : in std_logic_vector(9 downto 0);
        -- input data
        valid_in        : in std_logic; -- '1' when data is valid
        sof_in          : in std_logic; -- '1' during first valid data in image
        eof_in          : in std_logic; -- '1' during last valid data in image
        data_in         : in std_logic_vector(63 downto 0); -- 8 pixel 8 bit each
        -- output data
        valid_out       : out std_logic; -- '1' when data is valid
        sof_out         : out std_logic; -- '1' during first valid data in image
        eof_out         : out std_logic; -- '1' during last valid data in image
        data_out        : out std_logic_vector(63 downto 0) -- 8 pixels

        -- debugging
        --state   : out std_logic_vector(3 downto 0)
    );
end noise_reduction;

architecture behaviourial of noise_reduction is
signal test : std_logic := '0';    
type state_NR_type is (wait_start, read_first_vector, read_vector, last_vec);
signal state_NR : state_NR_type := wait_start;

signal last_pixel_in_prev_x2_vector : std_logic_vector(7 downto 0); -- two lines ago
signal previous_vector : std_logic_vector(63 downto 0); -- FFs for prev line

type pixels_focus_type is array (9 downto 0) of std_logic_vector(7 downto 0);
signal pixels_focus : pixels_focus_type;
signal first_vector_in_line : std_logic_vector(1 downto 0);
signal last_vector_in_line : std_logic_vector(1 downto 0);
signal line_vector_count : integer;
signal column_count : integer;

-- debugging
signal pixel_left_signal : integer;
signal pixel_right_signal : integer;
signal pixel_filtered_signal : integer;
signal line_width_signal : integer;
signal line_vector_count_signal : integer;
--

begin

NR_state_process : process (clk)
-- variable first_vector_in_line : boolean := false;

variable width_count : integer := 0;
variable height_vount : integer := 0;

variable pixel_left : integer;
variable pixel_right : integer;
variable pixel_filtered : integer;

-- number of blocks with 8 pixels / line
-- assuming image_width % 8 = 0
variable line_width : integer; 
variable columns : integer;



begin
    if rst = '0' then -- Cannot start until rst is set to 1
        state_NR <= wait_start;
        --state <= x"0"; -- debug
    
    else 
        if rising_edge(clk) then
            case state_NR is
                when wait_start =>
                    sof_out <= '0';
                    eof_out <= '0';
                    valid_out <= '0';
                    
                    if sof_in = '1' and valid_in = '1' then
                        state_NR <= read_first_vector;
                        --state <= x"1"; --debug
                        previous_vector <= data_in;
                        width_count := width_count + 8;
                        first_vector_in_line <= b"10";
                        -- assuming more than 8 pixels
                        last_vector_in_line <= b"00";

                        -- calculate width and height
                        line_width := to_integer(unsigned(image_width)) / 8;
                        columns := to_integer(unsigned(image_height));
                        line_vector_count <= 1;
                        column_count <= 1;
                    else
                        first_vector_in_line <= b"00";
                    end if; -- else stay the same
                when read_first_vector =>
                    previous_vector <= data_in;
                    last_pixel_in_prev_x2_vector <= previous_vector(7 downto 0);
                    state_NR <= read_vector;
                    first_vector_in_line <= '0' & first_vector_in_line(1);
                    line_vector_count <= line_vector_count + 1;

                    --dedubbing
                    line_width_signal <= line_width;

                    -- vector to be compared next state
                    pixels_focus(8) <= previous_vector(63 downto 56);
                    pixels_focus(7) <= previous_vector(55 downto 48);
                    pixels_focus(6) <= previous_vector(47 downto 40);
                    pixels_focus(5) <= previous_vector(39 downto 32);
                    pixels_focus(4) <= previous_vector(31 downto 24);
                    pixels_focus(3) <= previous_vector(23 downto 16);
                    pixels_focus(2) <= previous_vector(15 downto 8);
                    pixels_focus(1) <= previous_vector(7 downto 0);
                    pixels_focus(0) <= data_in(63 downto 56);
                when read_vector =>
                    if column_count = columns and line_vector_count = line_width then
                        -- finish and wait for another one!
                        state_NR <= wait_start;
                        eof_out <= '1';
                    end if;

                    if line_vector_count = line_width then
                        first_vector_in_line <= '1' & first_vector_in_line(0);
                        line_vector_count <= 1;
                        column_count <= column_count + 1;
                    else
                        first_vector_in_line <= '0' & first_vector_in_line(1);
                        line_vector_count <= line_vector_count + 1;

                        
                    end if;
                    -- debugging
                    line_vector_count_signal <= line_vector_count;

                    previous_vector <= data_in;
                    last_pixel_in_prev_x2_vector <= previous_vector(7 downto 0);

                    -- vector to be compared next state
                    pixels_focus(9) <= last_pixel_in_prev_x2_vector;
                    pixels_focus(8) <= previous_vector(63 downto 56);
                    pixels_focus(7) <= previous_vector(55 downto 48);
                    pixels_focus(6) <= previous_vector(47 downto 40);
                    pixels_focus(5) <= previous_vector(39 downto 32);
                    pixels_focus(4) <= previous_vector(31 downto 24);
                    pixels_focus(3) <= previous_vector(23 downto 16);
                    pixels_focus(2) <= previous_vector(15 downto 8);
                    pixels_focus(1) <= previous_vector(7 downto 0);
                    pixels_focus(0) <= data_in(63 downto 56);
                    for i in 1 to 8 loop
                        -- eof_out <= '0';
                        if pixels_focus(i) >= x"F0" or pixels_focus(i) <= x"10" then
                            -- Check if pixel is "black" or "light" =>
                            -- filter
                            --eof_out <= '1'; -- debugging
                            --report "hello";
                            if first_vector_in_line(0) = '1' and i = 8 then -- highest index to the left
                                --report "hello1";
                                -- no pixels to the left when first vector in line => 
                                -- set to same as pixel to the right
                                data_out((i*8 - 1) downto (i-1)*8) <= pixels_focus(i-1);
                            elsif last_vector_in_line(0) = '1' and i = 1 then
                                --report "hello2";
                                -- no pixel to the right of when last vector in line =>
                                -- set to same pixel as to the left
                                data_out((i*8 + 7) downto i*8) <= pixels_focus(i+1);
                            else
                                --report "hello3";
                                -- filter the data by averaging with the two closest pixels
                                -- to the right and left
                                -- Always round of to lowest integer (20 + 21) / 2 = 40.5 => 40
                                pixel_left := to_integer(unsigned(pixels_focus(i-1)));
                                pixel_right := to_integer(unsigned(pixels_focus(i+1)));
                                pixel_filtered := (pixel_left + pixel_right) / 2;

                                -- debugging
                                pixel_left_signal <= pixel_left;
                                pixel_right_signal <= pixel_right;
                                pixel_filtered_signal <= pixel_filtered;
                                -- 

                                data_out(((i-1)*8 + 7) downto (i-1)*8) <= std_logic_vector(to_unsigned(pixel_filtered, 8));
                            end if; -- first, middle or last pixel in line
                        else 
                            -- If passing filter => keep same value
                            data_out(((i-1)*8 + 7) downto (i-1)*8) <= pixels_focus(i);
                        end if; -- pixels_focus(i) >= ...
                        valid_out <= '1';
                        if first_vector_in_line(0) = '1' then
                            sof_out <= '1';
                        else
                            sof_out <= '0';
                        end if;
                    end loop;

                when others => 
                    -- Should never happen
                    -- 0 all output
                    state_NR <= wait_start;
            end case; -- state_NR

        end if; -- rising edge clk
    end if; -- rst

end process NR_state_process;
end behaviourial;
