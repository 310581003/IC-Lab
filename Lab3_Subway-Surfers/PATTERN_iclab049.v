`ifdef RTL
    `define CYCLE_TIME 10.0
`endif
`ifdef GATE
    `define CYCLE_TIME 10.0
`endif
`define PAT_NUM 300

module PATTERN(
    // Output Signals
    clk,
    rst_n,
    in_valid,
    init,
    in0,
    in1,
    in2,
    in3,
    // Input Signals
    out_valid,
    out
);


/* Input for design */
output reg       clk, rst_n;
output reg       in_valid;
output reg [1:0] init;
output reg [1:0] in0, in1, in2, in3; 


/* Output for pattern */
input            out_valid;
input      [1:0] out; 

//global
integer latency;
integer total_cycle;
integer total_latency;
integer i_pat;
integer patnum = `PAT_NUM;
integer random_number;
integer max_latency;
integer answer_count;
//================================================================
// clock
//================================================================
//reg clk;
real	CYCLE = `CYCLE_TIME;
always	#(CYCLE/2.0) clk = ~clk;


// Wire & Reg //
reg [1:0] train_interval_num [7:0];
reg [1:0] train_interval_place [2:0][7:0];
reg [1:0] map [3:0][63:0];
reg [2:0] row,initial_state,col;
reg [5:0] count;
reg [1:0] before_map,train_num,flag;
reg hit_low,out_side,hit_high,hit_train,nojump,in_valid_num;
//================================================================
// initial
//================================================================
initial begin

	max_latency = 0;
	reset_task;
	total_cycle = 0;
  	for (i_pat = 0; i_pat < patnum; i_pat = i_pat + 1)begin
		hit_low=0;
		hit_high=0;
		out_side=0;
		nojump=0;
		hit_train=0;
		input_task;
        wait_out_valid_task;
		for (answer_count = 0; answer_count < 63; answer_count = answer_count + 1)begin        
	        if (out_valid === 1) begin
				if (answer_count===0)begin
				    row=initial_state;
					count = 1;
					move_task;
					check_ans_task;	
				end
				else begin
					before_map=map[row][count];
					count= count+1;
					move_task;					
					check_ans_task;	
				end
	        end
	        else if (out_valid !== 1) begin
				$display("************************************************************");  
				$display("                     SPEC 7 IS FAIL!                        ");    
				$display("************************************************************");
				$finish;
	        end
	       	@(negedge clk);
	    end
	    if(out_valid !== 1'b0 || out !=='b0) begin //out!==0
	        $display("************************************************************");  
	        $display("                     SPEC 7 IS FAIL!                        ");    
	        $display("************************************************************");
	        $finish;
	    end
		else if(out_side==1) begin
			$display("************************************************************");  
	        $display("                    SPEC 8-1 IS FAIL!                       ");    
	        $display("************************************************************");
			$finish;
		end
		else if(hit_low==1) begin
			$display("************************************************************");  
	        $display("                    SPEC 8-2 IS FAIL!                       ");    
	        $display("************************************************************");
			$finish;
		end
		else if(hit_high==1) begin
			$display("************************************************************");  
	        $display("                    SPEC 8-3 IS FAIL!                       ");    
	        $display("************************************************************");
			$finish;
		end
		else if(hit_train==1) begin
			$display("************************************************************");  
	        $display("                    SPEC 8-4 IS FAIL!                       ");    
	        $display("************************************************************");
			$finish;
		end
		else if(nojump==1) begin
			$display("************************************************************");  
	        $display("                    SPEC 8-5 IS FAIL!                       ");    
	        $display("************************************************************");
			$finish;
		end
	
    end
	$display("************************************************************");  
	$display("                    Congratulations!                        ");
	$display ("                  Total Cycle : %d                         ",total_latency);
	$display("************************************************************");
	$finish;
end

//================================================================
// task
//================================================================

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    in_valid_num = 'b0;
    init = 4'dx;
	in0 = 4'dx;
	in1 = 4'dx;
	in2 = 4'dx;
	in3 = 4'dx;
    total_latency = 0;
    force clk = 0;
    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    if(out_valid !== 1'b0 || out !=='b0) begin //out!==0
        $display("************************************************************");  
        $display("                    SPEC 3 IS FAIL!                         ");    
        $display("************************************************************");
        $finish;
    end
	#CYCLE; release clk;
end endtask

integer t,i;
task input_task; begin
    t = $urandom_range(2, 4);
    for(i = 0; i < t; i = i + 1)begin
    	if(out_valid === 1'b0 && out !=='b0) begin //out!==0
    	    $display("************************************************************");  
    	    $display("                      SPEC 4 IS FAIL!                        ");    
    	    $display("************************************************************");
    	    $finish;
    	end    	
		@(negedge clk);
	end
	//initial_state = $urandom_range(0, 3);
	gen_map_task;
	// Main //
	for(i = 0; i < 64; i = i + 1)begin	
		if(i === 0)begin
			in_valid = 1'b1;
			init = initial_state;
			if(out_valid !== 1'b0) begin //out!==0
				$display("************************************************************");  
				$display("                     SPEC 5 IS FAIL!                        ");    
				$display("************************************************************");
				$finish;
			end
		end
		else begin
			in_valid = 1'b1;
			init = 'bx;
			if(out_valid !== 1'b0) begin //out!==0
				$display("************************************************************");  
				$display("                     SPEC 5 IS FAIL!                        ");    
				$display("************************************************************");
				$finish;
			end
		end
		//if(out_valid==1)
		in0= map [0][i] ;
		in1= map [1][i] ;
		in2= map [2][i] ;
		in3= map [3][i] ;
	    @(negedge clk);
	end
		
	in_valid_num = 1'b0;	
    in_valid = 1'b0;
	col = 'bx;
    row = 'bx;
end endtask
integer j;
task gen_map_task; begin
	//generate operation and inputs 
	for(i =0 ;i<64;i=i+1) begin
		for(j=0;j<4;j=j+1) begin
			map[j][i]=0;
		end
	end
    for(i = 0; i < 64; i = i + 1)begin	
		if (i%2==0 && i%8!=0)begin
			for (j=0;j<4;j=j+1)begin
				map [j][i] = $urandom_range(0, 2);
			end
		end
		else begin
			for (j=0;j<4;j=j+1)begin
				map [j][i] = 2'b00;
			end
		end
	end
	for(i = 0; i < 64; i = i + 1)begin
		if (i%8==0)begin
			train_num = $urandom_range(1, 3);
			for (j=0;j<train_num;j=j+1)begin
				flag = $urandom_range(0, 3);
				map [flag][i] = 2'b11;
				map [flag][i+1] = 2'b11;
				map [flag][i+2] = 2'b11;
				map [flag][i+3] = 2'b11;
			end
		end	
	end
	initial_state = $urandom_range(0, 3);
	while( map[initial_state][0]==2'b11) begin
		initial_state = $urandom_range(0, 3);
	end	
	
    // $display("a = %d b = %d ",a,b);
end endtask


task wait_out_valid_task; begin
    latency = 0;
    while(out_valid !== 1'b1) begin
	latency = latency + 1;
      if( latency == 3000) begin
          $display("********************************************************");     
          $display("                  SPEC 6 IS FAIL!                         ");
          $display("********************************************************");
		  $finish;
      end
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask
////////////////////////////////////////////////////////////////////////////

task move_task;begin
	
	case(out)
		2'b00 : row=row;
		2'b01 : begin
			if(row==3)
				out_side=1;
			else
				row=row+1;
		end
		2'b10 : begin
			if(row==0)
				out_side=1;
			else
				row=row-1;
		end
		2'b11 : row=row;
	endcase
	
end endtask


task check_ans_task; begin
	case(out)
		2'b00 : begin
			if (map[row][count]==2'b01)
				hit_low = 1;
			else if(map[row][count]==2'b11)
				hit_train=1;
			else hit_low = hit_low;
		end
		2'b01 : begin
			if (map[row][count]==2'b01) hit_low = 1;
			else if (map[row][count]==2'b10) hit_high = 1;
			else if (map[row][count]==2'b11) hit_train = 1;
			else hit_train  = hit_train ;			
		end
		2'b10 : begin
			if (map[row][count]==2'b01) hit_low = 1;
			else if (map[row][count]==2'b10) hit_high = 1;
			else if (map[row][count]==2'b11) hit_train = 1;
			else hit_train  = hit_train ;		
		end	
		2'b11 : begin
			if (map[row][count]==2'b10) hit_high = 1;
			else if (map[row][count]==2'b11) hit_train = 1;
			else if(before_map==1) nojump=1;
			else hit_train  = hit_train ;		
		end	
	endcase
end endtask



always @(*) begin
	if(latency > max_latency) begin
		max_latency = latency;
	end 
end

endmodule
