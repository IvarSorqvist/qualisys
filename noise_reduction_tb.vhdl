library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- for reading test file
use STD.textio.all;
use ieee.STD_LOGIC_TEXTIO.all;

entity noise_reduction_tb is
end noise_reduction_tb;

architecture behaviourial of noise_reduction_tb is
component noise_reduction is
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
        --state           : out std_logic_vector(3 downto 0)
    );
end component;

signal tb_rst           : std_logic := '0'; --start as of
signal tb_clk           : std_logic := '0';
signal tb_image_width   : std_logic_vector(9 downto 0);
signal tb_image_height  : std_logic_vector(9 downto 0);
signal tb_valid_in      : std_logic;
signal tb_sof_in        : std_logic;
signal tb_eof_in        : std_logic;
signal tb_data_in       : std_logic_vector(63 downto 0);
signal tb_valid_out     : std_logic;
signal tb_sof_out       : std_logic;
signal tb_eof_out       : std_logic;
signal tb_data_out      : std_logic_vector(63 downto 0);
-- debugging
--signal tb_state         : std_logic_vector(3 downto 0);

file file_IMAGE : text;
--signal image_data       : std_logic_vector(63 downto 0) := X"FFFFFFFFFFFFFFFF";

-- Convert std_logic_vector to string, for debugging
function to_hstring (SLV : std_logic_vector) return string is
    variable L : LINE;
  begin
    hwrite(L,SLV);
    return L.all;
end function to_hstring;

-- Convert string char to std_logic_vector. 
-- Used for reading input file
FUNCTION hexchar2bin (hex: character) RETURN std_logic_vector IS
VARIABLE result : std_logic_vector (3 downto 0);
BEGIN
CASE hex IS
    WHEN '0' =>     result := "0000";
    WHEN '1' =>     result := "0001";
    WHEN '2' =>     result := "0010";
    WHEN '3' =>     result := "0011";
    WHEN '4' =>     result := "0100";
    WHEN '5' =>     result := "0101";
    WHEN '6' =>     result := "0110";
    WHEN '7' =>     result := "0111";
    WHEN '8' =>     result := "1000";
    WHEN '9' =>     result := "1001";
    WHEN 'A'|'a' => result := "1010";
    WHEN 'B'|'b' => result := "1011";
    WHEN 'C'|'c' => result := "1100";
    WHEN 'D'|'d' => result := "1101";
    WHEN 'E'|'e' => result := "1110";
    WHEN 'F'|'f' => result := "1111";
    WHEN 'X'|'x' => result := "XXXX";
    WHEN others =>  NULL;
END CASE;
RETURN result;
END;

signal test_integer : integer;
signal test_std : std_logic_vector(7 downto 0) := x"FF";

begin

    UUT : component noise_reduction
        port map (
            rst             => tb_rst,
            clk             => tb_clk,
            image_width     => tb_image_width,
            image_height    => tb_image_height,
            valid_in        => tb_valid_in,
            sof_in          => tb_sof_in,
            eof_in          => tb_eof_in,
            data_in         => tb_data_in,
            valid_out       => tb_valid_out,
            sof_out         => tb_sof_out,
            eof_out         => tb_eof_out,
            data_out        => tb_data_out
        );

    
    tb_clk <= NOT tb_clk after 5 ns; -- 100 Mhz
    tb_rst <= '1' after 1 us;

    test_integer <= to_integer(unsigned(test_std));

    -- try on a 24 pixel x 24 pixel picture => 
    tb_image_height <= b"00" & x"18"; -- 24 pixels of each 1 byte
    tb_image_width <= b"00" & x"18"; -- 24 pixels

    read_in_file: process
        constant file_in_name   : string := "test_input.txt";
        file file_in_pointer    : text;
        variable line_content   : string(1 to 23); -- in line
        variable line_num       : line;
        variable filestatus     : file_open_status;

        variable start          : boolean := false;
    begin
        tb_data_in <= x"0000000000000000";
        wait until tb_rst = '1'; -- start first when rst says its okay

        file_open(filestatus, file_in_pointer, file_in_name, read_mode);
        report file_in_name & LF & HT & "file_open_status = " &
                            file_open_status'image(filestatus);
        while not endfile(file_in_pointer) loop
            wait until rising_edge(tb_clk); -- change once per clock
            readline(file_in_pointer, line_num);
            read(line_num, line_content);
            --report real'image(line_content);
            report line_content(1 to 23);
            tb_data_in(63 downto 0) <= hexchar2bin(line_content(1)) & hexchar2bin(line_content(2))
                    & hexchar2bin(line_content(4)) & hexchar2bin(line_content(5))
                    & hexchar2bin(line_content(7)) & hexchar2bin(line_content(8))
                    & hexchar2bin(line_content(10)) & hexchar2bin(line_content(11))
                    & hexchar2bin(line_content(13)) & hexchar2bin(line_content(14))
                    & hexchar2bin(line_content(16)) & hexchar2bin(line_content(17))
                    & hexchar2bin(line_content(19)) & hexchar2bin(line_content(20))
                    & hexchar2bin(line_content(22)) & hexchar2bin(line_content(23))
                    ;

            if not start then
                tb_sof_in <= '1'; -- first input
                start := true;
            end if;
            tb_valid_in <= '1'; -- Valid input

            assert tb_sof_out = '0' report "SOF out = 1" severity WARNING;

            --report to_hstring(hexchar2bin(line_content(4)));
            report to_hstring(tb_data_in);
            report to_hstring(tb_data_out);
            --report "STATE: " & to_hstring(tb_state);
            --report image_data;



        end loop;
        file_close(file_in_pointer);
        tb_eof_in <= '1'; -- Last line feeding into the NR_module

        wait for 1 us;
        report to_hstring(tb_data_in);

        wait for 100 ns;
        -- End test
        assert false report "END of test" severity FAILURE;
    end process read_in_file;

    

end architecture behaviourial;