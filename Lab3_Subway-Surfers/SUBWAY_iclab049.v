module SUBWAY(
    // Input Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Output Signals
    out_valid,
    out
);


/* Input for design */
input       clk, rst_n;
input       in_valid;
input [1:0] init;
input [1:0] in0, in1, in2, in3; 


/* Output for pattern */
output reg            out_valid;
output reg      [1:0] out; 

// Wire or Reg //
reg [1:0] current_state, next_state;
reg [5:0]col_count,in_count, out_count; 
reg [1:0]future_map[0:3][0:63];
reg [1:0] current_row;
reg  [1:0]out_mem[0:62];
reg [2:0] flag;

// Integer or Parameter //
integer i,j,k;
parameter IDLE=2'b00;
parameter MOVE=2'b01;
parameter FORSEE=2'b10;
parameter OUT=2'b11;


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
        case(current_state)
                IDLE: begin
					if(in_count<5)
                        next_state=IDLE;
					else
						next_state=MOVE;
                end
				
				MOVE : begin
						if (col_count%8==4)
							next_state = FORSEE;
						else if (col_count==63)
							next_state = OUT;
						else
							next_state = MOVE;
				end
				
				FORSEE : begin
						next_state = MOVE;			
				end
				
				OUT : begin
					if (out_count==62)
						next_state = IDLE;
					else
						next_state = OUT;
				end
				//default: next_state = IDLE;
        endcase		
end


