
`ifdef RTL
	`timescale 1ns/10ps
	`include "MMT.v"
	`define CYCLE_TIME 20.0
`endif
`ifdef GATE
	`timescale 1ns/10ps
	`include "MMT_SYN.v"
	`define CYCLE_TIME 20.0
`endif

`define PAT_NUM 100

module PATTERN(
// output signals
    clk,
    rst_n,
    in_valid,
	in_valid2,
    matrix,
	matrix_size,
    matrix_idx,
    mode,
// input signals
    out_valid,
    out_value
);
//================================================================
//   parameters & integers
//================================================================
parameter PATNUM=`PAT_NUM;

integer patcount,answer_count;
integer cycles;
integer total_cycles,total_latency;
integer latency;
integer Input_text,Output_text;
//================================================================
//   INPUT AND OUTPUT DECLARATION                         
//================================================================
output reg 		  clk, rst_n, in_valid, in_valid2;
output reg [7:0] matrix;
output reg [1:0]  matrix_size,mode;
output reg [4:0]  matrix_idx;

input 				out_valid;
input signed [49:0] out_value;
//================================================================
//    wires % registers
//================================================================
reg [7:0] element;
reg [1:0] size,pat_mode;
reg [4:0] index;
reg signed [49:0] golden_ans;
//================================================================
// clock
//================================================================
real CYCLE = `CYCLE_TIME;
always	#(`CYCLE_TIME/2.0) clk = ~clk;
initial	clk = 0;

//================================================================
//    initial
//================================================================

initial begin
	Input_text = $fopen("../00_TESTBED/input.txt" , "r");
	Output_text = $fopen("../00_TESTBED/output.txt", "r");		
	force clk = 0;
	total_cycles = 0;
	total_latency = 0;
	reset_task;
	@(negedge clk);
	
	for (patcount=0;patcount<PATNUM;patcount=patcount+1)begin
		cycles = 0;
		input_element_task;		
		for (answer_count = 0; answer_count < 10; answer_count = answer_count + 1)begin
			input_index_task;
			wait_out_valid;
			if (out_valid === 1) begin
		        check_ans;
	        end
	       	@(negedge clk);
	    end			 
		$display("\033[0;34mPASS PATTERN NO.%4d,\033[m \033[0;32m Cycles: %3d\033[m", patcount ,latency);
	end
	
	#(1000);
	YOU_PASS_task;
	$fclose(Input_text);
    $fclose(Output_text);
    $finish;
end
//================================================================
// task
//================================================================

task reset_task; begin 
	rst_n      = 1'b1;
	in_valid   = 1'b0;
	in_valid2   = 1'b0;
	matrix = 'bx; 
	matrix_size = 32'bx;
	mode = 32'bx;
	matrix_idx   = 32'bx;	
    
    #CYCLE; rst_n = 0; 
    #CYCLE; rst_n = 1;
    if(out_valid !== 1'b0 || out_value !=='b0) begin //out!==0
        $display("************************************************************");  
        $display("                    SPEC 3 IS FAIL!                         ");
		$display("                Output should be reset!                     ");
        $display("************************************************************");
        $finish;
    end
	#CYCLE; release clk;
end endtask

integer i, t1,t2,num_element;
task input_element_task; begin
    t1 = $urandom_range(1, 5);
    for(i = 0; i < t1; i = i + 1)begin
    	if(out_valid !== 1'b0 || out_value !=='b0) begin //out!==0
    	    $display("************************************************************");  
    	    $display("                    SPEC 4 IS FAIL!                          ");    
    	    $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
    	    $display("************************************************************");
    	    repeat(2) #CYCLE;
    	    $finish;
    	end    	
		@(negedge clk);
	end
	$fscanf(Input_text, "%d\n",size);
	num_element = 2**(2*(size+1));

	for(i = 0; i < 32*num_element; i = i + 1)begin
		in_valid2 = 1'b0;
		if(i === 0)begin
			in_valid = 1'b1;
			matrix_size = size;
		end
		else begin
			in_valid = 1'b1;
			matrix_size = 'bx;
		end
		$fscanf(Input_text, "%d\n",element);
		matrix = element;
	    @(negedge clk);
	end	
    in_valid = 1'b0;
	matrix = 'bx;
    matrix_size = 'bx;
