// synopsys translate_off
`ifdef RTL
	`include "GATED_OR.v"
`else
	`include "Netlist/GATED_OR_SYN.v"
`endif
// synopsys translate_on

module SNN(
	// Input signals
	clk,
	rst_n,
	cg_en,
	in_valid,
	img,
	ker,
	weight,

	// Output signals
	out_valid,
	out_data
);

input clk;
input rst_n;
input in_valid;
input cg_en;
input [7:0] img;
input [7:0] ker;
input [7:0] weight;

output reg out_valid;
output reg [9:0] out_data;

//==============================================//
//       parameter & integer declaration        //
//==============================================//
integer i;
parameter IDLE =  4'd0;
parameter MAX =   4'd1;
parameter QUAN1 = 4'd2;
parameter FC =    4'd3;
parameter QUAN2 = 4'd4;
parameter L1_D =   4'd5;
parameter ACT =   4'd6;
parameter OUT =   4'd7;

//==============================================//
//           reg & wire declaration             //
//==============================================//
// clock gating
reg en_cnn, en_max,  en_quan1, en_fc, en_quan2, en_l1, en_act, en_out;

//state
reg [2:0] current_state, next_state;

// input
reg [7:0] img_buf [35:0];
reg [7:0] ker_buf [8:0];
reg [7:0] weight_buf [3:0];

// CNN
reg [19:0] feature_map1 [15:0];
reg [19:0] feature_map2 [15:0];

//Max Pooling
reg [19:0] max_in1 [3:0];
reg [19:0] max_in2 [3:0];
reg [19:0] max_out1 [3:0];
reg [19:0] max_out2 [3:0];
wire [19:0] max1, max2;
//Quantization1
reg  [7:0] quant1 [3:0];
reg  [7:0] quant2 [3:0];
//Fully connected
reg [16:0] fc1[3:0];
reg [16:0] fc2[3:0];
//Quantization2
reg  [7:0] encoding1 [3:0];
reg  [7:0] encoding2 [3:0];
// L1
reg [7:0] L1_term [3:0];
reg [9:0] L1;
//Activation func
reg [9:0] score;

// counter
reg [5:0] in_cnt;
reg [3:0] f_cnt;
reg flag;
reg [4:0] cnn_cnt;

//==============================================//
//                Top design                    //
//==============================================//

// ---------- Clock gating module -------------//

wire GC_max;
wire SC_max = en_max;
GATED_OR GATED_max (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_max),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_max)
);

wire GC_quan1;
wire SC_quan1 = en_quan1;
GATED_OR GATED_quan1 (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_quan1),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_quan1)
);

wire GC_fc;
wire SC_fc = en_fc;
GATED_OR GATED_fc (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_fc),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_fc)
);

wire GC_quan2;
wire SC_quan2 = en_quan2;
GATED_OR GATED_quan2 (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_quan2),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_quan2)
);

wire GC_l1;
wire SC_l1 = en_l1;
GATED_OR GATED_l1 (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_l1),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_l1)
);

wire GC_act;
wire SC_act = en_act;
GATED_OR GATED_act (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_act),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_act)
);

wire GC_out;
wire SC_out = en_out;
GATED_OR GATED_out (
	.CLOCK(clk),
	.SLEEP_CTRL(SC_out),	// gated clock
	.RST_N(rst_n),
	.CLOCK_GATED(GC_out)
);

//--------------Clock gating control signal--------------------//

always@(*) begin
	if (!cg_en || (current_state == MAX ))
		en_max = 1'b0;        //Let block work
	else
		en_max = 1'b1;		//Let block stop
end

always@(*) begin
	if (!cg_en || (current_state == QUAN1 ))
		en_quan1 = 1'b0;        //Let block work
	else
		en_quan1 = 1'b1;		//Let block stop
end

always@(*) begin
	if (!cg_en || (current_state == FC ))
		en_fc = 1'b0;        //Let block work
	else
		en_fc = 1'b1;		//Let block stop
end

always@(*) begin
	if (!cg_en || (current_state == QUAN2 ))
		en_quan2 = 1'b0;        //Let block work
	else
		en_quan2 = 1'b1;		//Let block stop
end

always@(*) begin
	if (!cg_en || (current_state == L1_D ))
		en_l1 = 1'b0;        //Let block work
	else
		en_l1 = 1'b1;		//Let block stop
end

always@(*) begin
	if (!cg_en || (current_state == ACT ))
		en_act = 1'b0;        //Let block work
	else
		en_act = 1'b1;		//Let block stop
end

always@(*) begin
	if (!cg_en || (current_state == OUT || current_state == IDLE))
		en_out = 1'b0;        //Let block work
	else
		en_out = 1'b1;		//Let block stop
end


//------------------ State ---------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin
			if (f_cnt==15 && flag == 1)      next_state = MAX;
			else                 			next_state = IDLE;
		end	
		MAX : begin
			if (in_cnt==3)      next_state = QUAN1;
			else                next_state = MAX;
		end
		QUAN1 : begin			
			if (f_cnt==3)       next_state = FC;
			else                next_state = QUAN1;
		end
		
		FC :					next_state = QUAN2;
		QUAN2 :					next_state = L1_D;
		L1_D : begin
			if (in_cnt==1)     next_state = ACT;
			else				next_state = L1_D;
		end
		ACT :                   next_state = OUT;
		OUT :                   next_state = IDLE;
		default : next_state = IDLE;
	endcase
end

//----------------- Global counter -------------------//

//in counter							
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) in_cnt <= 0;
	else begin
		case(current_state)
			IDLE : begin
				if (in_cnt==35) in_cnt <= 0;
				else if (in_valid==1) in_cnt <= in_cnt + 1;
				else in_cnt <= in_cnt;
			end
			MAX : begin
				if (f_cnt==2 || f_cnt==8 || f_cnt==10) in_cnt <= in_cnt + 1;
				else if (in_cnt==3) in_cnt <= in_cnt;
				else in_cnt <= 0;
				
			end
			L1_D : begin
				in_cnt <= in_cnt+1;
			end
			default : in_cnt <= 0;
		endcase
	end
end


// feature map counter
always@(posedge clk or negedge rst_n) begin
    if (!rst_n)  begin
			f_cnt <= 0;
	end
	else begin
		case(current_state)
	
			IDLE : begin
				if (in_cnt>=21) f_cnt <= f_cnt+1;
				else f_cnt <= 0;
			end
			MAX : begin
				if (in_cnt==3) f_cnt<= 0;
				else if (f_cnt==0) f_cnt<= 2;
				else if (f_cnt==2) f_cnt<= 8;
				else if (f_cnt==8) f_cnt<= 10;
				else f_cnt <= f_cnt;
			end
			QUAN1 : begin
				if (f_cnt==3) f_cnt<= 0;
				else f_cnt <= f_cnt+1;
			end
			
		default : f_cnt <= 0;
		endcase
	end
end

//----------------- Get Input & Convolution -------------------//
// flag
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n)  begin
			flag <= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (f_cnt==15) flag <= 1;
				else flag <= flag;
			end

		default : flag <= 0;
		endcase
	end
end
//cnn_cnt
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n)  begin
			cnn_cnt <= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (cnn_cnt==3)       cnn_cnt <= 6;
				else if (cnn_cnt==9)  cnn_cnt <= 12;
				else if (cnn_cnt==15) cnn_cnt <= 18;
				else if (in_cnt<=20) cnn_cnt <= 0;
				else cnn_cnt <= cnn_cnt+1;
			end

		default : cnn_cnt <= 0;
		endcase
	end
end

//img 
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<36;i=i+1) begin
			img_buf[i] <= 0;
		end
	end
	else begin
		case(current_state)
			IDLE : begin
				if (in_valid==1)begin
					img_buf[in_cnt] <= img;
				end
				else begin
					for (i=0;i<36;i=i+1) begin
						img_buf[i] <= img_buf[i];
					end
				end
			end
			default : begin
				for (i=0;i<36;i=i+1) begin
						img_buf[i] <= img_buf[i];
				end
			end
		endcase
	end
end

//ker				
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<9;i=i+1)begin
			ker_buf[i] <= 0;
		end
	end
	else begin
		case(current_state)
			IDLE : begin
				if (in_valid==1 && in_cnt<9 && flag==0 && f_cnt==0)begin
					ker_buf[in_cnt] <= ker;
				end
				else begin
					for (i=0;i<9;i=i+1)begin
						ker_buf[i] <= ker_buf[i];
					end
				end
			end
			default : begin
				for (i=0;i<9;i=i+1)begin
						ker_buf[i] <= ker_buf[i];
				end
			end
		endcase
	end
end

//weight							
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			weight_buf[i] <= 0;
		end
	end
	else begin
		case(current_state)
			IDLE : begin
				if (in_valid==1 && in_cnt<4  && flag==0&& f_cnt==0)begin
					weight_buf[in_cnt] <= weight;
				end
				else begin
					for (i=0;i<4;i=i+1)begin
						weight_buf[i] <= weight_buf[i];
					end
				end
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
						weight_buf[i] <= weight_buf[i];
				end
			end
		endcase
	end
end


//-- Convolution --//

// img1
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n) begin
				for (i=0;i<16;i=i+1)begin
					feature_map1[i] <= 0;
				end
	end
	else begin
		case(current_state)
			IDLE : begin
				// img1 
				if ((in_cnt>=20 || (in_cnt==0 && f_cnt==15)) && flag==0) begin
					feature_map1[f_cnt] <= 	img_buf[cnn_cnt]*ker_buf[0]+
												img_buf[cnn_cnt+7'd1]*ker_buf[1]+
												img_buf[cnn_cnt+7'd2]*ker_buf[2]+
												img_buf[cnn_cnt+7'd6]*ker_buf[3]+
												img_buf[cnn_cnt+7'd7]*ker_buf[4]+
												img_buf[cnn_cnt+7'd8]*ker_buf[5]+
												img_buf[cnn_cnt+7'd12]*ker_buf[6]+
												img_buf[cnn_cnt+7'd13]*ker_buf[7]+
												img_buf[cnn_cnt+7'd14]*ker_buf[8];
				end
			
			end
			default : begin
				for (i=0;i<16;i=i+1)begin
					feature_map1[i] <= feature_map1[i];
				end
			end
		endcase
	end
end

//img2
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n)  begin
				for (i=0;i<16;i=i+1)begin
					feature_map2[i] <= 0;
				end		
	end
	else begin
		case(current_state)
			IDLE : begin
				// img2 
				if ((in_cnt>=20 || (in_cnt==0 && f_cnt==15)) && flag==1) begin
					feature_map2[f_cnt] <= 	img_buf[cnn_cnt]*ker_buf[0]+
											img_buf[cnn_cnt+7'd1]*ker_buf[1]+
											img_buf[cnn_cnt+7'd2]*ker_buf[2]+
											img_buf[cnn_cnt+7'd6]*ker_buf[3]+
											img_buf[cnn_cnt+7'd7]*ker_buf[4]+
											img_buf[cnn_cnt+7'd8]*ker_buf[5]+
											img_buf[cnn_cnt+7'd12]*ker_buf[6]+
											img_buf[cnn_cnt+7'd13]*ker_buf[7]+
											img_buf[cnn_cnt+7'd14]*ker_buf[8];
				end
			
			end
			default : begin
				for (i=0;i<16;i=i+1)begin
					feature_map2[i] <= feature_map2[i];
				end			
			end
		endcase
	end
end



//----------------- Max Pooling -------------------//

MAX_POOLING MAX1(.in1(max_in1[0]),.in2(max_in1[1]),.in3(max_in1[2]),.in4(max_in1[3]),.out(max1)); 
MAX_POOLING MAX2(.in1(max_in2[0]),.in2(max_in2[1]),.in3(max_in2[2]),.in4(max_in2[3]),.out(max2)); 

always@(posedge GC_max or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			max_in1[i] <= 0;
		end
	end
	else begin
		case(current_state)
			MAX : begin
				max_in1[0] <= feature_map1[f_cnt];
				max_in1[1] <= feature_map1[f_cnt+1];
				max_in1[2] <= feature_map1[f_cnt+4];
				max_in1[3] <= feature_map1[f_cnt+5];
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					max_in1[i] <= max_in1[i];
				end
			end
		endcase
	end
end

always@(posedge GC_max or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			max_in2[i] <= 0;
		end
	end
	else begin
		case(current_state)
			MAX : begin
				max_in2[0] <= feature_map2[f_cnt];
				max_in2[1] <= feature_map2[f_cnt+1];
				max_in2[2] <= feature_map2[f_cnt+4];
				max_in2[3] <= feature_map2[f_cnt+5];
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					max_in2[i] <= max_in2[i];
				end
			end
		endcase
	end
end

always@(posedge GC_max or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			max_out1[i] <= 0;
		end
	end
	else begin
		case(current_state)
			MAX : begin
				max_out1[in_cnt] <= max1;
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					max_out1[i] <= max_out1[i];
				end
			end
		endcase
	end
end

always@(posedge GC_max or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			max_out2[i] <= 0;
		end
	end
	else begin
		case(current_state)
			MAX : begin
				max_out2[in_cnt] <= max2;
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					max_out2[i] <= max_out2[i];
				end
			end
		endcase
	end
end

//----------------- Quantization-1 -------------------//
always@(posedge GC_quan1 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			quant1[i] <= 0;
		end
	end
	else begin
		case(current_state)
			QUAN1 : begin
				quant1[f_cnt] <= max_out1[f_cnt]/2295;
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					quant1[i] <= quant1[i];
				end
			end
		endcase
	end
end

always@(posedge GC_quan1 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			quant2[i] <= 0;
		end
	end
	else begin
		case(current_state)
			QUAN1 : begin
				quant2[f_cnt] <= max_out2[f_cnt]/2295;
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					quant2[i] <= quant2[i];
				end
			end
		endcase
	end
end

//----------------- Fully connected -------------------//
always@(posedge GC_fc or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			fc1[i] <= 0;
		end
	end
	else begin
		case(current_state)
			FC : begin
				fc1[0] <= quant1[0]*weight_buf[0] + quant1[1]*weight_buf[2];
				fc1[1] <= quant1[0]*weight_buf[1] + quant1[1]*weight_buf[3];
				fc1[2] <= quant1[2]*weight_buf[0] + quant1[3]*weight_buf[2];
				fc1[3] <= quant1[2]*weight_buf[1] + quant1[3]*weight_buf[3];
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					fc1[i] <= fc1[i];
				end
			end
		endcase
	end
end

always@(posedge GC_fc or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			fc2[i] <= 0;
		end
	end
	else begin
		case(current_state)
			FC : begin
				fc2[0] <= quant2[0]*weight_buf[0] + quant2[1]*weight_buf[2];
				fc2[1] <= quant2[0]*weight_buf[1] + quant2[1]*weight_buf[3];
				fc2[2] <= quant2[2]*weight_buf[0] + quant2[3]*weight_buf[2];
				fc2[3] <= quant2[2]*weight_buf[1] + quant2[3]*weight_buf[3];
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					fc2[i] <= fc2[i];
				end
			end
		endcase
	end
end
//----------------- Quantization-2 -------------------//
always@(posedge GC_quan2 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			encoding1[i] <= 0;
		end
	end
	else begin
		case(current_state)
			QUAN2 : begin
				encoding1[0] <= fc1[0]/510;
				encoding1[1] <= fc1[1]/510;
				encoding1[2] <= fc1[2]/510;
				encoding1[3] <= fc1[3]/510;
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					encoding1[i] <= encoding1[i];
				end
			end
		endcase
	end
end

always@(posedge GC_quan2 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			encoding2[i] <= 0;
		end
	end
	else begin
		case(current_state)
			QUAN2 : begin
				encoding2[0] <= fc2[0]/510;
				encoding2[1] <= fc2[1]/510;
				encoding2[2] <= fc2[2]/510;
				encoding2[3] <= fc2[3]/510;
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					encoding2[i] <= encoding2[i];
				end
			end
		endcase
	end
end
//----------------- L1 distance -------------------//
always@(posedge GC_l1 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<4;i=i+1)begin
			L1_term[i] <= 0;
		end
	end
	else begin
		case(current_state)
			L1_D : begin
				if (in_cnt==0) begin
					if (encoding1[0]>=encoding2[0]) L1_term[0] <= encoding1[0]-encoding2[0];
					else                            L1_term[0] <= encoding2[0]-encoding1[0];
					if (encoding1[1]>=encoding2[1]) L1_term[1] <= encoding1[1]-encoding2[1];
					else                            L1_term[1] <= encoding2[1]-encoding1[1];
					if (encoding1[2]>=encoding2[2]) L1_term[2] <= encoding1[2]-encoding2[2];
					else                            L1_term[2] <= encoding2[2]-encoding1[2];
					if (encoding1[3]>=encoding2[3]) L1_term[3] <= encoding1[3]-encoding2[3];
					else                            L1_term[3] <= encoding2[3]-encoding1[3];
				end
				else begin
					for (i=0;i<4;i=i+1)begin
						L1_term[i] <= L1_term[i];
					end
				end
			end
			default : begin
				for (i=0;i<4;i=i+1)begin
					L1_term[i] <= 0;
				end
			end
		endcase
	end
end

always@(posedge GC_l1 or negedge rst_n) begin
    if (!rst_n) L1 <=0;
	else begin
		case(current_state)
			L1_D : begin
				 if (in_cnt==1) L1 <= L1_term[0]+L1_term[1]+L1_term[2]+L1_term[3];
				 else L1 <=L1;
			end
			default : L1 <=L1;

		endcase
	end
end

//----------------- Activation func -------------------//
always@(posedge GC_act or negedge rst_n) begin
    if (!rst_n) score <=0;
	else begin
		case(current_state)
			ACT : begin
				 if (L1<16) score <=0;
				 else score <= L1;
			end
			default : score <=score;

		endcase
	end
end
//----------------- OUT -------------------//
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n) out_data <=0;
	else begin
		case(current_state)
			OUT : out_data <=score;
			default : out_data <=0;

		endcase
	end
end
always@(posedge GC_out or negedge rst_n) begin
    if (!rst_n) out_valid <=0;
	else begin
		case(current_state)
			OUT : out_valid <=1;
			default : out_valid <=0;

		endcase
	end
end
endmodule

 
 

//==============================================//
//                Submodule                     //
//==============================================//

module MAX_POOLING (
	in1,
	in2,
	in3,
	in4,
	out	
);
input [19:0] in1, in2, in3, in4;
output [19:0] out;
wire [19:0] compare1, compare2;
assign compare1=(in1>=in2)?in1:in2;
assign compare2=(compare1>=in3)?compare1:in3;
assign out=(compare2>=in4)?compare2:in4;
endmodule
