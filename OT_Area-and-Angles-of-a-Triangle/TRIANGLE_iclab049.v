//synopsys translate_off
`include "DW_div.v"
`include "DW_div_seq.v"
`include "DW_div_pipe.v"
//synopsys translate_on

module TRIANGLE(
    clk,
    rst_n,
    in_valid,
    in_length,
    out_cos,
    out_valid,
    out_tri
);
input wire clk, rst_n, in_valid;
input wire [7:0] in_length;

output reg out_valid;
output reg [15:0] out_cos;
output reg [1:0] out_tri;

// Declare //
reg signed [17:0] in_a, in_b, in_c;
reg signed [17:0] son_a, son_b, son_c;
reg signed [18:0] mom_a, mom_b, mom_c;
wire  signed[30:0] div_a, div_b, div_c;
reg signed [30:0] rel_a, rel_b, rel_c;
wire signed [30:0] r_a, r_b, r_c;
reg [1:0] in_count, out_count;
reg [1:0] mod;
reg [2:0] current_state, next_state;
reg start_flag,  fuck_flag;  
wire a_flag,b_flag, c_flag, divide_by_0;
// par

parameter IDLE = 3'b000;
parameter CAL1 = 3'b001;
parameter CAL2 = 3'b010;
parameter CAL3 = 3'b011;
parameter CAL4 = 3'b100;
parameter OUT = 3'b101;

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
			if (in_count==2) next_state =CAL1;
			else next_state =IDLE;
		end
		CAL1: next_state =CAL2;
		CAL2: begin
			if (a_flag==1 && b_flag==1 && c_flag==1 &&fuck_flag==1) next_state =CAL3;
			else next_state =CAL2;
		end
		CAL3: next_state =CAL4;
		CAL4: next_state =OUT;
		OUT : begin
			if (out_count==2) next_state =IDLE;
			else next_state =OUT;
		end
		default : next_state =IDLE;
	endcase
end

// Get Input //		
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		in_a <= 0;
		in_b <= 0;
		in_c <= 0;
    	end
    	else begin
		case(current_state)
            		IDLE : begin
				if (in_valid==1 && in_count==0)in_a <= in_length;
				else if (in_valid==1 && in_count==1)in_b <= in_length;
				else 	in_c <= in_length; //
	    		end
			default : begin
				in_a <= in_a;
				in_b <= in_b;
				in_c <= in_c;
			end
		endcase
	end
end
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		in_count <= 0;
    	end
    	else begin
		case(current_state)
            		IDLE : begin
				if (in_valid==1) in_count <= in_count+1;
				else  in_count <= in_count;
	    		end
			default : in_count <= 0;
		endcase
	end
end

// calculate //
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		son_a <= 0;
		son_b <= 0;
		son_c <= 0;
    	end
    	else begin
		case(current_state)
            IDLE : begin
				son_a <= 0;
				son_b <= 0;
				son_c <= 0;
    			end
			CAL1: begin
				son_a <= (in_b*in_b)+(in_c*in_c)-(in_a*in_a);
				son_b <= (in_a*in_a)+(in_c*in_c)-(in_b*in_b);
				son_c <= (in_a*in_a)+(in_b*in_b)-(in_c*in_c);
			end
			default : begin
 				son_a <= son_a;
				son_b <= son_b;
				son_c <= son_c ;
			end
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		mom_a <= 0;
		mom_b <= 0;
		mom_c <= 0;
    	end
    	else begin
		case(current_state)
            IDLE : begin
				mom_a <= 0;
				mom_b <= 0;
				mom_c <= 0;
    			end
			CAL1: begin
				mom_a <= 2*in_b*in_c;
				mom_b <= 2*in_a*in_c;
				mom_c <= 2*in_a*in_b;
			end
			default : begin
 				mom_a <= mom_a;
				mom_b <= mom_b;
				mom_c <= mom_c ;
			end
		endcase
	end
end
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		start_flag <= 0;
    	end
    	else begin
		case(current_state)
            CAL1 : start_flag <= 1;
			default : start_flag <= 0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		fuck_flag <= 0;
    	end
    	else begin
		case(current_state)
            CAL2 : begin
				if (a_flag==1 && b_flag==1 && c_flag==1 ) fuck_flag <= 1;
				else fuck_flag <= fuck_flag;
			end
			default : fuck_flag <= 0;
		endcase
	end
end
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		rel_a <=0;
		rel_b <= 0;
		rel_c <= 0;
    	end
    	else begin
		case(current_state)
            CAL3 : begin
				rel_a <= div_a;
				rel_b <= div_b;
				rel_c <= div_c;
    			end
			default : begin
				rel_a <= rel_a;
				rel_b <= rel_b;
				rel_c <= rel_c;
    			end
		endcase
	end
end

///      Type     ///
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		mod <= 0;
    	end
    	else begin
		case(current_state)
            CAL4 : begin
				if (rel_a==0 || rel_b==0 || rel_c==0) mod <= 2'b11;
				else if (rel_a<0 || rel_b<0 || rel_c<0) mod <= 2'b01;	
				else 	mod <= 2'b00;
    			end
			OUT : mod <= mod;
			default : mod <=0;
		endcase
	end
end

///      Out     ///
always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		out_cos <=0;
    	end
    	else begin
		case(current_state)
            OUT : begin
				if (out_count==0) begin
					if (rel_a[30] == 1 ) out_cos <= {1'b1,rel_a[14:0]};
					else out_cos <= {1'b0,rel_a[14:0]};
				end
				else if (out_count==1)begin
					if (rel_b[30] == 1 ) out_cos <= {1'b1,rel_b[14:0]};
					else out_cos <= {1'b0,rel_b[14:0]};
				end	
				else if (out_count==2)begin
					if (rel_c[30] == 1 ) out_cos <= {1'b1,rel_c[14:0]};
					else out_cos <= {1'b0,rel_c[14:0]};
				end
				else 	out_cos <=0;
    		end
			default : out_cos <=0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		out_tri <=0;
    	end
    	else begin
		case(current_state)
            		OUT : begin
				if (out_count==0)out_tri <= mod;
				else if (out_count==1)out_tri <= 0;	
				else if (out_count==2) out_tri <= 0;
				else 	out_tri <=0;
    			end
			default : out_tri <=0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		out_count <=0;
    	end
    	else begin
		case(current_state)
            		OUT : begin
						out_count <=out_count+1;
				
    			end
			default : out_count <=0;
		endcase
	end
end

always @(posedge clk or negedge rst_n) begin   
    	if(!rst_n) begin
		out_valid <=0;
    	end
    	else begin
		case(current_state)
            		OUT : begin
					out_valid <= 1;
    			end
			default : out_valid <=0;
		endcase
	end
end

			

DW_div_seq #(.a_width(31), .b_width(19), .tc_mode(1), .num_cyc(15), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0)) D1(
		.clk(clk),
		.rst_n(rst_n),
		.hold(0),
		.start(start_flag),
		.a({son_a, 13'd0}),
		.b(mom_a),
		.complete(a_flag),
		.quotient(div_a)
		);
DW_div_seq #(.a_width(31), .b_width(19), .tc_mode(1), .num_cyc(15), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0)) D2(
		.clk(clk),
		.rst_n(rst_n),
		.hold(0),
		.start(start_flag),
		.a({son_b, 13'd0}),
		.b(mom_b),
		.complete(b_flag),
		.quotient(div_b)
		);
DW_div_seq #(.a_width(31), .b_width(19), .tc_mode(1), .num_cyc(15), .rst_mode(0), .input_mode(0), .output_mode(1), .early_start(0)) D3(
		.clk(clk),
		.rst_n(rst_n),
		.hold(0),
		.start(start_flag),
		.a({son_c, 13'd0}),
		.b(mom_c),
		.complete(c_flag),
		.quotient(div_c)
		);	

   

endmodule
