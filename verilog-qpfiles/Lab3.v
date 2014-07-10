module Lab3 (CLOCK_50, KEY, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7, out_minutes, out_hours, in_minutes, in_hours, load_enable);

input CLOCK_50, load_enable;
input[3:0] KEY;

output[6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7;
output[6:0] out_minutes, out_hours;
input[6:0] in_minutes, in_hours;


wire[6:0] timer1 = 'd99;
wire[6:0] timer2 = 'd59;
wire[6:0] timer3 = 'd59;
wire[6:0] timer4 = 'd23;
wire[6:0] load_zero = 'd0;

wire clk_tick12, clk_tick23, clk_tick34, clk_tick4, clk_tickminutes, clk_tickhours;
wire done1, done2, done3, done4, done5, done6, done7, done8;
wire ms100_tick;

wire minute_buttonpress, hour_buttonpress;

wire[6:0] ms100, seconds, minutes, hours;
wire[3:0] BCD1, BCD2, BCD3, BCD4, BCD5, BCD6, BCD7, BCD8;



assign clk_tickminutes = clk_tick23 | minute_buttonpress;
assign clk_tickhours = clk_tick34 | hour_buttonpress;



// tick generator for enabling clock modules
ms100_tick clock1_enable(.clk(CLOCK_50), .reset(KEY), .tick(ms100_tick));

// Button debouncers to prevent a single press from registering mulitple times

Button_Debounce debounce_minutes(.Button(KEY[2]), .clk(CLOCK_50), .output_tick(minute_buttonpress));
Button_Debounce debounce_hours(.Button(KEY[3]), .clk(CLOCK_50), .output_tick(hour_buttonpress));

// counters with output on rollover or hitting .res_compare value.  Each output tick is connected to the enable of the next unit up.
// so after say 1000 ms the ms clock enables the second clock for one clock cycle, then 60 seconds ticks the minutes.
clock_SM clock1(.clk(CLOCK_50), .enable(ms100_tick), .reset(KEY[0]), .res_compare('d99), .tick(clk_tick12), .count(ms100), .load(load_zero), .loaden(load_enable));
clock_SM clock2(.clk(CLOCK_50), .enable(clk_tick12), .reset(KEY[0]), .res_compare('d59), .tick(clk_tick23), .count(seconds), .load(load_zero), .loaden(load_enable));
clock_SM clock3(.clk(CLOCK_50), .enable(clk_tickminutes), .reset(KEY[0]), .res_compare('d59), .tick(clk_tick34), .count(minutes), .load(in_minutes), .loaden(load_enable));
clock_SM clock4(.clk(CLOCK_50), .enable(clk_tickhours), .reset(KEY[0]), .res_compare('d23), .tick(clk_tick4), .count(hours), .load(in_hours), .loaden(load_enable));

assign out_minutes = minutes;
assign out_hours = hours;
// binary to bcd format using a slightly modified algorithm I found in FPGA Prototyping By Verilog Examples: Xilinx Spartan-3 Version (a book I've been reading
// recently). This algorithm is designed using a state chart and uses cases to represent the different states.  3 states, idle, convert, and finished.
// I set start to always be 1 so it continuously runs.
binary_2_BCD BCD_mili100(.clk(CLOCK_50), .reset(KEY[0]), .start(1'b1), .bin(ms100), .done_tick(done1), .bcd1(BCD1), .bcd2(BCD2));
binary_2_BCD BCD_seconds(.clk(CLOCK_50), .reset(KEY[0]), .start(1'b1), .bin(seconds), .done_tick(done2), .bcd1(BCD3), .bcd2(BCD4));
binary_2_BCD BCD_minutes(.clk(CLOCK_50), .reset(KEY[0]), .start(1'b1), .bin(minutes), .done_tick(done3), .bcd1(BCD5), .bcd2(BCD6));
binary_2_BCD BCD_hours(.clk(CLOCK_50), .reset(KEY[0]), .start(1'b1), .bin(hours), .done_tick(done4), .bcd1(BCD7), .bcd2(BCD8));

// with everything in BCD form I use a module for each of the eight displays.
seven_segdisplay dig1(.clk(CLOCK_50), .reset(KEY[0]), .load(done1), .bcd(BCD1), .hex(HEX0));
seven_segdisplay dig2(.clk(CLOCK_50), .reset(KEY[0]), .load(done1), .bcd(BCD2), .hex(HEX1));
seven_segdisplay dig3(.clk(CLOCK_50), .reset(KEY[0]), .load(done2), .bcd(BCD3), .hex(HEX2));
seven_segdisplay dig4(.clk(CLOCK_50), .reset(KEY[0]), .load(done2), .bcd(BCD4), .hex(HEX3));
seven_segdisplay dig5(.clk(CLOCK_50), .reset(KEY[0]), .load(done3), .bcd(BCD5), .hex(HEX4));
seven_segdisplay dig6(.clk(CLOCK_50), .reset(KEY[0]), .load(done3), .bcd(BCD6), .hex(HEX5));
seven_segdisplay dig7(.clk(CLOCK_50), .reset(KEY[0]), .load(done4), .bcd(BCD7), .hex(HEX6));
seven_segdisplay dig8(.clk(CLOCK_50), .reset(KEY[0]), .load(done4), .bcd(BCD8), .hex(HEX7));

endmodule

module ms100_tick (clk, reset, tick);

input clk, reset;
output reg tick;
reg[18:0] count;

localparam compare_val = 19'b1111010000100011111;

always @(posedge clk, negedge reset)
begin
	if (~reset) count = 19'b0;
	else
	begin
		if (count == compare_val)
		begin
			count <= 19'b0;
			tick <= 1'b1;
		end
		else
		begin
			count <= count + 19'b1;
			tick <= 1'b0;
		end
	end
end
endmodule