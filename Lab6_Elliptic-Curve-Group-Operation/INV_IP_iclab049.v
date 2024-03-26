//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : INV_IP.v
//   	Module Name : INV_IP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

module INV_IP #(parameter IP_WIDTH = 6) (
    // Input signals
    IN_1, IN_2,
    // Output signals
    OUT_INV
);

// ===============================================================
// Declaration
// ===============================================================
input [IP_WIDTH-1:0] IN_1, IN_2;
output [IP_WIDTH-1:0] OUT_INV;
wire signed [IP_WIDTH:0]result;
wire [IP_WIDTH-1:0] IN1,IN2;
//wire [31:0] idx;
//integer idx;
// ===============================================================
// Main
// ===============================================================
genvar i;
generate
	for(i=0; i<9; i=i+1) begin: ASSIGN_AB
		wire[IP_WIDTH-1:0] a,b,idx;
		if(i==0) begin
			assign b=(IN_1>=IN_2)? {1'b0,IN_1}: {1'b0,IN_2};
			assign a=(IN_1>=IN_2)? {1'b0,IN_2}: {1'b0,IN_1};
			//assign idx=0;
		end
		else begin
			assign a = ASSIGN_AB[i-1].b;	
			assign b = (ASSIGN_AB[i-1].a)%(ASSIGN_AB[i-1].b);
			//assign idx=(b==0)?i:ASSIGN_AB[i-1].idx;
			//assign idx=ASSIGN_AB[i-1].idx;
			
		end	
	end
endgenerate

genvar j;
generate
	for(j=0; j<9; j=j+1) begin: A_DIV_B
		wire signed [IP_WIDTH:0] div;
		assign div = (ASSIGN_AB[j].a)/(ASSIGN_AB[j].b);	
	end
endgenerate

genvar k;
generate
	for(k=8; k>=0; k=k-1) begin: EE
		wire signed [IP_WIDTH+1:0] s,t;
		if(k==8) begin
			assign s=1;
			assign t=0;
		end
		else if(k==0) begin
 			assign result = (EE[k+1].t+ASSIGN_AB[0].b)%ASSIGN_AB[0].b;
		end
		else begin
			assign s=(ASSIGN_AB[k].b==0)? 1: EE[k+1].t;
			assign t=(ASSIGN_AB[k].b==0)? 0: (EE[k+1].s)-(A_DIV_B[k].div)*EE[k+1].t;
		end
		
	end
endgenerate
assign OUT_INV = result[IP_WIDTH-1:0];

endmodule