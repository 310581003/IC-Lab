module MMT(
// input signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
	
// output signals
    out_valid,
    out_value
);
//---------------------------------------------------------------------
//   INPUT AND OUTPUT DECLARATION
//---------------------------------------------------------------------
input        clk, rst_n, in_valid, in_valid2;
input [7:0] matrix;
input [1:0]  matrix_size,mode;
input [4:0]  matrix_idx;

output reg       	     out_valid;
output reg signed [49:0] out_value;


//---------------------------------------------------------------------
//   PARAMETER
//---------------------------------------------------------------------
 integer i,j;
 parameter IDLE   = 3'b000;
 parameter READ_A = 3'b001;
 parameter READ_B = 3'b010;
 parameter READ_C = 3'b011;
 parameter READ_AB = 3'b100;
 parameter MUL    = 3'b101;
 parameter TRACE  = 3'b110;
 parameter OUT    = 3'b111;
//---------------------------------------------------------------------
//   WIRE AND REG DECLARATION
//---------------------------------------------------------------------
reg [2:0] current_state, next_state;
reg [12:0] A_C;
reg [7:0] A_AB;
reg [13:0]address_cnt;
reg signed[7:0] D_C;
reg signed[49:0]D_AB;
reg WEN_C,WEN_AB;
wire signed[7:0] Q_C;
wire signed[49:0] Q_AB;
reg [1:0] idx_cnt,cal_mod,init_size,switch;
reg [4:0] index [2:0];
reg signed [7:0] A [0:15] [0:15]; 
reg signed [7:0] B [0:15] [0:15];
reg signed [7:0] C [0:15] [0:15];

reg [4:0] size, row_cnt,col_cnt;
reg [8:0] cal_counter,data_cnt,trace_cnt;
reg signed [49:0] trace,AB;
reg [3:0] out_cnt;
//---------------------------------------------------------------------
//   SRAM
//---------------------------------------------------------------------

RA1SH     C_SRAM(.Q(Q_C),.CLK(clk),.CEN(1'b0),.WEN(WEN_C),.A(A_C),.D(D_C),.OEN(1'b0));
RA1SH_AB AB_SRAM(.Q(Q_AB),.CLK(clk),.CEN(1'b0),.WEN(WEN_AB),.A(A_AB),.D(D_AB),.OEN(1'b0));

//---------------------------------------------------------------------
//   DESIGN
//---------------------------------------------------------------------
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end


always@(*) begin
    case(current_state)
		IDLE : begin
			case(size)
				5'd2 : begin
					if (address_cnt==128) next_state = READ_A;
					else                     next_state = IDLE;
				end
				5'd4 : begin
					if (address_cnt==512) next_state = READ_A;
					else                     next_state = IDLE;
				end
				5'd8 : begin
					if (address_cnt==2048) next_state = READ_A;
					else                     next_state = IDLE;
				end
				5'd16 : begin
					if (address_cnt==8192) next_state = READ_A;
					else                     next_state = IDLE;
				end
				default : next_state = IDLE;
			endcase	
		end
		READ_A : begin
			if (switch==1) next_state = READ_B;
			else           next_state = READ_A; 
		end
		READ_B : begin
			if (switch==1) next_state = READ_C;
			else           next_state = READ_B; 
		end
		READ_C : begin
			if (switch==1) next_state = MUL;
			else           next_state = READ_C; 
		end
		//READ_AB : begin
			 //next_state = MUL; 
		//end
		MUL : begin
			if(data_cnt<256) next_state = MUL;	
			else next_state = TRACE;
		end
		TRACE: begin
			if(trace_cnt<255) next_state = TRACE;	
			else next_state = OUT;			
		end
		OUT : begin
			if (out_cnt==9) next_state = IDLE;
			else             next_state = READ_A;		
		end
		default : next_state = IDLE;
	endcase
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) out_cnt <=0;
	else begin
		case(current_state)
			IDLE : out_cnt <=0;
			OUT : out_cnt <=out_cnt+1;
			default : out_cnt <=out_cnt;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) out_valid <=0;
	else begin
		case(current_state)
			OUT : out_valid <=1;
			default : out_valid <=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) out_value <=0;
	else begin
		case(current_state)
			OUT : out_value <=trace;
			default : out_value <=0;
		endcase	
	end
