module Button_Debounce (Button, clk, output_tick);

input wire clk, Button;
output reg output_tick = 1'b0;

localparam[1:0] 	init = 2'b00,
						pressed = 2'b01,
						wait_pressed = 2'b10,
						wait_released = 2'b11;
						
reg [1:0] state_reg, state_next;
reg [21:0] countdown;

always @(posedge clk)
	begin
		case (state_reg)
		
			init:
				begin
					output_tick <= 1'b0;
					if (!Button)
						state_reg <= pressed;
					else if (Button)
						state_reg <= init;
				end
				
			pressed:
				begin
					output_tick <= 1'b1;
					state_reg <= wait_pressed;
				end
				
			wait_pressed:
				begin
					output_tick <= 1'b0;
					countdown <= 22'd75000;
					if (!Button)
						state_reg <= wait_pressed;
					else if (Button)
						state_reg <= wait_released;
				end
				
			wait_released:
				begin
					countdown <= countdown - 1;
					if (!Button)
						state_reg <= wait_pressed;
					else if (Button && countdown)
						state_reg <= wait_released;
					else if (Button && !countdown)
						state_reg <= init;
				end
				
			default:
				begin
					countdown <= 22'd0;
					output_tick <= 1'b0;
					state_reg <= init;
				end
		endcase
	end
endmodule
						