always @(posedge clk or negedge rst_n) begin
    
    if(!rst_n) begin
        col_count<=1;
		in_count <=0;
		out_count <=0;
		flag <=0;
		current_row <=0;
		for (i=0;i<64;i=i+1)begin
		  for(j=0;j<4;j=j+1) begin		
			future_map[j][i]<=0;
            end
		end
		for (k=0;k<63;k=k+1)begin		
			out_mem[j]<=0;
		end
		
		out_valid<=0;
		out <=0;
    end
    else begin
        case(current_state)
            IDLE : begin
				if (in_valid==1 && in_count==0)begin
					current_row <= init;
					future_map[0][in_count]<=in0;
					future_map[1][in_count]<=in1;
					future_map[2][in_count]<=in2;
					future_map[3][in_count]<=in3;
					in_count<=in_count+1;
				end
				else if (in_valid==1 && in_count!=0)begin
					future_map[0][in_count]<=in0;
					future_map[1][in_count]<=in1;
					future_map[2][in_count]<=in2;
					future_map[3][in_count]<=in3;
					in_count<=in_count+1;
				end
				else begin
					out_valid<=0;
					out <=0;
					current_row <=0;					
					col_count<=1;
					in_count <=0;
					out_count <=0;
					flag <=0;
				end		
			end
			
			MOVE : begin
				
				if (in_valid==1 )begin
					future_map[0][in_count]<=in0;
					future_map[1][in_count]<=in1;
					future_map[2][in_count]<=in2;
					future_map[3][in_count]<=in3;
					in_count<=in_count+1;
				end	
				else
					in_count<=0;
				
				
				if (flag == 3'd0 || flag == 3'd4) begin
					case (future_map[current_row][col_count])
					
						2'b00 : out_mem [col_count-1] <= 2'b00;						
						2'b01 : out_mem [col_count-1] <= 2'b11;		
						2'b10 : out_mem [col_count-1] <= 2'b00;
						default : out_mem [col_count-1] <= 0;
					endcase					
					flag <=0;	
					col_count<=col_count+1;
					current_row <= current_row;
				end
				else if( flag <=7  && flag >= 5)begin
					case (future_map[current_row-1][col_count])					
						2'b00 : begin
							flag <= flag-1;	
							col_count<=col_count+1;
							current_row <= current_row-1;
							out_mem [col_count-1] <= 2'b10;	
						end
						2'b01 : begin
							flag <= flag;
							col_count<=col_count+1;
							current_row <= current_row;
							if(future_map[current_row][col_count]==2'b01) out_mem [col_count-1] <= 2'b11;
							else out_mem [col_count-1] <= 2'b00;									
						end
						2'b10 : begin
							flag <= flag;
							col_count<=col_count+1;
							current_row <= current_row;
							if(future_map[current_row][col_count]==2'b01) out_mem [col_count-1] <= 2'b11;
							else out_mem [col_count-1] <= 2'b00;								
						end
						default : begin
							out_mem [col_count-1] <= 0;
							flag <= 0;
							current_row <= current_row;
						end
					endcase

				end	
				else if( flag >= 1 && flag <= 3'd3)begin
					case (future_map[current_row+1][col_count])					
						2'b00 : begin
							flag <= flag-1;	
							col_count<=col_count+1;
							current_row <= current_row+1;						
							out_mem [col_count-1] <= 2'b01;	
						end
						2'b01 : begin
							flag <= flag;
							col_count<=col_count+1;
							current_row <= current_row;
							if(future_map[current_row][col_count]==2'b01) out_mem [col_count-1] <= 2'b11;
							else out_mem [col_count-1] <= 2'b00;			
						end
						2'b10 : begin
							flag <= flag;
							col_count<=col_count+1;
							current_row <= current_row;
							if(future_map[current_row][col_count]==2'b01) out_mem [col_count-1] <= 2'b11;
							else out_mem [col_count-1] <= 2'b00;								
						end
						default : begin
							out_mem [col_count-1] <= 0;
							flag <= 0;
							current_row <= current_row;
						end
					endcase
				end
				else 
					flag <= 3'd0;
			end
			
			FORSEE : begin
				if (in_valid==1 )begin
					future_map[0][in_count]<=in0;
					future_map[1][in_count]<=in1;
					future_map[2][in_count]<=in2;
					future_map[3][in_count]<=in3;
					in_count<=in_count+1;
				end	
				else begin
					in_count<=0;
				end

				if (future_map[current_row][col_count+4]==2'b00)flag <= 3'd0;
				else if (future_map[current_row][col_count+4]!=2'b00)begin
					case(current_row)
						2'd0 : begin
							if (future_map[current_row+1][col_count+4]==2'b00) flag <= 3'd1;
							else if (future_map[current_row+2][col_count+4]==2'b00) flag <= 3'd2;
							else if (future_map[current_row+3][col_count+4]==2'b00)flag <= 3'd3;
							else flag<=flag;						
						end
						2'd1: begin
							if (future_map[current_row+1][col_count+4]==2'b00) flag <= 3'd1;
							else if (future_map[current_row+2][col_count+4]==2'b00) flag <= 3'd2;
							else if (future_map[current_row-1][col_count+4]==2'b00)flag <=  3'd5;
							else flag<=flag;
						end
						2'd2: begin
							if (future_map[current_row+1][col_count+4]==2'b00) flag <= 3'd1;
							else if (future_map[current_row-1][col_count+4]==2'b00)flag <= 3'd5;
							else if (future_map[current_row-2][col_count+4]==2'b00)flag <= 3'd6;
							else flag<=flag;
						end
						2'd3: begin
							if (future_map[current_row-1][col_count+4]==2'b00)flag <= 3'd5;
							else if (future_map[current_row-2][col_count+4]==2'b00)flag <= 3'd6;
							else if (future_map[current_row-3][col_count+4]==2'b00)flag <= 3'd7;
							else flag<=flag;
						end					
					endcase
				end
				else flag<=flag;
			end
			OUT : begin
				out_valid <=1;
				out <= out_mem [out_count];
				out_count<=out_count+1;
				current_row <=0;					
				col_count<=1;
				flag <= 0;
			end
			//default : begin
				//current_row <=0;					
				//col_count<=1;
				//out<=0;
				//out_valid<=0;
				//left_flag <= 0;
				//right_flag <= 0;
			//end
		endcase
	end
end
endmodule
