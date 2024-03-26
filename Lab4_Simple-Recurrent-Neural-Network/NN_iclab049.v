//synopsys translate_off
`include "/usr/synthesis/dw/sim_ver/DW_fp_dp3.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_recip.v"
`include "/usr/synthesis/dw/sim_ver/DW_fp_exp.v"
//synopsys translate_on

module NN(
	//input
	clk,
	rst_n,
	in_valid,
	weight_u,
	weight_w,
	weight_v,
	data_x,
	data_h,
	//output
	out_valid,
	out
);

// Input & Output //
input clk, rst_n,in_valid;
input [31:0] weight_u, weight_v,weight_w,data_x;
input [31:0] data_h;

output reg out_valid;
output reg [31:0] out;

// Wire & Reg //
reg [31:0] U [8:0];
reg [31:0] V [8:0];
reg [31:0] W [8:0];
reg [31:0] X [8:0];
reg [31:0] Y [8:0];
reg [31:0] H [11:0];

reg [31:0] reg_mult0_u,reg_mult0_x,reg_mult0_h,reg_mult0_w;
reg [31:0] reg_mult1_u,reg_mult1_x,reg_mult1_h,reg_mult1_w;
reg [31:0] reg_mult2_u,reg_mult2_x,reg_mult2_h,reg_mult2_w;
reg [31:0] reg_mult3_u,reg_mult3_x,reg_mult3_h,reg_mult3_w;
reg [31:0] reg_add0_ux_hw0;
reg [3:0] in_count,count_y,count_ux,count,count_out,count2, count3;
reg [3:0] current_state, next_state;
reg [3:0] count_h;
wire [31:0] Leaky_ReLU_flag,exp_out,Y_sigmoid,reg_xu,reg_wh;
// Parameter & Integer //
parameter IDLE=4'd0;
parameter EXE1=4'd1;
parameter EXE2=4'd2;
parameter PRE_RELU=4'd3;
parameter RELU=4'd4;
parameter Y1=4'd5;
parameter pre_sigmoid=4'd6;
parameter sigmoid=4'd7;
parameter OUT=4'd8;
parameter inst_sig_width=23;
parameter inst_exp_width=8;
parameter inst_ieee_compliance=0;
parameter inst_arch=0;
parameter inst_faithful_round=0;
parameter round=0;
//parameter zeroone=32'b0011111110111001100110011001100110011001100110011001100110011010 ;

integer i,j;

//---------------------------------------------//
//                    Design                   //
//---------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
        case(current_state)
                IDLE: begin
					if(in_count==8)
						next_state= EXE1;
					else 
						next_state= IDLE;
				end
				EXE1 : begin
					next_state= EXE2;
				end
				EXE2 : begin
					next_state= PRE_RELU;
				end
				PRE_RELU : begin
					next_state= RELU;
				end
				RELU : begin
					if (count_h==8)
						next_state=Y1 ;
					else
						next_state= EXE1;
				end	
				Y1 : begin
					next_state= pre_sigmoid;	
				end
				pre_sigmoid : begin
					next_state= sigmoid;
				end		
				sigmoid : begin 
					if(count3>8)
						next_state=OUT;
					else
						next_state=Y1;
				end
				OUT : begin
					if(count_out<=8) 
						next_state=OUT;
					else
						next_state=IDLE;
				end
				default : begin
						next_state=IDLE;
				end
		endcase
end		

