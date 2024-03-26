`ifdef RTL
	`timescale 1ns/1ps
	`define CYCLE_TIME_clk1 15.5
	`define CYCLE_TIME_clk2 18.3
`endif
`ifdef GATE
	`timescale 1ns/1ps
	`define CYCLE_TIME_clk1 15.5
	`define CYCLE_TIME_clk2 18.3
`endif

`define PAT_NUM 10


module PATTERN #(parameter DSIZE = 8,
			   parameter ASIZE = 4)(
	//Output Port
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

    //Input Port
    ready,
	out_valid,
	out,
	
); 
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg	rst_n, clk1, clk2, in_valid;
output reg [4:0]doraemon_id;
output reg [7:0]size;
output reg [7:0]iq_score;
output reg [7:0]eq_score;
output reg [2:0]size_weight,iq_weight,eq_weight;

input 	ready, out_valid;
input  [7:0] out;

//global
integer latency;
integer total_cycle;
integer total_latency;
integer i_pat;
integer i_in;
integer patnum = `PAT_NUM;
integer random_number;
integer max_latency;
integer answer_count;
integer input_cnt;

reg [4:0] id_buf[4:0];
reg [7:0] size_buf [4:0];
reg [7:0] iq_buf [4:0];
reg [7:0] eq_buf [4:0];
reg [13:0] score[4:0];
reg [2:0] max1,max2,max3,max4;
reg [7:0] size_in [5999:0];
reg [4:0] id [5999:0];
reg [7:0] eq [5999:0];
reg [7:0] iq [5999:0];
reg [2:0] size_w [5995:0];
reg [2:0] eq_w [5995:0];
reg [2:0] iq_w [5995:0];
reg [7:0] answer [5995:0];
reg  [12:0] output_cnt;



//================================================================
// clock
//================================================================
//reg clk;
real	CYCLE1 = `CYCLE_TIME_clk1;
real	CYCLE2 = `CYCLE_TIME_clk2;
always	#(CYCLE1/2.0) clk1 = ~clk1;
always	#(CYCLE2/2.0) clk2 = ~clk2;

// Wire & Reg //