end endtask 

task input_index_task; begin
	t2 = $urandom_range(1, 3);
    for(i = 0; i < t2; i = i + 1)begin
    	if(out_valid !== 1'b0 || out_value !=='b0) begin //out!==0
    	    $display("************************************************************");  
    	    $display("                   SPEC 4 IS FAIL!                           ");    
    	    $display("*  Output signal should be 0 after initial RESET  at %8t   *",$time);
    	    $display("************************************************************");
    	    repeat(2) #CYCLE;
    	    $finish;
    	end    	
		@(negedge clk);
	end
	$fscanf(Input_text, "%d\n",pat_mode);
	for(i = 0; i < 3; i = i + 1)begin
		in_valid2 = 1'b1;
		if(i === 0)begin
			mode = pat_mode;
		end
		else begin
			mode = 'bx;
		end
		$fscanf(Input_text, "%d\n",index);
		matrix_idx = index;
	    @(negedge clk);
	end	
    in_valid2 = 1'b0;
	matrix_idx = 'bx;
    mode = 'bx;	
end endtask 

task wait_out_valid ; 
begin
	
	latency = -1;
	while(out_valid === 0)begin
		if(out_value !== 0) begin 
			$display ( "----------------------------------------------------------------------------------\n");
			$display ( "                               SPEC 5 IS FAIL!                                   \n");
			$display ( "        The out should be reset after your out_valid is pulled down.             \n");
			$display ( "----------------------------------------------------------------------------------\n");
			repeat(2)@(negedge clk);
			$finish;
		end
		cycles = cycles + 1;
		latency=latency+1;
		if(latency == 10000) begin
			$display ("----------------------------------------------------------------------------------");
			$display ("                                 SPEC 6 IS FAIL!                                  ");
			$display ("                      The execution latency are over 10000 cycles                   ");
			$display ("----------------------------------------------------------------------------------");
			repeat(2)@(negedge clk);
			$finish;
		end
		cycles = cycles+1;
		@(negedge clk);
	end
	total_cycles = total_cycles + cycles;
end 
endtask

integer out_count;
task check_ans; begin
	out_count = 0;
    while(out_valid===1'b1) begin
        if(out_count>=1) begin
            $display ("-------------------------------------------------------------------");
            $display ("                    out_valid is more than 1 cycle                 ");
            $display ("-------------------------------------------------------------------");
            repeat(2) @(negedge clk);
            $finish;
        end
		
		$fscanf(Output_text, "%d\n",golden_ans);
		if(out_value !== golden_ans) begin
			$display ("-------------------------------------------------------------------");
			$display ("                   %d/10  Testing Error                           ", answer_count+1);			
			$display("                      Your answer   =                               ",out_value);
			$display("                      Golden answer =                               ",golden_ans);
			$display ("-------------------------------------------------------------------");
			repeat(2) @(negedge clk);
			$finish;
		end		

        @(negedge clk);	
		cycles = cycles+1;
		out_count = out_count+1;
    end
	total_cycles = total_cycles + cycles;
end endtask

task YOU_PASS_task; begin
	$display ("-------------------------------------------------------------------------");
	$display ("                         Congratulations!                                ");
	$display ("                   You have passed all patterns!                         ");
	$display ("                   Your execution cycles = %5d cycles                    ", total_cycles);
	$display ("                   Your clock period = %.1f ns                           ", `CYCLE_TIME);
	$display ("                   Your total latency = %.1f ns                          ", total_cycles*`CYCLE_TIME);
	$display ("-------------------------------------------------------------------------");
	$finish;
end endtask
endmodule