always @(posedge clk or negedge rst_n) begin   
    if(!rst_n) begin
		for(i=0;i<9;i=i+1) begin
			U[i] <= 0;
			V[i] <= 0;
			W[i] <= 0;
			X[i] <= 0;
			Y[i] <= 1;
		end
		for(j=0;j<3;j=j+1) begin
			H[j] <= 0;
		end
		in_count<=0;
		reg_mult0_u <= 0;
		reg_mult0_x <= 0;
		reg_mult1_h <= 0;
		reg_mult1_w <= 0;
		reg_add0_ux_hw0 <= 0;
		count <= 0;
		count_h <= 0;
		count_ux <= 0;
		count_y <= 0;
		count_out <=0;
		count2 <= 0;
		count3 <= 0;
		//Leaky_ReLU_flag <=0;
		out <= 0;
		out_valid <= 0;
    end
    else begin
        case(current_state)
            IDLE : begin
				if (in_valid==1)begin
					if (in_count<3)begin
						U[in_count] <= weight_u;
						V[in_count] <= weight_v;
						W[in_count] <= weight_w;
						X[in_count] <= data_x;
						H[in_count] <= data_h;
						in_count <= in_count +1;
					end
					else begin
						U[in_count] <= weight_u;
						V[in_count] <= weight_v;
						W[in_count] <= weight_w;
						X[in_count] <= data_x;
						in_count <= in_count +1;	
					end
					for(i=0;i<9;i=i+1) begin
						Y[i] <= 0;
					end					
				end
				else begin
					for(i=0;i<9;i=i+1) begin
						U[i] <= 0;
						V[i] <= 0;
						W[i] <= 0;
						X[i] <= 0;
						Y[i] <= 0;
					end
					for(j=0;j<3;j=j+1) begin
						H[j] <= 0;
					end
					in_count<=0;
					reg_mult0_u <= 0;
					reg_mult0_x <= 0;
					reg_mult1_h <= 0;
					reg_mult1_w <= 0;
					reg_add0_ux_hw0 <= 0;
					count <= 0;
					count_h <= 0;
					count_ux <= 0;
					count_y <= 0;
					count_out <=0;
					count2 <= 0;
					count3 <= 0;
					//Leaky_ReLU_flag <=0;
					out <= 0;
					out_valid <= 0;
				end
			end
			EXE1 : begin

				reg_mult0_u <= U[count];
				reg_mult0_x <= X[count2];
				reg_mult1_u <= U[count+1];
				reg_mult1_x <= X[count2+1];
				reg_mult2_u <= U[count+2];
				reg_mult2_x <= X[count2+2];				
				reg_mult0_h <= H[count2];
				reg_mult0_w <= W[count];
				reg_mult1_h <= H[count2+1];
				reg_mult1_w <= W[count+1];
				reg_mult2_h <= H[count2+2];
				reg_mult2_w <= W[count+2];				
				out<=0;						
				count <= count+3;
				for(i=0;i<9;i=i+1) begin
					Y[i] <= 0;
				end				
			end
			EXE2 : begin
				reg_mult0_u <=reg_xu;
				reg_mult0_x <=32'b00111111100000000000000000000000;
				reg_mult1_u <=reg_wh;
				reg_mult1_x <=32'b00111111100000000000000000000000;
				reg_mult2_u <=0;
				reg_mult2_x <=0;				
				reg_mult0_h <=0;
				reg_mult0_w <=0;
				reg_mult1_h <=0;
				reg_mult1_w <=0;
				reg_mult2_h <=0;
				reg_mult2_w <=0;				
				out<=0;
				for(i=0;i<9;i=i+1) begin
					Y[i] <= 0;
				end						
			end
			PRE_RELU : begin
				reg_mult0_u <=reg_xu;
				reg_mult0_x <=Leaky_ReLU_flag;
				reg_mult1_u <=0;
				reg_mult1_x <=0;
				reg_mult2_u <=0;
				reg_mult2_x <=0;				
			end
			RELU : begin
				H[count_h+3] <= reg_xu;
				count_h<=count_h+1;
				out<=0;
				for(i=0;i<9;i=i+1) begin
					Y[i] <= 0;
				end		
				if (count_h == 2 || count_h == 5) begin
					count2 <= count2+3;
					count<=0;
				end
				else begin
					count2 <= count2;	
					count<=count;
				end
			end
			Y1 : begin
				reg_mult0_u <= V[count_ux];
				reg_mult0_x <= H[count3+3];	
				reg_mult1_u <= V[count_ux+1];
				reg_mult1_x <= H[count3+4];
				reg_mult2_u <= V[count_ux+2];
				reg_mult2_x <= H[count3+5];			
				reg_mult0_h <= 0;
				reg_mult0_w <= 0;
				reg_mult1_h <= 0;
				reg_mult1_w <= 0;
				reg_mult2_h <= 0;
				reg_mult2_w <= 0;	
	            count_ux<=count_ux+3;
				out<=0;
				for(i=0;i<9;i=i+1) begin
					Y[i] <= Y[i];
				end		
			end
			pre_sigmoid : begin
				reg_mult0_u <= exp_out;
				reg_mult0_x <= 32'b00111111100000000000000000000000;	
				reg_mult1_u <= 32'b00111111100000000000000000000000;
				reg_mult1_x <= 32'b00111111100000000000000000000000;
				reg_mult2_u <= 0;
				reg_mult2_x <= 0;			
				reg_mult0_h <= 0;
				reg_mult0_w <= 0;
				reg_mult1_h <= 0;
				reg_mult1_w <= 0;
				reg_mult2_h <= 0;
				reg_mult2_w <= 0;
			end
			sigmoid : begin
				Y[count_y] <= Y_sigmoid;
				count_y<=count_y+1;
				out<=0;
				if (count_ux>=8) begin
					count_ux<=0;
					count3 <= count3+3;
				end
				else begin
					count_ux<=count_ux;
					count3 <= count3;
				end
			end
			
			OUT : begin
				if(count_out>8) begin
					out_valid<=0;
					out<=0;
				for(i=0;i<9;i=i+1) begin
					Y[i] <= 0;
				end	
				end
				else begin
					out_valid<=1;
					out<=Y[count_out];
					count_out<=count_out+1;
					for(i=0;i<9;i=i+1) begin
						Y[i] <= Y[i];
					end	
				end

			end
		endcase
	end	
end

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U1 (
			.a(reg_mult0_u),
			.b(reg_mult0_x),
			.c(reg_mult1_u),
			.d(reg_mult1_x),
			.e(reg_mult2_u),
			.f(reg_mult2_x),
			.rnd(3'b0),
			.z(reg_xu));

DW_fp_dp3 #(inst_sig_width, inst_exp_width, inst_ieee_compliance, inst_arch) U2 (
			.a(reg_mult0_w),
			.b(reg_mult0_h),
			.c(reg_mult1_w),
			.d(reg_mult1_h),
			.e(reg_mult2_w),
			.f(reg_mult2_h),
			.rnd(3'b0),
			.z(reg_wh));
// Leaky_ReLU
assign Leaky_ReLU_flag = (reg_xu[31] == 1'b1)? 32'b00111101110011001100110011001101 : 32'b00111111100000000000000000000000;
// Sigmoid
DW_fp_exp #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_arch) Uexp(.a({~reg_xu[31],reg_xu[30:0]}), .z(exp_out));
DW_fp_recip #(inst_sig_width,inst_exp_width,inst_ieee_compliance,inst_faithful_round) Urecip(.a(reg_xu), .rnd(3'b0), .z(Y_sigmoid));
endmodule