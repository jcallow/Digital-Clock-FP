module Clock (
	input wire CLOCK_50,
	input wire [9:0] SW,
	input wire [3:0] KEY,
	output wire [7:0] LEDG,
	output wire [9:0] LEDR,
	output wire [6:0] HEX7, HEX6, HEX5, HEX4, HEX3, HEX2, HEX1, HEX0,
	//SDram
	output [12:0] DRAM_ADDR,
	output [1:0] DRAM_BA,
	output DRAM_CAS_N, DRAM_RAS_N, DRAM_CLK,
	output DRAM_CKE, DRAM_CS_N, DRAM_WE_N,
	output [3:0] DRAM_DQM,
	inout [31:0] DRAM_DQ,
	// LCD
	inout [7:0] LCD_DATA,
	output LCD_RS, LCD_RW, LCD_EN
	//
);

wire [14:0] clock_set;
wire [13:0] clock_get;



CPU_Final_Project nios_cpu_unit(
	.clk_clk(CLOCK_50), 
	.reset_reset_n(1'b1),
	.btn_external_connection_export(KEY),
	.ledg_external_connection_export(LEDG),
	.ledr_external_connection_export(LEDR),
	.switch_external_connection_export(SW),
	//sdram
	.sram_wire_addr(DRAM_ADDR),
	.sram_wire_ba(DRAM_BA),
	.sram_wire_cas_n(DRAM_CAS_N),
	.sram_wire_cke(DRAM_CKE),
	.sram_wire_cs_n(DRAM_CS_N),
	.sram_wire_dq(DRAM_DQ),
	.sram_wire_dqm(DRAM_DQM),
	.sram_wire_ras_n(DRAM_RAS_N),
	.sram_wire_we_n(DRAM_WE_N),
	.sdram_clk_clk(DRAM_CLK),
	// LCD
	.lcd_16207_RS(LCD_RS),
	.lcd_16207_RW(LCD_RW),
	.lcd_16207_data(LCD_DATA),
	.lcd_16207_E(LCD_EN),
	// PIO
	.clock_set_ext_export(clock_set),
	.clock_get_ext_export(clock_get)
	);
	
	
	// connect to lab 3 clock hardware
	
Lab3 hexclock(
		.CLOCK_50(CLOCK_50),
		.KEY(KEY),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3),
		.HEX4(HEX4),
		.HEX5(HEX5),
		.HEX6(HEX6),
		.HEX7(HEX7),
		.out_minutes(clock_get[6:0]),
		.out_hours(clock_get[13:7]),
		.in_minutes(clock_set[6:0]),
		.in_hours(clock_set[13:7]),
		.load_enable(clock_set[14])
		);
	endmodule
	