end


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) A_C <= 0;
	else begin
		case(current_state)
			IDLE :begin
				if(in_valid==1) A_C <= address_cnt;
				else A_C <= A_C;
			end
			READ_A : begin
				if(in_valid2==1) A_C <=index[0]*size*size;
				else if (idx_cnt==3) begin
					if(cal_counter<size*size && switch!=1) A_C<=A_C+1;
					else A_C<=index[1]*size*size;
				end
				else  A_C <= A_C;								
			end
			READ_B : begin
				if(cal_counter<size*size && switch!=1) A_C<=A_C+1;
				else  A_C<=index[2]*size*size;							
			end	
			READ_C : begin
				if(cal_counter<size*size && switch!=1) A_C<=A_C+1;
				else  A_C<=0;							
			end				
			default : A_C <= 0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) D_C <= 0;
	else begin
		case(current_state)
			IDLE :begin
				if(in_valid==1) D_C<=matrix;
				else D_C<=D_C;
			end			
			default : D_C<=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) WEN_C <= 0;
	else begin
		case(current_state)
			IDLE : WEN_C <=0;
			default : WEN_C <=1;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) address_cnt <=0;
	else begin
		case(current_state)
			IDLE :begin
				if(in_valid==1) address_cnt<=address_cnt+1;
				else address_cnt <=address_cnt;				
			end		
			default : address_cnt <=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) idx_cnt <= 0;
	else begin
		case(current_state)
			READ_A :begin
				if(in_valid2==1) idx_cnt<=idx_cnt+1;
				else if(idx_cnt==3) idx_cnt <= idx_cnt;	
				else idx_cnt <= 0;	
			end		
			default : idx_cnt <= 0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) cal_mod <= 0;
	else begin
		case(current_state)
			IDLE : cal_mod<=0;
			READ_A :begin
				if(in_valid2==1) begin
					if(idx_cnt==0) cal_mod<=mode;
					else cal_mod<=cal_mod;
				end
				else cal_mod<=cal_mod;			
			end	 
			default : cal_mod<=cal_mod;	
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) init_size <= 0;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid==1) begin
					if(address_cnt==0) init_size<=matrix_size;
					else init_size<=init_size;
				end
				else init_size<=0;
			end	 
			default : init_size<=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) size <= 0;
	else begin
		case(current_state)
			IDLE : begin
				if(in_valid==1) begin
					if(address_cnt==0) size<=0;
					else begin
						case(init_size)
							2'b00 : size<=2;
							2'b01 : size<=4;
							2'b10 : size<=8;
							2'b11 : size<=16;
						endcase
					end
				end
				else size<=size;
			end	 
			READ_A, READ_B, READ_C : size<=size;
			default : size<=size;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) A_AB<=0;
	else begin
		case(current_state)
			MUL : begin
				if(col_cnt==31) A_AB<=0;
				else if(row_cnt==16) A_AB<=0;
				else if(col_cnt==15) A_AB<=A_AB+1;
				else A_AB<=A_AB+1;
			end	 
			TRACE : A_AB<=A_AB+1;
			default : A_AB<=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) WEN_AB<=0;
	else begin
		case(current_state)
			MUL : begin
				if(col_cnt==31)WEN_AB<=0;
				else if(row_cnt==16) WEN_AB<=1;
				else if(col_cnt==15) WEN_AB<=0;
				else WEN_AB<=0;
			end	
			//READ_AB : WEN_AB<=1;
			TRACE : WEN_AB<=1;
			default : WEN_AB<=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) D_AB<=0;
	else begin
		case(current_state)
			MUL : begin
				if(col_cnt==31) D_AB <= A[0][0]*B[0][0]  +A[0][1]*B[1][0]  +A[0][2]*B[2][0]  +A[0][3]*B[3][0]+
										A[0][4]*B[4][0]  +A[0][5]*B[5][0]  +A[0][6]*B[6][0]  +A[0][7]*B[7][0]+
										A[0][8]*B[8][0]  +A[0][9]*B[9][0]  +A[0][10]*B[10][0]+A[0][11]*B[11][0]+
										A[0][12]*B[12][0]+A[0][13]*B[13][0]+A[0][14]*B[14][0]+A[0][15]*B[15][0];
				else if(row_cnt==16) D_AB<=D_AB;
				else D_AB <= A[row_cnt][0]*B[0][col_cnt]  +A[row_cnt][1]*B[1][col_cnt]  +A[row_cnt][2]*B[2][col_cnt]  +A[row_cnt][3]*B[3][col_cnt]+
							A[row_cnt][4]*B[4][col_cnt]  +A[row_cnt][5]*B[5][col_cnt]  +A[row_cnt][6]*B[6][col_cnt]  +A[row_cnt][7]*B[7][col_cnt]+
							A[row_cnt][8]*B[8][col_cnt]  +A[row_cnt][9]*B[9][col_cnt]  +A[row_cnt][10]*B[10][col_cnt]+A[row_cnt][11]*B[11][col_cnt]+
							A[row_cnt][12]*B[12][col_cnt]+A[row_cnt][13]*B[13][col_cnt]+A[row_cnt][14]*B[14][col_cnt]+A[row_cnt][15]*B[15][col_cnt];
			end	 
			default : D_AB<=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) trace<=0;
	else begin
		case(current_state) 
			TRACE : begin
				if(col_cnt==31) trace <= 0;
				else trace<=trace+AB*C[row_cnt][col_cnt];			
			end
			default : trace <= 0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) AB<=0;
	else begin
		case(current_state)
			MUL : AB<=Q_AB;				
			TRACE : begin
				if(col_cnt==31) AB<=Q_AB;
				else AB<=Q_AB;			
			end
			default : AB <= 0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) data_cnt<=0;
	else begin
		case(current_state)
			MUL : data_cnt<=data_cnt+1;
			default : data_cnt<=0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) trace_cnt <= 0;
	else begin
		case(current_state) 
			TRACE : begin
				if(col_cnt==31) trace_cnt <= 0;
				else trace_cnt<=trace_cnt+1;		
			end
			default : trace_cnt <= 0;
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<3;i=i+1)begin
			index[i] <=0;
		end		
	end
	else begin
		case(current_state) 
			READ_A : begin
				if(in_valid2==1) index[idx_cnt]<=matrix_idx;					
				else  begin
					index[0]<=index[0];
					index[1]<=index[1];
					index[2]<=index[2];		
				end		
			end
			READ_B, READ_C : begin
				index[0]<=index[0];
				index[1]<=index[1];
				index[2]<=index[2];		
			end
			default : begin
				for (i=0;i<3;i=i+1)begin
					index[i] <=0;
				end							
			end
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) switch<=0;
	else begin
		case(current_state) 
			READ_A : begin
				if(in_valid2==1) switch<=0;
				else if (idx_cnt==3) begin
					if(cal_counter<size*size && switch!=1) switch<=switch;
					else switch<=switch+1;
				end
				else  switch<=0;
			end
			READ_B : begin
				if(cal_counter<size*size && switch!=1) switch<=switch;
				else switch<=switch-1;	
			end
			READ_C : begin
				if(cal_counter<size*size && switch!=1) switch<=switch;
				else switch<=switch+1;	
			end
			default : 	switch<=0;					
		endcase	
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) cal_counter	<=0;
	else begin
		case(current_state) 
			READ_A : begin
				if(in_valid2==1) cal_counter<=0;
				else if (idx_cnt==3) begin
					if(cal_counter<size*size && switch!=1) begin					
						if(cal_mod==1) begin
							if (row_cnt==31) cal_counter<=0;
							else if (row_cnt<size-1) cal_counter <= cal_counter+1;
							else cal_counter <= cal_counter+1;
						end
						else begin
							if(col_cnt==31) cal_counter<=0;
							else if (col_cnt<size-1) cal_counter <= cal_counter+1;
							else cal_counter <= cal_counter+1;
						end
					end
					else cal_counter<=0;
				end
				else  cal_counter<=0;	
			end
			READ_B : begin
				if(cal_counter<size*size && switch!=1) begin					
					if(cal_mod==2) begin
						if (row_cnt==31) cal_counter<=0;
						else if (row_cnt<size-1) cal_counter <= cal_counter+1;
						else cal_counter <= cal_counter+1;
					end
					else begin
						if(col_cnt==31) cal_counter<=0;
						else if (col_cnt<size-1) cal_counter <= cal_counter+1;
						else cal_counter <= cal_counter+1;
					end
				end
				else cal_counter<=0;	
			end
			READ_C : begin
				if(cal_counter<size*size && switch!=1) begin					
					if(cal_mod==3) begin
						if (row_cnt==31) cal_counter<=0;
						else if (row_cnt<size-1) cal_counter <= cal_counter+1;
						else cal_counter <= cal_counter+1;
					end
					else begin
						if(col_cnt==31) cal_counter<=0;
						else if (col_cnt<size-1) cal_counter <= cal_counter+1;
						else cal_counter <= cal_counter+1;
					end
				end
				else cal_counter<=0;	
			end
			default : cal_counter<=0;						
		endcase	
	end