//================================================================
// initial
//================================================================
initial begin
	for(i_pat = 0; i_pat < patnum; i_pat = i_pat + 1) begin
		max_latency = 0;
		reset_task;//spec3 spec4
		total_cycle = 0;
		output_cnt=0;
		input_cnt=0;
		gen_input_task;
		calculate_task;
		input_task;
		while(output_cnt<5996)begin
			input_task;
			wait_out_valid_task;
			if (out_valid==1)begin
				if(out!=answer[output_cnt]) begin
					$display("************************************************************");  
					$display("                      FAIL!  answer wrong                   "); 
					$display("     your answer : %d    but golden answer : %d  wrong output_cnt :%d ",out,answer[output_cnt],output_cnt); 
					$display("************************************************************");
					repeat(2) #CYCLE2;
					$finish;
				end
				else begin
					$display("PASSED No.%d output of PATTERN NO.%d", output_cnt, i_pat);
					output_cnt =output_cnt+1;
					//repeat(2) #CYCLE2;
				end					
			end
			else  begin
				if(out !=='b0) begin //out!==0
					$display("************************************************************");  
					$display("                      FAIL!                                  "); 
					$display("     When out_valid is low, output should be  zero!           "); 
					$display("************************************************************");
					//repeat(2) #CYCLE2;
					$finish;
				end
			end
				
		end
		$display("PASSED PATTERN NO.%d, total latency = %d", i_pat, total_latency);
	end
	$display ("----------------------------------------------------------------------------------------------------------------------");
	$display ("                                                  Congratulations!                                                    ");
	$display ("                                           You have passed all patterns!                                              ");
	$display ("----------------------------------------------------------------------------------------------------------------------");
	repeat(2) #CYCLE2;
	$finish;
end

//================================================================
// task
//================================================================

task reset_task; begin 
    rst_n = 'b1;
    in_valid = 'b0;
    doraemon_id = 'dx;
	size = 'dx;
	iq_score = 'dx;
	eq_score = 'dx;
	size_weight = 'dx;
	iq_weight = 'dx;
	eq_weight = 'dx;
    total_latency = 3;
    force clk1 = 0;
	force clk2 = 0;
    #CYCLE1; rst_n = 0; 
    #CYCLE1; rst_n = 1;
    if(out_valid !== 1'b0 || out !=='b0 || ready!==0) begin //out!==0
        $display("************************************************************");  
        $display("                    SPEC 3 IS FAIL!                         ");    
        $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
        $display("************************************************************");
        repeat(2) #CYCLE1;
        $finish;
    end
	#CYCLE1; release clk1;
	release clk2;
end endtask

integer t,i;
task input_task; begin
	if(input_cnt==0) begin
		t = $urandom_range(3, 5);
		for(i = 0; i < t; i = i + 1)begin
			if(out_valid !== 1'b0 || out !=='b0) begin //out!==0
				$display("************************************************************");  
				$display("                      SPEC 5 IS FAIL!                        ");    
				$display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
				$display("************************************************************");
				repeat(2) #CYCLE1;
				$finish;
			end    	
			@(negedge clk1);
		end
		for(i = 0; i < 4; i = i + 1)begin	
			in_valid = 1'b1;
			//if(out_valid==1)
			doraemon_id= id [i] ;
			size= size_in [i] ;
			iq_score= iq[i] ;
			eq_score = eq [i] ;
			input_cnt=3;
			@(negedge clk1);
		end
		
	end
	else begin
		// Main //
		if(input_cnt>=3 && input_cnt<6000) begin
			if(ready==1) begin	
				in_valid = 1'b1;
				
				doraemon_id= id[input_cnt+1] ;
				size= size_in [input_cnt+1] ;
				iq_score= iq[input_cnt+1] ;
				eq_score = eq[input_cnt+1] ;
				iq_weight=iq_w[input_cnt-3];
				eq_weight=eq_w[input_cnt-3];
				size_weight=size_w[input_cnt-3];
				input_cnt=input_cnt+1;
				@(negedge clk1);
			end
			else begin
				in_valid = 1'b0;
				doraemon_id = 'dx;
				size = 'dx;
				iq_score = 'dx;
				eq_score = 'dx;
				size_weight = 'dx;
				iq_weight = 'dx;
				eq_weight = 'dx;
				@(negedge clk1);
			end
		end
		else begin
			in_valid = 1'b0;
			doraemon_id = 'dx;
			size = 'dx;
			iq_score = 'dx;
			eq_score = 'dx;
			size_weight = 'dx;
			iq_weight = 'dx;
			eq_weight = 'dx;
			@(negedge clk1);
		end
	end
end endtask


integer j;
task calculate_task; begin
	//generate operation and inputs 
	for(i =0 ;i<5996;i=i+1) begin
		if (i==0)begin
			id_buf[0] = id[0];
			id_buf[1] = id[1];
			id_buf[2] = id[2];
			id_buf[3] = id[3];
			id_buf[4] = id[4];
			
			size_buf[0] = size_in[0];
			size_buf[1] = size_in[1];
			size_buf[2] = size_in[2];
			size_buf[3] = size_in[3];
			size_buf[4] = size_in[4];
			
			iq_buf[0] = iq[0];
			iq_buf[1] = iq[1];
			iq_buf[2] = iq[2];
			iq_buf[3] = iq[3];
			iq_buf[4] = iq[4];
			
			eq_buf[0] = eq[0];
			eq_buf[1] = eq[1];
			eq_buf[2] = eq[2];
			eq_buf[3] = eq[3];
			eq_buf[4] = eq[4];
			
			score[0]=size_buf[0]*size_w[i]+iq_buf[0]*iq_w[i]+eq_buf[0]*eq_w[i];
			score[1]=size_buf[1]*size_w[i]+iq_buf[1]*iq_w[i]+eq_buf[1]*eq_w[i];
			score[2]=size_buf[2]*size_w[i]+iq_buf[2]*iq_w[i]+eq_buf[2]*eq_w[i];
			score[3]=size_buf[3]*size_w[i]+iq_buf[3]*iq_w[i]+eq_buf[3]*eq_w[i];
			score[4]=size_buf[4]*size_w[i]+iq_buf[4]*iq_w[i]+eq_buf[4]*eq_w[i];

			if(score[0]>=score[1]) max1=0;
			else max1=1;
			if(score[2]>=score[3]) max2=2;
			else max2=3;
			if(score[max1]>=score[max2]) max3=max1;
			else max3=max2;
			if(score[max3]>=score[4]) max4=max3;
			else max4=4;
			answer[i]={max4,id_buf[max4]};
		
		end
		else begin
		
			id_buf[max4] = id[i+4];
			
			size_buf[max4] = size_in[i+4];
			
			iq_buf[max4] = iq[i+4];
			
			eq_buf[max4] = eq[i+4];
			
			score[0]=size_buf[0]*size_w[i]+iq_buf[0]*iq_w[i]+eq_buf[0]*eq_w[i];
			score[1]=size_buf[1]*size_w[i]+iq_buf[1]*iq_w[i]+eq_buf[1]*eq_w[i];
			score[2]=size_buf[2]*size_w[i]+iq_buf[2]*iq_w[i]+eq_buf[2]*eq_w[i];
			score[3]=size_buf[3]*size_w[i]+iq_buf[3]*iq_w[i]+eq_buf[3]*eq_w[i];
			score[4]=size_buf[4]*size_w[i]+iq_buf[4]*iq_w[i]+eq_buf[4]*eq_w[i];

			if(score[0]>=score[1]) max1=0;
			else max1=1;
			if(score[2]>=score[3]) max2=2;
			else max2=3;
			if(score[max1]>=score[max2]) max3=max1;
			else max3=max2;
			if(score[max3]>=score[4]) max4=max3;
			else max4=4;
			answer[i]={max4,id_buf[max4]};
		end
	end
    // $display("a = %d b = %d ",a,b);
end endtask

task gen_input_task; begin
	//generate operation and inputs 
	for(i =0 ;i<6000;i=i+1) begin
		size_in[i]=$urandom_range(50, 200);
		id[i]=$urandom_range(0, 31);
		iq[i]=$urandom_range(50, 200);
		eq[i]=$urandom_range(50, 200);
	end
	for(j=0;j<5996;j=j+1) begin
			iq_w[j]=$urandom_range(0, 7);
			eq_w[j]=$urandom_range(0, 7);
			size_w[j]=$urandom_range(0, 7);
	end

    // $display("a = %d b = %d ",a,b);
end endtask

task wait_out_valid_task; begin
    latency = 0;
	latency = latency + 1;
      if( total_latency  == 100000) begin
          $display("********************************************************");     
          $display("                  SPEC 6 IS FAIL!                       ");
          $display("*  The execution latency are over 100000 cycles  at %8t   *",$time);//over max
          $display("********************************************************");
	    repeat(2)@(negedge clk2);
	    $finish;
      end
     //@(negedge clk1);
   total_latency = total_latency + latency ;
end endtask

endmodule 