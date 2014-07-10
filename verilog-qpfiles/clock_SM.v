module clock_SM (clk, enable, reset, res_compare, tick, count, load, loaden);


input clk, reset, enable, loaden;
input[6:0] res_compare;
input[6:0] load;
output reg tick = 0;
output reg[6:0] count = 0;


always @(posedge clk, negedge reset)
begin
	if (~reset)
		begin
			count <= 7'd0;
			tick <= 1'b0;
		end
	else
		begin
			if (loaden)
				begin
						count <= load;
						tick <= 1'b0;
				end	
			else if (enable & !loaden)
			begin
				if (count == res_compare)
					begin
						count <= 7'd0;
						tick <= 1'b1;
					end
				else
					begin
						count <= count+7'd1;
						tick <= 1'b0;
					end
			end
			else tick <= 1'b0;
		end
end		
endmodule			
			