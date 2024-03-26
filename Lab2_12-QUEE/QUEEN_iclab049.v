module QUEEN(
    //Input Port
    clk,
    rst_n,

    in_valid,
    col,
    row,

    in_valid_num,
    in_num,

    out_valid,
    out

    );
input               clk, rst_n, in_valid,in_valid_num;
input       [3:0]   col,row;
input       [2:0]   in_num;

output reg          out_valid;
output reg  [3:0]   out;

//==============================================//
//             Parameter and Integer            //
//==============================================//
reg [2:0] current_state, next_state;
reg a,b,in_flag;
//reg a_flag;
//reg a [11:0];
reg [3:0] mem_row [11:0] ;
reg [3:0] mem_col [11:0] ;
reg [3:0] mem_out [11:0] ;
reg [3:0] w_num,count,col_num,row_num,out_num,q,order,counter_2;
parameter IDLE=3'b000;
//parameter DATA_IN=3'b001;
parameter Q_PLACE=3'b001;
parameter CHECK=3'b010;
parameter BACK=3'b011;
parameter OUT=3'b100;


integer i,j;

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end


//next_state
always@(*) begin
        case(current_state)
                IDLE:
                begin
                        if (count<w_num-1 || in_valid==1)
                                next_state=IDLE;
                        else
                                next_state=Q_PLACE;
                end
                //DATA_IN:
                //begin
                        
						//if (count==w_num) next_state=Q_PLACE;
            
						//else 
						//next_state=DATA_IN;
				//end
				
				Q_PLACE:
				begin
					if(row_num==12) begin
						next_state=BACK;
					end
					else
						next_state=CHECK;
				end
				CHECK :
				begin
				
				if(col_num==12)begin
					next_state=OUT;
				end
				//else if(row_num==12) begin
						//next_state=BACK;
				//end
				else
					next_state=Q_PLACE;
				end
				BACK : 
				begin
						next_state=Q_PLACE;
				end

                OUT:
                begin
                        if(order != 4'd11)
                                next_state = OUT;
                        else
                                next_state = IDLE;
                end
                default:
                        next_state = IDLE;
        endcase
end


always @(posedge clk or negedge rst_n) begin
    
    if(!rst_n) begin
		//num <= 0;
        w_num<=0;
		count <= 0;
        col_num<=0;
        row_num<=0;
		a<=0;
		order<=0;
		for (j=0;j<12;j=j+1)begin		
			mem_row [j]<=0;
			mem_col [j]<=0;
			mem_out[j]<=0;
			//a[j] <= 0;
		end
		out_valid<=0;
		out <=0;
		q<=0;
		b<=0;
    end
    else begin
        case(current_state)
            IDLE : begin
				
                if(in_valid==1 || (in_valid_num==1)) begin      
                    //num<=in_num;
					if (in_valid_num==1) begin
					w_num<=in_num;
					mem_row[count]<=row;
                    mem_col[count]<=col;
					mem_out[col]<=row;
                    count<=count+1;
					out_valid<=0;
					out<=0;
					a<=0;
					b<=0;
					end
					else begin
						mem_row[count]<=row;
						mem_col[count]<=col;
						mem_out[col]<=row;
						count<=count+1;
						out_valid<=0;
						out<=0;
						a<=0;
						b<=0;
					end
					
				end
				// else if (in_flag==1)begin
                     // mem_row[count]<=row;
                     // mem_col[count]<=col;
					 // mem_out[col]<=row;
                     // count<=count+1; 					
                // end
                else begin
					//num <= 0;
					w_num<=w_num;
					count <= count;
					col_num<=0;
					row_num<=0;
					a<=0;
					order<=0;
					//for (j=0;j<12;j=j+1)begin		
						//mem_row [j]<=mem_row [j];
						//mem_col [j]<=mem_col [j];
						//mem_out[j]<=0;
						//a[j] <= 0;
					//end
					out_valid<=0;
					out <=0;
					q<=0;
					b<=0;
					//a_falg<=0;
				end
            end
            //DATA_IN: begin 
                     //mem_row[count]<=row;
                     //mem_col[count]<=col;
					 //mem_out[col]<=row;
                     //count<=count+1;               
            //end
            Q_PLACE : begin
					in_flag <=0;
					q<=w_num-1;
					for(i=0;i<12;i=i+1) begin
					if (i<w_num)begin
						if(row_num-mem_row[i]!=0 && col_num-mem_col[i]!=0)begin
							if((row_num>mem_row[i]) && (col_num>mem_col[i]))begin
								if(row_num-mem_row[i]==col_num-mem_col[i])
									a<=1;
								else
									counter_2<=0;
							end
							else if((row_num<mem_row[i]) && (col_num>mem_col[i]) )begin
								if(mem_row[i]-row_num==col_num-mem_col[i])
									a<=1;
								else
									counter_2<=0;
							end
							else if((row_num<mem_row[i]) && (col_num<mem_col[i]))begin	
								if(mem_row[i]-row_num==mem_col[i]-col_num)
									a<=1;
								else
									counter_2<=0;
							end								
							else if((row_num>mem_row[i]) && (col_num<mem_col[i]) )begin
								if(row_num-mem_row[i]==mem_col[i]-col_num)
									a<=1;
								else
									counter_2<=0;
							end							
							else begin
								counter_2<=0;
							end
						end
						else if(col_num-mem_col[i]==0)
							b<=1;
						else begin
							if(row_num-mem_row[i]==0)begin
								a<=1;
							end
							else begin
								counter_2<=0;
							end
						end
					end
					else begin
						counter_2<=0;
					end
				end
			end
			
			
			CHECK :
			begin
				
				if(a==0  && b==0) begin
					mem_row[w_num]<=row_num;
					mem_col[w_num]<=col_num;
					mem_out[col_num]<=row_num;
					w_num<=w_num+1;
					row_num<=0;
					col_num<=col_num+1;
					a<=0;
					b<=0;
				end
				else if(b==1)begin
					row_num<=0;
					col_num<=col_num+1;	
					b<=0;
					a<=0;
				end

				else begin
					row_num<=row_num+1;
					a<=0;
					b<=0;
				end

            end
	
			BACK :
			begin
				w_num<=w_num-1;
                row_num <= mem_row[q]+1;
                col_num <= mem_col[q];
				a<=0;
				b<=0;				
				
			end				
            OUT : begin
				//for (j=0;j<12;j=j+1)begin		
					//mem_row [j]<=0;
					//mem_col [j]<=0;
					
				//end
				w_num<=0;
				count <= 0;
				out_valid<=1;
				out<=mem_out[order];
				order<=order+1;
				//if(order==12) begin
					//out_valid<=0;
					//out<=0;
				//end
				//else
					//out_valid<=1;
            end
            default: begin
				//w_num<=in_num;
				//col_num<=0;
				//row_num<=0;
				//a<=0;
				//for (k=0;k<12;k=k+1)begin		
					//mem_row [k]<=0;
					//mem_col [k]<=0;
					//mem_out[k]<=0;
				//end
				out_valid<=0;
				out <=0;
			end
            endcase
       end
end

	
endmodule