end


// Read A //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin	
		for (i=0;i<16;i=i+1)begin
			for (j=0;j<16;j=j+1)begin
				A[i][j] <= 0;
			end
		end	
	end
    else begin
		case(current_state)
			READ_A : begin
				if(in_valid2==1) begin
					for (i=0;i<16;i=i+1)begin
						for (j=0;j<16;j=j+1)begin
							A[i][j] <= 0;
						end
					end	
				end
				else if(idx_cnt==3) begin
					if(cal_counter<size*size && switch!=1) begin					
						if(cal_mod==1) begin
							if (row_cnt==31) begin
								for (i=0;i<16;i=i+1)begin
									for (j=0;j<16;j=j+1)begin
										A[i][j] <= 0;
									end
								end	
							end
							else if (row_cnt<size-1) A[row_cnt][col_cnt]<=Q_C;													
							else A[row_cnt][col_cnt]<=Q_C;
						end
						else begin
							if(col_cnt==31) begin
								for (i=0;i<16;i=i+1)begin
									for (j=0;j<16;j=j+1)begin
										A[i][j] <= 0;
									end
								end
							end						
							else if (col_cnt<size-1) A[row_cnt][col_cnt]<=Q_C;													
							else A[row_cnt][col_cnt]<=Q_C;
						end
					end
					else begin
						for (i=0;i<16;i=i+1)begin
							for (j=0;j<16;j=j+1)begin
								A[i][j] <= A[i][j];
							end
						end
					end
				end
				else begin
					for (i=0;i<16;i=i+1)begin
						for (j=0;j<16;j=j+1)begin
							A[i][j] <= 0;
						end
					end
				end
			end
			default : begin
				for (i=0;i<16;i=i+1)begin
					for (j=0;j<16;j=j+1)begin
						A[i][j] <= A[i][j];
					end
				end
			end
		endcase
	end
