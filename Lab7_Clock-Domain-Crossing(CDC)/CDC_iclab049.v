`include "AFIFO.v"

module CDC #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Input Port
	rst_n,
	clk1,
    clk2,
	in_valid,
    doraemon_id,
    size,
    iq_score,
    eq_score,
    size_weight,
    iq_weight,
    eq_weight,
    //Output Port
	ready,
    out_valid,
	out
    
); 
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
output reg  [7:0] out;
output reg	out_valid,ready;

input rst_n, clk1, clk2, in_valid;
input  [4:0]doraemon_id;
input  [7:0]size;
input  [7:0]iq_score;
input  [7:0]eq_score;
input [2:0]size_weight,iq_weight,eq_weight;

//---------------------------------------------------------------------
//   Integer AND PARAMETER DECLARATION
//---------------------------------------------------------------------
integer i;
parameter pat_num = 13'd5995;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg rinc_flag1,winc_flag1;
wire rempty1,wfull1;
wire [7:0] wdata;
wire [7:0] rdata1;
reg [4:0] doraemon_id_buf [4:0];
reg [7:0] size_buf[4:0];
reg [7:0] iq_score_buf[4:0];
reg [7:0] eq_score_buf[4:0];
reg [13:0] perf[4:0];
wire [2:0] maxid1,maxid2,maxid3,maxid4;
reg [3:0] in_cnt;
reg [13:0] wcnt,out_cnt;
reg [2:0]size_w ;
reg [2:0]iq_w ;
reg[2:0]eq_w ;

//-----------------------------------------------------------------------------------------------------------------
//   Design                                                            
//-----------------------------------------------------------------------------------------------------------------

AFIFO AFIFO1(.rst_n(rst_n),.rclk(clk2),.rinc(rinc_flag1),.wclk(clk1),.winc(winc_flag1),.wdata(wdata),.rempty(rempty1),.rdata(rdata1),.wfull(wfull1));
//AFIFO AFIFO2(.rst_n(rst_n),.rclk(clk2),.rinc(rinc_flag2),.wclk(clk1),.winc(winc_flag2),.wdata(wdata),.rempty(rempty2),.rdata(rdata2),.wfull(wfull2));

MUX mux1(.in1(perf[0]),.in2(perf[1]),.in1_id(3'd0),.in2_id(3'd1),.maxid(maxid1));
MUX mux2(.in1(perf[2]),.in2(perf[3]),.in1_id(3'd2),.in2_id(3'd3),.maxid(maxid2));
MUX mux3(.in1(perf[maxid1]),.in2(perf[maxid2]),.in1_id(maxid1),.in2_id(maxid2),.maxid(maxid3));
MUX mux4(.in1(perf[maxid3]),.in2(perf[4]),.in1_id(maxid3),.in2_id(3'd4),.maxid(maxid4));


// ---------------------------------------------------------------------
//        CLOCK1
// ---------------------------------------------------------------------

// ---------------------------------------------------------------------
//         Get Input
// ---------------------------------------------------------------------

// input counter
always@(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
		in_cnt<=0;			
	end
	else begin
		if (in_valid==1 && in_cnt<=4) in_cnt <= in_cnt+1; 
		else if (out_cnt>=pat_num) in_cnt<=0;
		else in_cnt<=in_cnt;
	end
end

// Get input
always@(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<7;i=i+1)begin
			doraemon_id_buf[i] <= 0;
			size_buf [i] <= 0;                                   
			iq_score_buf [i] <= 0;
			eq_score_buf [i] <= 0;
		end
	end
	else if (out_cnt>=pat_num) begin
		for (i=0;i<5;i=i+1)begin
				doraemon_id_buf[i] <= 0;
				size_buf [i] <= 0;
				iq_score_buf [i] <= 0;
				eq_score_buf [i] <= 0;
		end
	
	end
	else if (in_valid==1 && in_cnt<=4)begin
			for (i=0;i<5;i=i+1)begin
				if (i==in_cnt)begin
					doraemon_id_buf[in_cnt] <= doraemon_id;
					size_buf [in_cnt] <= size;
					iq_score_buf [in_cnt] <= iq_score;
					eq_score_buf [in_cnt] <= eq_score;
				end
				else begin
					doraemon_id_buf[i] <= doraemon_id_buf[i];
					size_buf [i] <= size_buf [i];
					iq_score_buf [i] <= iq_score_buf [i];
					eq_score_buf [i] <= eq_score_buf [i];
				end
			end
	end
	else if (in_valid==1 )begin
			for (i=0;i<5;i=i+1)begin
					if(i==maxid4)begin
						doraemon_id_buf[i] <= doraemon_id;
						size_buf [i] <= size;
						iq_score_buf [i] <= iq_score;
						eq_score_buf [i] <= eq_score;
					end
					else begin
						doraemon_id_buf[i] <= doraemon_id_buf[i];
						size_buf [i] <= size_buf [i];
						iq_score_buf [i] <= iq_score_buf [i];
						eq_score_buf [i] <= eq_score_buf [i];
					end
			end
	end
	else begin
			for (i=0;i<5;i=i+1)begin
				doraemon_id_buf[i] <= doraemon_id_buf[i];
				size_buf [i] <= size_buf [i];
				iq_score_buf [i] <= iq_score_buf [i];
				eq_score_buf [i] <= eq_score_buf [i];
			end
	end
end

//ready
always@(*) begin
    if (!rst_n) ready<=0;
	else if (wfull1==1) ready<=0;
	else if (out_cnt>=pat_num) ready<=0;
	else ready<=1;
end

// Get weight
always@(posedge clk1 or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<5;i=i+1)begin
			size_w <= 0;                                   
			iq_w  <= 0;
			eq_w <= 0;
		end
	end
	else if(in_valid==1 && in_cnt>=4) begin
		size_w <= size_weight;                                   
		iq_w  <=iq_weight ;
		eq_w <= eq_weight;
	end
	else if (out_cnt>=pat_num)begin
		size_w <= 0;                                   
		iq_w  <= 0;
		eq_w <= 0;
	end
	else begin
		size_w <= size_w;                                   
		iq_w  <=iq_w ;
		eq_w <= eq_w;
	end
end	

//Write
//always@(posedge clk1 or negedge rst_n) begin
    //if (!rst_n) winc_flag1<=0;
	//else if (wfull1==1) winc_flag1<=1;
	//else if (out_cnt>=pat_num) winc_flag1<=0;
	//else if (in_cnt>=4) winc_flag1<=1;
	//else winc_flag1<=0;
//end

always@(*) begin
    if (!rst_n) winc_flag1<=0;
	else if (wfull1==1 || (in_valid==0 && wcnt<pat_num)) winc_flag1<=0;
	else if (out_cnt>pat_num) winc_flag1<=0;
	else if (in_cnt>=5) winc_flag1<=1;
	else winc_flag1<=0;
end

always@(posedge clk1 or negedge rst_n) begin
    if (!rst_n) wcnt<=0;
	else if (out_cnt>=pat_num) wcnt<=0;
	else if (winc_flag1==1) wcnt<=wcnt+1;
	else wcnt<=wcnt;
end


// ---------------------------------------------------------------------
//         Calculate Performance
// ---------------------------------------------------------------------

always@(*) begin
	if (!rst_n) begin
		for (i=0;i<5;i=i+1)begin
				perf[i] = 0;                                   
		end	
	end
	else if (out_cnt<=pat_num ) begin
			for (i=0;i<5;i=i+1)begin
				perf[i] = size_buf[i]*size_w+iq_score_buf[i]*iq_w+eq_score_buf[i]*eq_w;                                   
			end
	end	
	else begin
			for (i=0;i<5;i=i+1)begin
				perf[i] = 0;                                   
			end	
	end
end		

assign wdata ={maxid4,doraemon_id_buf[maxid4]};
// ---------------------------------------------------------------------
//         CLOCK2
// ---------------------------------------------------------------------

//Read
//always@(posedge clk2 or negedge rst_n) begin
    //if (!rst_n) rinc_flag1<=0;
	//else if (rempty1!=1)rinc_flag1<=1;
	//else if (out_cnt>=pat_num) rinc_flag1<=0;
	//else rinc_flag1<=0;
//end
//ready
always@(*) begin
    if (!rst_n) rinc_flag1<=0;
	else if (rempty1==1) rinc_flag1<=0;
	else if (out_cnt>=pat_num) rinc_flag1<=0;
	else rinc_flag1<=1;
end

//  Output
always@(posedge clk2 or negedge rst_n) begin
    if (!rst_n) out_valid<=0;	
	else if (rinc_flag1==1&&out_cnt<pat_num)out_valid<=1;
	else out_valid<=0;
end

always@(posedge clk2 or negedge rst_n) begin
    if (!rst_n) out<=0;	
	else if (out_cnt>=pat_num)out<=0;
	else if (rinc_flag1==1)out<=rdata1;
	else out<=0;
end

always@(posedge clk2 or negedge rst_n) begin
    if (!rst_n) out_cnt<=0;
	else if (out_valid==1)out_cnt<=out_cnt+1;
	else if (out_cnt>=pat_num) out_cnt<=out_cnt;
	else out_cnt<=out_cnt;
end

endmodule

module MUX(in1,in2,in1_id,in2_id,maxid);
input [13:0] in1,in2;
input [2:0] in1_id,in2_id;

output wire[2:0] maxid;

assign maxid=(in1>=in2)?in1_id:in2_id;

endmodule
