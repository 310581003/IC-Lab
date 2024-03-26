module CC(
	in_s0,
	in_s1, 
	in_s2, 
	in_s3, 
    in_s4, 
	in_s5,
    in_s6, 
	opt,
	a,
	b,
	out,
    s_id0,
    s_id1,
    s_id2,
    s_id3,
    s_id4,
    s_id5,
    s_id6
);
input [3:0]in_s0;
input [3:0]in_s1;
input [3:0]in_s2;
input [3:0]in_s3;
input [3:0]in_s4;
input [3:0]in_s5;
input [3:0]in_s6;
input [2:0] opt;
input [1:0] a;
input [2:0] b;

output reg [2:0] out;

output [2:0] s_id0;
output [2:0] s_id1;
output [2:0] s_id2;
output [2:0] s_id3;
output [2:0] s_id4;
output [2:0] s_id5;
output [2:0] s_id6;
//==================================================================
// reg & wire
//==================================================================
reg [3:0] initial_input [6:0];
//reg signed[8:0] all_input [6:0];
reg signed[4:0] all_input_extend [6:0];
//reg signed [3:0] all_input_signed [6:0];
//reg signed [3:0] input_signed_sort [6:0];
reg [2:0] id [6:0];
//reg signed[4:0] key;
//reg signed[4:0] key_2;
//reg signed[7:0] sum;
//reg signed[6:0] sum_2;
//reg [3:0] mean;
reg signed[7:0] passingscore;
//reg signed [4:0] passingscore_1;
reg signed [6:0] adjusts [6:0];
reg [2:0] no_pass;
//reg [2:0] pass;
reg signed [4:0] a_extend;
reg signed [4:0] b_extend;

integer nn,z,k;

wire signed[4:0]temp_val[24:0] ;
wire        [2:0]temp_id[24:0] ;
wire signed[4:0]result_val[6:0] ;
wire       [2:0]result_id[6:0] ;
//==================================================================
// design
//==================================================================