end

// Read B //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin	
		for (i=0;i<16;i=i+1)begin
			for (j=0;j<16;j=j+1)begin
				B[i][j] <= 0;
			end
		end	
	end
    else begin
		case(current_state)
			READ_A : begin
				for (i=0;i<16;i=i+1)begin
					for (j=0;j<16;j=j+1)begin
						B[i][j] <= 0;
					end
				end	
			end
			READ_B : begin
				if(cal_counter<size*size && switch!=1) begin					
					if(cal_mod==2) begin
						if (row_cnt==31) begin
							for (i=0;i<16;i=i+1)begin
								for (j=0;j<16;j=j+1)begin
									B[i][j] <= 0;
								end
							end	
						end
						else if (row_cnt<size-1) B[row_cnt][col_cnt]<=Q_C;													
						else B[row_cnt][col_cnt]<=Q_C;
					end
					else begin
						if(col_cnt==31) begin
							for (i=0;i<16;i=i+1)begin
								for (j=0;j<16;j=j+1)begin
										B[i][j] <= 0;
								end
							end
						end						
						else if (col_cnt<size-1) B[row_cnt][col_cnt]<=Q_C;													
						else B[row_cnt][col_cnt]<=Q_C;
					end
				end
				else begin
					for (i=0;i<16;i=i+1)begin
						for (j=0;j<16;j=j+1)begin
							B[i][j] <= B[i][j];
						end
					end
				end
			end
			default : begin
				for (i=0;i<16;i=i+1)begin
					for (j=0;j<16;j=j+1)begin
						B[i][j] <= B[i][j];
					end
				end
			end
		endcase
	end
