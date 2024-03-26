//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//    (C) Copyright Optimum Application-Specific Integrated System Laboratory
//    All Right Reserved
//		Date		: 2023/03
//		Version		: v1.0
//   	File Name   : EC_TOP.v
//   	Module Name : EC_TOP
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################

//synopsys translate_off
`include "INV_IP.v"
//synopsys translate_on

module EC_TOP(
    // Input signals
    clk, rst_n, in_valid,
    in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a,
    // Output signals
    out_valid, out_Rx, out_Ry
);

// ===============================================================
// Input & Output Declaration
// ===============================================================
input clk, rst_n, in_valid;
input [6-1:0] in_Px, in_Py, in_Qx, in_Qy, in_prime, in_a;
output reg out_valid;
output reg [6-1:0] out_Rx, out_Ry;
// ===============================================================
// Integer & Parameter
// ===============================================================



// ===============================================================
// Wire & Reg
// ===============================================================
reg [6-1:0] px, py, qx, qy, a, xr, yr;
reg [13:0] s_son;
reg [20:0]  s;
reg [6:0] p,s_mom;
reg [2:0] counter;
reg [11:0] first_sub;
wire [5:0] INV_IP6_out;
// ===============================================================
// IP
// ===============================================================
//INV_IP #(.IP_WIDTH(5)) I_INV_IP5 ( .IN_1(p[4:0]), .IN_2(s_mom[4:0]), .OUT_INV(INV_IP5_out));
INV_IP #(.IP_WIDTH(6)) I_INV_IP6 ( .IN_1(p[5:0]), .IN_2(s_mom[5:0]), .OUT_INV(INV_IP6_out));
//INV_IP #(.IP_WIDTH(7)) I_INV_IP7 ( .IN_1(p[6:0]), .IN_2(s_mom[6:0]), .OUT_INV(INV_IP7_out));

// ===============================================================
// Design
// ===============================================================

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		counter<=0;
	end
	else begin
		if(in_valid==1 && counter<6) counter <= 1;
		else if (counter<6 && counter>0) counter <= counter+1;
		else counter<=0;
	end
end
		
// Input //	
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		px <= 0;	
		py <= 0;
		qx <= 0;
		qy <= 0;
		p <= 0;
		a <= 0;
	end
	else begin		
		if (in_valid==1) begin				
			px <= in_Px;	
			py <= in_Py;
			qx <= in_Qx;
			qy <= in_Qy;
			p <= in_prime;
			a <= in_a;
		end	
		else begin
			px <= px;	
			py <= py;
			qx <= qx;
			qy <= qy;
			p <= p;
			a <= a;
		end
	end
end

// Calculation //
always@(*)begin

		if ((px!=qx) || (py!=qy))begin
			if ((qy>=py) && (qx>=px))begin
				s_son = qy-py;
				s_mom = qx-px;
			end
			else if ((qy<=py) && (qx>=px))begin
				s_son = qy+p-py;   // overflow??
				s_mom = qx-px;
			end	
			else if ((qy>=py) && (qx<=px))begin
				s_son = qy-py;   // overflow??
				s_mom = qx+p-px;
			end
			else begin
				s_son = qy+p-py;   // overflow??
				s_mom = qx+p-px;
			end
		end
		else begin
			s_son = 3*px*px + a;
			s_mom = (2*py)%p;
		end
		
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		s <= 0;
	end
	else begin
		s <= (INV_IP6_out*s_son)%p;
		//counter <= counter+1;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		first_sub <= 0;
	end
	else begin
		if (counter==2) begin
			if (s*s>=px) first_sub<= (s*s)-px;
			else first_sub<= (s*s)+p-px;
		end
		else if (counter==4) begin
			if (px>=xr) first_sub<= s*(px-xr);
			else first_sub<= s*(px+p-xr);
		end
		else first_sub<= first_sub;	
	end

end
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		xr <= 0;
	end
	else begin
		if (counter==3) begin
			if (first_sub>=qx) xr <= (first_sub-qx)%p;
			else xr <= (first_sub+p-qx)%p;
		end
		else xr<=xr;
	end
end

always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		yr <= 0;
	end
	else begin
		if (counter==5) begin
			if (first_sub>=py) yr <= (first_sub-py)%p;
			else yr <= (first_sub+p-py)%p;
		end
		else yr<=yr;
	end
end		
		
always@(posedge clk or negedge rst_n)begin
	if(!rst_n) begin
		out_valid <= 0;
		out_Rx <= 0;
		out_Ry <= 0;
	end
	else begin
		if (counter==6) begin
			out_valid <= 1;
			out_Rx <= xr;
			out_Ry <= yr;
		end
		else begin
			out_valid <= 0;
			out_Rx <= 0;
			out_Ry <= 0;
		end
	end
end

endmodule