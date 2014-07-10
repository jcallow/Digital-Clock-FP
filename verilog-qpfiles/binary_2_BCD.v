module binary_2_BCD (clk, reset, start, bin, done_tick, bcd1, bcd2);

input wire clk, reset;
input wire start;
input wire [6:0] bin;
output reg done_tick;
output wire [3:0] bcd1, bcd2;

localparam[1:0]	idle	= 2'b00,				   // give my states labels that are easier to follow than binary numbers.
						op		= 2'b01,
						done	= 2'b10;
						
						
reg [1:0] state_reg, state_next;
reg[6:0] bin_reg, bin_next;
reg[2:0] n_reg, n_next;
reg[3:0] bcd1_reg, bcd2_reg;
reg[3:0] bcd1_next, bcd2_next;
wire[3:0] bcd1_tmp, bcd2_tmp;


always @(posedge clk, negedge reset)
	if (~reset)
		begin
			state_reg = idle;			 // resets all values and sets state back to idle
			bin_reg <=0;
			n_reg <=0;
			bcd1_reg <= 0;
			bcd2_reg <= 0;
		end
	else
		begin
			state_reg <= state_next;			//  assigns new values/states on each clock tick.  
			bin_reg <= bin_next;
			n_reg <= n_next;
			bcd1_reg <= bcd1_next;
			bcd2_reg <= bcd2_next;
		end
		
always @*
begin											// begin describing how the state machine behaves.
	state_next = state_reg;						
	done_tick = 1'b0;
	bin_next = bin_reg;
	bcd1_next = bcd1_reg;
	bcd2_next = bcd2_reg;
	n_next = n_reg;
	
	case (state_reg)
		idle:
			begin
				done_tick = 1'b0;
				if (start)
					begin
						state_next = op;
						bcd1_next = 0;						  // waits for start, always on in my circuit.
						bcd2_next = 0;
						n_next = 3'b111;
						bin_next = bin;
					end
			end
		op:
			begin
				bin_next = bin_reg << 1;
				bcd1_next = {bcd1_tmp[2:0], bin_reg[6]};
				bcd2_next = {bcd2_tmp[2:0], bcd1_tmp[3]};			  // Begins shifting in bits for BCD conversion.  counts down with n_next to tell it when to stop.  
				n_next = n_reg - 3'd1;
				if (n_next==0)
					state_next = done;
			end
		done:
			begin
				done_tick = 1'b1;
				state_next = idle;
			end
		default: state_next = idle;
	endcase
end

// data path function units
assign bcd1_tmp = (bcd1_reg > 4'd4) ? bcd1_reg+4'd3 : bcd1_reg;				// The operations done during the op (convert) state.  If after shift in the value is >4 then add 3 before the next shift in
assign bcd2_tmp = (bcd2_reg > 4'd4) ? bcd2_reg+4'd3 : bcd2_reg;				// otherwise just prepare for next bit to be shifted in.

// output
assign bcd1 = bcd1_reg;			  // continuosly outputs the current value, even while converting.  This is why a done tick is needed.  Whatever I'm sending to, I only want it
assign bcd2 = bcd2_reg;			  // to load the bcd values when conversion is done.

endmodule
			
			