// Extend
always@(*)begin
	id [6] = 6;
	id [5] = 5;
	id [4] = 4;
	id [3] = 3;
	id [2] = 2;
	id [1] = 1;
	id [0] = 0;
	initial_input[6] = in_s6;
	initial_input[5] = in_s5;
	initial_input[4] = in_s4;
	initial_input[3] = in_s3;
	initial_input[2] = in_s2;
	initial_input[1] = in_s1;
	initial_input[0] = in_s0;
	case (opt[0])
		1'b0 : begin
			for(k=0;k<7;k=k+1)begin: extend1
				all_input_extend[k] = {1'b0,initial_input[k]};
				//all_input[k] = {1'b0,initial_input[k],id [k]};
			end
		end
		1'b1 : begin
			for(k=0;k<7;k=k+1)begin: extend2
				case(initial_input[k][3])
					1'b0 : begin
						all_input_extend[k] = {1'b0,initial_input[k]};
						//all_input[k] = {1'b0,initial_input[k],id [k]};
					end
					1'b1 : begin
						all_input_extend[k] = {1'b1,initial_input[k]};
						//all_input[k] = {1'b1,initial_input[k],id [k]};
					end
				endcase
			end
		end
	endcase
end


//mean
always@(*)begin
	a_extend=a;
	b_extend=b;
	passingscore= (all_input_extend[0]+all_input_extend[1]+all_input_extend[2]+all_input_extend[3]+all_input_extend[4]+all_input_extend[5]+all_input_extend[6])/7-a_extend-b_extend;
	//passingscore=sum/7;
	//passingscore=passingscore-a_extend-b_extend;
		for(nn=0;nn<7;nn=nn+1)begin: adj2
			if(all_input_extend[nn]<0)begin
				adjusts[nn]=all_input_extend[nn]/(a_extend+1);
			end
			else
				adjusts[nn]=(a_extend+1)*all_input_extend[nn];
			end
end

//adjust score

always@(*)begin
	no_pass=0;
	for(z=0;z<7;z=z+1)begin: adj3
		if(adjusts[z]<passingscore)
			no_pass=no_pass+1; 
		else
			no_pass=no_pass;

	end
	case(opt[2])
		1'd1 : out=no_pass;
		1'd0 : out=7-no_pass;
	endcase
end

// sort
first_stage_compare f1 (opt[1],all_input_extend[0], all_input_extend[6],id[0],id[6], temp_val[0], temp_val[1], temp_id[0], temp_id[1]);
first_stage_compare f2 (opt[1],all_input_extend[2], all_input_extend[3],id[2],id[3], temp_val[2], temp_val[3], temp_id[2], temp_id[3]);
first_stage_compare f3 (opt[1],all_input_extend[4], all_input_extend[5],id[4],id[5], temp_val[4], temp_val[5], temp_id[4], temp_id[5]);
first_stage_compare f4 (opt[1],all_input_extend[1], temp_val[4] ,id[1],temp_id[4], temp_val[6], temp_val[7], temp_id[6], temp_id[7]);
first_stage_compare f5 (opt[1],temp_val[0] , temp_val[2] ,temp_id[0] , temp_id[2] , temp_val[8], temp_val[9], temp_id[8], temp_id[9]);
first_stage_compare f6 (opt[1],temp_val[3] , temp_val[1] ,temp_id[3] , temp_id[1] , temp_val[10], temp_val[11], temp_id[10], temp_id[11]);
first_stage_compare f7 (opt[1],temp_val[8] , temp_val[6] ,temp_id[8] , temp_id[6], result_val[0], temp_val[12], result_id[0], temp_id[12]);
first_stage_compare f8 (opt[1],temp_val[10], temp_val[7] ,temp_id[10], temp_id[7], temp_val[13], temp_val[14], temp_id[13], temp_id[14]);
first_stage_compare f9 (opt[1],temp_val[9] , temp_val[5] ,temp_id[9] , temp_id[5], temp_val[15], temp_val[16], temp_id[15], temp_id[16]);
first_stage_compare f10(opt[1],temp_val[12], temp_val[15],temp_id[12], temp_id[15], temp_val[17], temp_val[18], temp_id[17], temp_id[18]);
first_stage_compare f11(opt[1],temp_val[14], temp_val[11],temp_id[14], temp_id[11], temp_val[19], temp_val[20], temp_id[19], temp_id[20]);
first_stage_compare f12(opt[1],temp_val[18], temp_val[13],temp_id[18], temp_id[13], temp_val[21], temp_val[22], temp_id[21], temp_id[22]);
first_stage_compare f13(opt[1],temp_val[19], temp_val[16],temp_id[19], temp_id[16], temp_val[23], temp_val[24], temp_id[23], temp_id[24]);
first_stage_compare f14(opt[1],temp_val[17], temp_val[21],temp_id[17], temp_id[21], result_val[1],result_val[2], result_id[1],result_id[2]);
first_stage_compare f15(opt[1],temp_val[22], temp_val[23],temp_id[22], temp_id[23], result_val[3],result_val[4], result_id[3],result_id[4]);
first_stage_compare f16(opt[1],temp_val[24], temp_val[20],temp_id[24], temp_id[20], result_val[5],result_val[6], result_id[5],result_id[6]);

assign s_id0 = result_id[0];
assign s_id1 = result_id[1];
assign s_id2 = result_id[2];
assign s_id3 = result_id[3];
assign s_id4 = result_id[4];
assign s_id5 = result_id[5];
assign s_id6 = result_id[6];


endmodule

module first_stage_compare(mod,in1, in2,id1,id2, upper_val, down_val, upper_id, down_id);
	input signed[4:0] in1, in2;
	input [2:0] id1, id2;
	input mod;
	output reg signed[4:0] upper_val, down_val;
	output reg[2:0] upper_id, down_id;
	
	always @(*)begin
		case(mod)
			1'b0 : begin
				if (in1>in2) begin
					upper_val = in2;
					upper_id = id2;
					down_val = in1;
					down_id = id1;
				end
				else if (in1==in2)begin
					if (id1>id2) begin
						upper_val = in2;
						upper_id = id2;
						down_val = in1;
						down_id = id1;
					end
					else begin
						upper_val = in1;
						upper_id = id1;
						down_val = in2;
						down_id = id2;
					end
				end
				else begin
					upper_val = in1;
					upper_id = id1;
					down_val = in2;
					down_id = id2;
				end
			end
			1'b1 : begin
				if (in1<in2) begin
					upper_val = in2;
					upper_id = id2;
					down_val = in1;
					down_id = id1;
				end
				else if (in1==in2)begin
					if (id1>id2) begin
						upper_val = in2;
						upper_id = id2;
						down_val = in1;
						down_id = id1;
					end
					else begin
						upper_val = in1;
						upper_id = id1;
						down_val = in2;
						down_id = id2;
					end
				end
				else begin
					upper_val = in1;
					upper_id = id1;
					down_val = in2;
					down_id = id2;
				end
			end	
		endcase		
	end

endmodule