end

// Read C //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin	
		for (i=0;i<16;i=i+1)begin
			for (j=0;j<16;j=j+1)begin
				C[i][j] <= 0;
			end
		end	
	end
    else begin
		case(current_state)
			READ_C : begin
				if(cal_counter<size*size && switch!=1) begin					
					if(cal_mod==3) begin
						if (row_cnt==31) begin
							for (i=0;i<16;i=i+1)begin
								for (j=0;j<16;j=j+1)begin
									C[i][j] <= 0;
								end
							end	
						end
						else if (row_cnt<size-1) C[row_cnt][col_cnt]<=Q_C;													
						else C[row_cnt][col_cnt]<=Q_C;
					end
					else begin
						if(col_cnt==31) begin
							for (i=0;i<16;i=i+1)begin
								for (j=0;j<16;j=j+1)begin
									C[i][j] <= 0;
								end
							end
						end						
						else if (col_cnt<size-1) C[row_cnt][col_cnt]<=Q_C;													
						else C[row_cnt][col_cnt]<=Q_C;
					end
				end
				else begin
					for (i=0;i<16;i=i+1)begin
						for (j=0;j<16;j=j+1)begin
							C[i][j] <= C[i][j];
						end
					end
				end
			end
			default : begin
				for (i=0;i<16;i=i+1)begin
					for (j=0;j<16;j=j+1)begin
						C[i][j] <= C[i][j];
					end
				end
			end
		endcase
	end
end

