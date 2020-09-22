/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

// This is the top module
// It performs debouncing on the push buttons using a 1kHz clock, and a 10-bit shift register
// When PB0 is pressed, it will stop/start the counter
module experiment5 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[7:0], // 8 seven segment displays		
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

parameter	MAX_1kHz_div_count = 24999,
		MAX_1Hz_div_count = 24999999;

logic resetn;
assign resetn = ~SWITCH_I[17];
logic [15:0] clock_1kHz_div_count;
logic clock_1kHz, clock_1kHz_buf;

logic [24:0] clock_1Hz_div_count;
logic clock_1Hz, clock_1Hz_buf;

logic [9:0] debounce_shift_reg [3:0];
logic [3:0] push_button_status, push_button_status_buf;


logic [7:0] counter;
logic [6:0] value_7_segment0, value_7_segment1;
logic stop_count;
logic up_count;
logic down_count; 
logic flag = 1'b0;

logic s_count;
logic d_count;
logic u_count;
logic pause0;
logic pause1;
logic pause2;
logic p0;
logic p1;
logic p2;
int out;
int tens;
int ones;
logic [3:0] value;
logic AND,OR,NAND,NOR,XOR;

always_comb begin//combinational logic control for green LEDs

	AND = &SWITCH_I[7:0];
	OR = |SWITCH_I[7:0];
	
	
	NOR = ~|SWITCH_I[15:8];
	NAND = ~&SWITCH_I[15:8];
	
	XOR = ^SWITCH_I[15:0];

	//priority encoder checking for Least signifigant active low switch
	
	
	if (SWITCH_I[0] == 1'b0) begin//if the first switch is off, set value = 0 etc...
		value = 4'b0000;
		
	end else begin
		if (SWITCH_I[1] == 1'b0) begin
			value = 4'b0001;
			
		end else begin
			if (SWITCH_I[2] == 1'b0) begin
				value = 4'b0010;
				
			end else begin
				if (SWITCH_I[3] == 1'b0) begin
					value = 4'b0011;
					
				end else begin
					if (SWITCH_I[4] == 1'b0) begin
						value = 4'b0100;
						
					end else begin
						if (SWITCH_I[5] == 1'b0) begin
							value = 4'b0101;
																	
						end else begin
							if(SWITCH_I[6] == 1'b0) begin
							value = 4'b0110;
							
						end else begin
							if (SWITCH_I[7] == 1'b0) begin
								value = 4'b0111;
								
							end else begin
								if (SWITCH_I[8] == 1'b0) begin
									value = 4'b1000;
									
								end else begin
									if (SWITCH_I[9] == 1'b0) begin
										value = 4'b1001;
										
									end else begin
										if (SWITCH_I[10] == 1'b0) begin
											value = 4'b1010;
											
										end else begin
											if (SWITCH_I[11] == 1'b0) begin
												value = 4'b1011;
												
											end else begin
												if (SWITCH_I[12] == 1'b0) begin
													value = 4'b1100;
													
												end else begin
													if (SWITCH_I[13] == 1'b0) begin
														value = 4'b1101;
														
													end else begin
														if (SWITCH_I[14] == 1'b0) begin
															value = 4'b1110;
															
														end else begin
															if (SWITCH_I[15] == 1'b0) begin
																value = 4'b1111;
																
															end else begin
																
																value = 4'b0000;
															end
														end
													end
												end
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end
end


end

assign LED_GREEN_O = {value, XOR, NAND, NOR, OR, AND};

// Clock division for 1kHz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_div_count <= 16'd0;
	end else begin
		if (clock_1kHz_div_count < MAX_1kHz_div_count) begin
			clock_1kHz_div_count <= clock_1kHz_div_count + 16'd1;
		end else 
			clock_1kHz_div_count <= 16'd0;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz <= 1'b1;
	end else begin
		if (clock_1kHz_div_count == 16'd0) 
			clock_1kHz <= ~clock_1kHz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_buf <= 1'b1;	
	end else begin
		clock_1kHz_buf <= clock_1kHz;
	end
end

// Clock division for 1Hz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz_div_count <= 25'd0;
	end else begin
		if (clock_1Hz_div_count < MAX_1Hz_div_count) begin
			clock_1Hz_div_count <= clock_1Hz_div_count + 25'd1;
		end else 
			clock_1Hz_div_count <= 25'd0;		
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz <= 1'b1;
	end else begin
		if (clock_1Hz_div_count == 25'd0) 
			clock_1Hz <= ~clock_1Hz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz_buf <= 1'b1;	
	end else begin
		clock_1Hz_buf <= clock_1Hz;
	end
end

// Shift register for debouncing
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		debounce_shift_reg[0] <= 10'd0;
		debounce_shift_reg[1] <= 10'd0;
		debounce_shift_reg[2] <= 10'd0;
		debounce_shift_reg[3] <= 10'd0;						
	end else begin
		if (clock_1kHz_buf == 1'b0 && clock_1kHz == 1'b1) begin
			debounce_shift_reg[0] <= {debounce_shift_reg[0][8:0], ~PUSH_BUTTON_N_I[0]};
			debounce_shift_reg[1] <= {debounce_shift_reg[1][8:0], ~PUSH_BUTTON_N_I[1]};
			debounce_shift_reg[2] <= {debounce_shift_reg[2][8:0], ~PUSH_BUTTON_N_I[2]};
			debounce_shift_reg[3] <= {debounce_shift_reg[3][8:0], ~PUSH_BUTTON_N_I[3]};
		end
	end
end

// push_button_status will contained the debounced signal
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		push_button_status <= 4'h0;
		push_button_status_buf <= 4'h0;
	end else begin
		push_button_status_buf <= push_button_status;
		push_button_status[0] <= |debounce_shift_reg[0];
		push_button_status[1] <= |debounce_shift_reg[1];
		push_button_status[2] <= |debounce_shift_reg[2];
		push_button_status[3] <= |debounce_shift_reg[3];						
	end
end

// Push button status is checked here for controlling the counter
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		
		stop_count <= 1'b0;
		up_count <= 1'b1;
		down_count <= 1'b0;
		p0 <= 1'b0;
		p1 <= 1'b0;
		p2 <= 1'b0;
	end else begin
		
			
			if(stop_count != s_count && p0 == 1'b1) begin
				stop_count <= stop_count;
				p0 <= 1'b0;
			end else begin
				stop_count <= s_count;
			end
			if(up_count != u_count && p1 == 1'b1) begin
				up_count <= up_count;
				p1 <= 1'b0;
			end else begin
				up_count <= u_count;
			end
			if(down_count != d_count && p2 == 1'b1) begin
				down_count <= down_count;
				p2 <= 1'b0;
			end else begin
				down_count <= d_count;
			end
				
			
		
		if (push_button_status_buf[0] == 1'b0 && push_button_status[0] == 1'b1) begin	
				stop_count <= ~stop_count;
				p0 <= 1'b1;
		end
		
		if (push_button_status_buf[1] == 1'b0 && push_button_status[1] == 1'b1 && s_count == 1'b0) begin
			up_count <= 1'b1;
			down_count <= 1'b0;
			p1 <= 1'b1;
			p2 <= 1'b1;
		end
					
		if (push_button_status_buf[2] == 1'b0 && push_button_status[2] == 1'b1 && s_count == 1'b0) begin
			down_count <= 1'b1;
			up_count <= 1'b0;
			p1 <= 1'b1;
			p2 <= 1'b1;
		end 
				
		if (push_button_status_buf[3] == 1'b0 && push_button_status[3] == 1'b1) begin
		end
		
				
	end
end

// Counter is incremented here, ****1s real time == 10us simulation time****
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		counter <= 8'h00;
		u_count <= 1'b1;
		d_count <= 1'b0;
		s_count <= 1'b0;
		pause0 <= 1'b0;
		pause1 <= 1'b0;
		pause2 <= 1'b0;
		out <= 1'd0;
		tens <= 1'b0;
		ones <= 1'b0;
	end else begin
		
		if(stop_count != s_count && pause0 == 1'b1) begin
				s_count <= s_count;
				pause0 <= 1'b0;
			end else begin
				s_count <= stop_count;
			end
			if(up_count != u_count && pause1 == 1'b1) begin
				u_count <= u_count;
				pause1 <= 1'b0;
			end else begin
				u_count <= up_count;
			end
			if(down_count != d_count && pause2 == 1'b1) begin
				d_count <= d_count;
				pause2 <= 1'b0;
			end else begin
				d_count <= down_count;
		end
		
		if (clock_1Hz_buf == 1'b0 && clock_1Hz == 1'b1) begin		
				
				if(s_count == 1'b0) begin
				
					if(u_count == 1'b1) begin
					
						if(counter<8'd59) begin
							counter <= counter + 8'd1;//counts up until 59
							
						end else begin//once 59 is reached, swaps from counting up to counting down and waits for reset
							u_count <= 1'b0;
							d_count <= 1'b1;
							s_count <= 1'b1;
							pause0 <= 1'b1;
							pause1 <= 1'b1;
							pause2 <= 1'b1;
						end
					end else if (d_count == 1'b1) begin
					
						if(counter>8'd00) begin
							counter <= counter - 8'd1;//counts up until 59
							
						end else begin//once 59 is reached, swaps from counting up to counting down and waits for reset
							u_count <= 1;
							d_count <= 0;
							s_count <= 1'b1;
							pause0 <= 1'b1;
							pause1 <= 1'b1;
							pause2 <= 1'b1;
						end
				
				end
			end
		end
		out <= counter[7:0];
		ones <= out%10;
		tens <= out/10;
		
	end
end

// Instantiate modules for converting hex number to 7-bit value for the 7-segment display
convert_hex_to_seven_segment unit0 (
	.hex_value(ones), 
	.converted_value(value_7_segment0)
);

convert_hex_to_seven_segment unit1 (
	.hex_value(tens), 
	.converted_value(value_7_segment1)
);

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment0,
		SEVEN_SEGMENT_N_O[1] = value_7_segment1,
		SEVEN_SEGMENT_N_O[2] = 7'h7f,
		SEVEN_SEGMENT_N_O[3] = 7'h7f,
		SEVEN_SEGMENT_N_O[4] = 7'h7f,
		SEVEN_SEGMENT_N_O[5] = 7'h7f,
		SEVEN_SEGMENT_N_O[6] = 7'h7f,
		SEVEN_SEGMENT_N_O[7] = 7'h7f;



endmodule