// row_counter //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) row_cnt <= 0;
    else begin
		case(current_state)
			IDLE : row_cnt<=31;
			READ_A : begin
				if(in_valid2==1) row_cnt<=31;
				else if(idx_cnt==3) begin
					if(cal_counter<size*size && switch!=1) begin
						if(cal_mod==1) begin
							if (row_cnt==31) row_cnt<=row_cnt+1;
							else if (row_cnt<size-1) row_cnt<=row_cnt+1;	
							else row_cnt<=0;
						end
						else begin
							if (col_cnt==31) row_cnt<=row_cnt+1;
							else if (col_cnt<size-1) row_cnt<=row_cnt;	
							else row_cnt<=row_cnt+1;
						end	
						
					end
					else row_cnt<=31;
				end
				else row_cnt<=31;
			end
			READ_B : begin
				if(cal_counter<size*size && switch!=1) begin
					if(cal_mod==2) begin			
						if (row_cnt==31) row_cnt<=row_cnt+1;
						else if(row_cnt<size-1) row_cnt<=row_cnt+1;
						else row_cnt<=0;
					end
					else begin
						if (col_cnt==31) row_cnt<=row_cnt+1;
						else if(col_cnt<size-1) row_cnt<=row_cnt;
						else row_cnt<=row_cnt+1;
					end

				end
				else row_cnt<=31;
			end	
			READ_C : begin
				if(cal_counter<size*size && switch!=1) begin
					if(cal_mod==3) begin			
						if (row_cnt==31) row_cnt<=row_cnt+1;
						else if(row_cnt<size-1) row_cnt<=row_cnt+1;
						else row_cnt<=0;
					end
					else begin
						if (col_cnt==31) row_cnt<=row_cnt+1;
						else if(col_cnt<size-1) row_cnt<=row_cnt;
						else row_cnt<=row_cnt+1;
					end
				end
				else row_cnt<=31;
			end
			MUL : begin
				if(col_cnt==31) row_cnt<=0;
				else if(row_cnt==16) row_cnt<=30;
				else if(col_cnt==15) row_cnt<=row_cnt+1;
				else row_cnt<=row_cnt;
			end
			TRACE : begin
				if(col_cnt==30 || col_cnt==31) row_cnt<=row_cnt+1;
				else if(row_cnt==15) row_cnt<=0;
				else row_cnt<=row_cnt+1;
			end
			default : row_cnt<=0;
		endcase
	end
end
// col_counter //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) col_cnt <= 0;
    else begin
		case(current_state)
			IDLE : col_cnt<=31;
			READ_A : begin
				if(in_valid2==1) col_cnt<=31;
				else if(idx_cnt==3) begin
					if(cal_counter<size*size && switch!=1) begin
						if(cal_mod==1) begin
							if (row_cnt==31) col_cnt<=col_cnt+1;
							else if (row_cnt<size-1) col_cnt<=col_cnt;	
							else col_cnt<=col_cnt+1;
						end
						else begin
							if (col_cnt==31) col_cnt<=col_cnt+1;
							else if (col_cnt<size-1) col_cnt<=col_cnt+1;	
							else col_cnt<=0;
						end
					end
					else col_cnt<=31;
				end
				else col_cnt<=31;
			end
			READ_B : begin
				if(cal_counter<size*size && switch!=1) begin
					if(cal_mod==2) begin			
						if (row_cnt==31) col_cnt<=col_cnt+1;
						else if (row_cnt<size-1) col_cnt<=col_cnt;	
						else col_cnt<=col_cnt+1;
					end
					else begin
						if (col_cnt==31) col_cnt<=col_cnt+1;
						else if (col_cnt<size-1) col_cnt<=col_cnt+1;	
						else col_cnt<=0;
					end
				end
				else col_cnt<=31;
			end	
			READ_C : begin
				if(cal_counter<size*size && switch!=1) begin
					if(cal_mod==3) begin
						if (row_cnt==31) col_cnt<=col_cnt+1;
						else if (row_cnt<size-1) col_cnt<=col_cnt;	
						else col_cnt<=col_cnt+1;
					end
					else begin
						if (col_cnt==31) col_cnt<=col_cnt+1;
						else if (col_cnt<size-1) col_cnt<=col_cnt+1;	
						else col_cnt<=0;
					end
				end
				else col_cnt<=31;
			end
			MUL : begin
				if(col_cnt==31) col_cnt<=1;
				else if(row_cnt==16) col_cnt<=30;
				else if(col_cnt==15) col_cnt<=0;
				else col_cnt<=col_cnt+1;
			end
			TRACE : begin
				if(col_cnt==30 || col_cnt==31) col_cnt<=col_cnt+1;
				else if(row_cnt==15) col_cnt<=col_cnt+1;
				else col_cnt<=col_cnt;
			end
			default : col_cnt<=0;
		endcase
	end
end
		
endmodule
