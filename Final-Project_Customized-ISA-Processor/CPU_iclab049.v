
module CPU(

				clk,
			  rst_n,
  
		   IO_stall,

         awid_m_inf,
       awaddr_m_inf,
       awsize_m_inf,
      awburst_m_inf,
        awlen_m_inf,
      awvalid_m_inf,
      awready_m_inf,
                    
        wdata_m_inf,
        wlast_m_inf,
       wvalid_m_inf,
       wready_m_inf,
                    
          bid_m_inf,
        bresp_m_inf,
       bvalid_m_inf,
       bready_m_inf,
                    
         arid_m_inf,
       araddr_m_inf,
        arlen_m_inf,
       arsize_m_inf,
      arburst_m_inf,
      arvalid_m_inf,
                    
      arready_m_inf, 
          rid_m_inf,
        rdata_m_inf,
        rresp_m_inf,
        rlast_m_inf,
       rvalid_m_inf,
       rready_m_inf 

);
// Input port
input  wire clk, rst_n;
// Output port
output reg  IO_stall;

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
  your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
  therefore I declared output of AXI as wire in CPU
*/



// axi write address channel 
output  wire [WRIT_NUMBER * ID_WIDTH-1:0]        awid_m_inf;
output  wire [WRIT_NUMBER * ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [WRIT_NUMBER * 3 -1:0]            awsize_m_inf;
output  wire [WRIT_NUMBER * 2 -1:0]           awburst_m_inf;
output  wire [WRIT_NUMBER * 7 -1:0]             awlen_m_inf;
output  wire [WRIT_NUMBER-1:0]                awvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                awready_m_inf;
// axi write data channel 
output  wire [WRIT_NUMBER * DATA_WIDTH-1:0]     wdata_m_inf;
output  wire [WRIT_NUMBER-1:0]                  wlast_m_inf;
output  wire [WRIT_NUMBER-1:0]                 wvalid_m_inf;
input   wire [WRIT_NUMBER-1:0]                 wready_m_inf;
// axi write response channel
input   wire [WRIT_NUMBER * ID_WIDTH-1:0]         bid_m_inf;
input   wire [WRIT_NUMBER * 2 -1:0]             bresp_m_inf;
input   wire [WRIT_NUMBER-1:0]             	   bvalid_m_inf;
output  wire [WRIT_NUMBER-1:0]                 bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [DRAM_NUMBER * ID_WIDTH-1:0]       arid_m_inf;
output  wire [DRAM_NUMBER * ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [DRAM_NUMBER * 7 -1:0]            arlen_m_inf;
output  wire [DRAM_NUMBER * 3 -1:0]           arsize_m_inf;
output  wire [DRAM_NUMBER * 2 -1:0]          arburst_m_inf;
output  wire [DRAM_NUMBER-1:0]               arvalid_m_inf;
input   wire [DRAM_NUMBER-1:0]               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [DRAM_NUMBER * ID_WIDTH-1:0]         rid_m_inf;
input   wire[DRAM_NUMBER * DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [DRAM_NUMBER * 2 -1:0]             rresp_m_inf;
input   wire [DRAM_NUMBER-1:0]                  rlast_m_inf;
input   wire [DRAM_NUMBER-1:0]                 rvalid_m_inf;
output  wire [DRAM_NUMBER-1:0]                 rready_m_inf;
// -----------------------------

//
//
// 
/* Register in each core:
  There are sixteen registers in your CPU. You should not change the name of those registers.
  TA will check the value in each register when your core is not busy.
  If you change the name of registers below, you must get the fail in this lab.
*/

reg signed [15:0] core_r0 , core_r1 , core_r2 , core_r3 ;
reg signed [15:0] core_r4 , core_r5 , core_r6 , core_r7 ;
reg signed [15:0] core_r8 , core_r9 , core_r10, core_r11;
reg signed [15:0] core_r12, core_r13, core_r14, core_r15;

parameter signed OFFSET = 16'h1000;
//###########################################
//
// Wrtie down your design below
//
//###########################################

//####################################################//
//               reg & wire							  //
//####################################################//
// State
reg [2:0] current_state, next_state;
parameter IDLE			 = 3'd0;
parameter DRAM_TO_CACHE  = 3'd1;
parameter INST_FETCH     = 3'd2;
parameter INST_DECODE    = 3'd3;
parameter EXE            = 3'd4;
parameter WRITE_BACK     = 3'd5;

// DRAM to I_CACHE
reg [1:0]inst_fetch_flag; 
wire is_finished_IF;
wire [ADDR_WIDTH-1:0] start_inst_addr;
reg [ADDR_WIDTH-1:0] cur_inst_addr;
wire wWEN_I;
wire [6:0] wA_I;
wire signed [15:0] wD_I;

// SRAM
wire [15:0] Q_I;
reg WEN_I;
reg [6:0] A_I;
reg [15:0] D_I;

// Instr fetch
reg  [15:0] inst_queue;
reg [1:0]inst_flag;

// Instr decode
reg [2:0] op_code;
reg signed[15:0] rs_data, rt_data;
reg [3:0] rd;
reg func;
reg signed [4:0] immediate;
reg [12:0] j_addr;

// EXE
reg is_finished_exe;
reg signed [15:0] exe_result;
reg [1:0]load_flag; 
wire is_finished_load;
reg signed [ADDR_WIDTH-1:0] load_addr;
wire signed [15:0] load_data;
reg jump_flag;

reg [1:0] store_flag;
wire is_finished_store;
reg signed [ADDR_WIDTH-1:0] store_addr;
reg signed [15:0] store_data;

reg signed [15:0] cur_pc;

// Write Back


//####################################################//
//               		SRAM						  //
//####################################################//
// Instruction cache
RA1SH_FINAL_I  I_CACHE(.Q(Q_I),.CLK(clk),.CEN(1'b0),.WEN(WEN_I),.A(A_I),.D(D_I),.OEN(1'b0));
// Data cache
//RA1SH_FINAL_D_CACHE  D_CACHE(.Q(Q_D),.CLK(clk),.CEN(1'b0),.WEN(WEN_D),.A(A_D),.D(D_D),.OEN(1'b0));

//##############################################################//
//              ***** Top Module *****							//
//#############################################################//

//--------------------------------------//
//                 State               //
//------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE :						next_state <= DRAM_TO_CACHE;
		DRAM_TO_CACHE : begin
			if (is_finished_IF==1) 	next_state <= INST_FETCH;
			else					next_state <= DRAM_TO_CACHE;
		end
		INST_FETCH : begin
			if (inst_flag == 1)     next_state <= INST_DECODE;
			else					next_state <= INST_FETCH;
		end
		INST_DECODE : 				next_state <= EXE;
		EXE : begin
			case (op_code)
				// Branch
				3'b101 : begin
					if (rs_data==rt_data && (((cur_pc + 2 + immediate*2)>start_inst_addr+16'hfe) ||  (cur_pc + 2 + immediate*2)<start_inst_addr))	next_state <= IDLE;
					else																														next_state <= WRITE_BACK;
				end
				// Jump
				3'b100 : begin
					if (j_addr>(start_inst_addr+16'hfe) || j_addr<start_inst_addr+16'hfe) next_state <= IDLE;
					else															next_state <= WRITE_BACK;
				end
				default : begin
					if (is_finished_exe == 1 )										next_state <= WRITE_BACK;
					else															next_state <= EXE;
				end
			endcase
		end 
		WRITE_BACK : begin
			if ((cur_pc>start_inst_addr+16'hfe) || (cur_pc<start_inst_addr)) 		next_state <= IDLE;
			else																	next_state <= INST_FETCH;
		end
		default :																	next_state <= IDLE;
	endcase
end

//--------------------------------------//
//                IDLE                 //
//------------------------------------//

// DRAM start addr for reading
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				cur_inst_addr <= 0;
	else begin
		case(current_state)
			IDLE :				cur_inst_addr <= cur_pc;
			DRAM_TO_CACHE : 	cur_inst_addr <= cur_pc;
			default : 			cur_inst_addr <= cur_inst_addr;
		endcase
	end
end

// fetch from DRAM
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				inst_fetch_flag <= 0;
	else begin
		case(current_state)
			IDLE :				inst_fetch_flag <= 1;
			DRAM_TO_CACHE :  begin   
				if (inst_fetch_flag==1) 		inst_fetch_flag <= 2;
				else if (inst_fetch_flag==2) 	inst_fetch_flag <= 2;
				else							inst_fetch_flag <= 1;
			end

			default : 			inst_fetch_flag <= 0;
		endcase
	end
end
//--------------------------------------//
//          DRAM -> I_CACHE            //
//------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				jump_flag <= 0;
	else begin
		case(current_state)
			IDLE :				jump_flag <= jump_flag;
			DRAM_TO_CACHE :     jump_flag <= jump_flag;
			EXE : begin
				case(op_code)
					// Branch
					3'b101 : begin
						if (rs_data==rt_data && (((cur_pc + 2 + immediate*2)>start_inst_addr+16'hfe) ||  (cur_pc + 2 + immediate*2)<start_inst_addr))	jump_flag <= 1;
						else																														    jump_flag <= 0;
					end
					// Jump
					3'b100 : begin
						if (j_addr>(start_inst_addr+16'hfe) || j_addr<start_inst_addr+16'hfe) jump_flag <= 1;
						else															      jump_flag <= 0;
					end
					default : jump_flag <= 0;
				endcase
			end

			default : 			jump_flag <= jump_flag;
		endcase
	end
end



Read_from_DRAM_inst IF(
	// basic
	.clk 				(clk),
	.rst_n 				(rst_n),
	.inst_fetch_flag 	(inst_fetch_flag[0]),
	.is_finished_IF 	(is_finished_IF),
	.start_addr 		(start_inst_addr),
	
	//axi read address channel 
	.arid_m_inf   (arid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]),
	.araddr_m_inf (araddr_m_inf[DRAM_NUMBER * ADDR_WIDTH-1:ADDR_WIDTH]),
	.arlen_m_inf  (arlen_m_inf[DRAM_NUMBER * 7 -1:7]),
	.arsize_m_inf (arsize_m_inf[DRAM_NUMBER * 3 -1:3]),
	.arburst_m_inf(arburst_m_inf[DRAM_NUMBER * 2 -1:2]),
	.arvalid_m_inf(arvalid_m_inf[1]),
	.arready_m_inf(arready_m_inf[1]),
	.raddr_base   (cur_inst_addr),
	
	//axi read data channel
	.rid_m_inf    (rid_m_inf[DRAM_NUMBER * ID_WIDTH-1:ID_WIDTH]),
	.rdata_m_inf  (rdata_m_inf[DRAM_NUMBER * DATA_WIDTH-1:DATA_WIDTH]),
	.rresp_m_inf  (rresp_m_inf[DRAM_NUMBER * 2 -1:2]),
	.rlast_m_inf  (rlast_m_inf[1]),
	.rvalid_m_inf (rvalid_m_inf[1]),
	.rready_m_inf (rready_m_inf[1]),
	
	//sram
	.sram_in_addr  (wA_I),
	.r_temp_data   (wD_I),
	.WEN_IN        (wWEN_I)
);		

//--------------------------------------//
//                I_CACHE              //
//------------------------------------//	

// Address	
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				A_I <= 0;
	else begin
		case(current_state)
			DRAM_TO_CACHE : begin
				if (is_finished_IF==1) A_I <= (cur_pc-start_inst_addr)/2;
				else					A_I <= wA_I;
			end
			WRITE_BACK :      	A_I <= (cur_pc-start_inst_addr)/2;
			default : 			A_I <= A_I;
		endcase
	end
end
// W_EN
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				WEN_I <= 0;
	else begin
		case(current_state)
			DRAM_TO_CACHE : 	WEN_I <= wWEN_I;
			INST_FETCH :        WEN_I <= 1;
			default : 			WEN_I <= 1;
		endcase
	end
end
// D
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				D_I <= 0;
	else begin
		case(current_state)
			DRAM_TO_CACHE : 	D_I <= wD_I;
			INST_FETCH :      	D_I <= 0;
			default : 			D_I <= 0;
		endcase
	end
end

//---------------------------------------------//
//    Instruction Fetch (from I_Cache)         //
//---------------------------------------------//

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				inst_flag <= 0;
	else begin
		case(current_state)
			DRAM_TO_CACHE : 	inst_flag <= 0;
			INST_FETCH :  begin
				if (inst_flag==0) 		inst_flag <= 1;
				else if (inst_flag==1) 	inst_flag <= 2;
				else					inst_flag <= inst_flag;
			end
			default : 			inst_flag <= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				inst_queue <= 0;
	else begin
		case(current_state)
			DRAM_TO_CACHE : 	inst_queue <= inst_queue;
			INST_FETCH : begin
				if (inst_flag==1)   inst_queue <= Q_I;
				else				inst_queue <= inst_queue;
			end
			default : 			inst_queue <= inst_queue;
		endcase
	end
end

//---------------------------------------------//
//             Instruction Decode              //
//---------------------------------------------//
// op code
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				op_code <= 0;
	else begin
		case(current_state)
			INST_DECODE : 		op_code <= inst_queue[15:13];
			default : 			op_code <= op_code;
		endcase
	end
end

// rs_data
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		rs_data <= 0;
	end
	else begin
		case(current_state)
			INST_DECODE :  begin
				case (inst_queue[15:13])
					3'b000, 3'b001, 3'b011, 3'b010, 3'b101 : begin
						case (inst_queue[12:9])
							4'd0 :  rs_data <= core_r0;
							4'd1 :  rs_data <= core_r1;
							4'd2 :  rs_data <= core_r2;
							4'd3 :  rs_data <= core_r3;
							4'd4 :  rs_data <= core_r4;
							4'd5 :  rs_data <= core_r5;
							4'd6 :  rs_data <= core_r6;
							4'd7 :  rs_data <= core_r7;
							4'd8 :  rs_data <= core_r8;
							4'd9 :  rs_data <= core_r9;
							4'd10 : rs_data <= core_r10;
							4'd11 : rs_data <= core_r11;
							4'd12 : rs_data <= core_r12;
							4'd13 : rs_data <= core_r13;
							4'd14 : rs_data <= core_r14;
							4'd15 : rs_data <= core_r15;
						endcase
					end
					default : 		rs_data <= rs_data;
				endcase
			end		
			default : 				rs_data <= rs_data;
		endcase
	end
end

// rt_data
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		rt_data <= 0;
	end
	else begin
		case(current_state)
			INST_DECODE :  begin
				case (inst_queue[15:13])
					3'b000, 3'b001, 3'b010, 3'b101 : begin
						case (inst_queue[8:5])
							4'd0 :  rt_data <= core_r0;
							4'd1 :  rt_data <= core_r1;
							4'd2 :  rt_data <= core_r2;
							4'd3 :  rt_data <= core_r3;
							4'd4 :  rt_data <= core_r4;
							4'd5 :  rt_data <= core_r5;
							4'd6 :  rt_data <= core_r6;
							4'd7 :  rt_data <= core_r7;
							4'd8 :  rt_data <= core_r8;
							4'd9 :  rt_data <= core_r9;
							4'd10 : rt_data <= core_r10;
							4'd11 : rt_data <= core_r11;
							4'd12 : rt_data <= core_r12;
							4'd13 : rt_data <= core_r13;
							4'd14 : rt_data <= core_r14;
							4'd15 : rt_data <= core_r15;
						endcase
					end
					
					default : 		rt_data <= rt_data;
				endcase
			end		
			default : 				rt_data <= rt_data;
		endcase
	end
end

// rd
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		rd <= 0;
	end
	else begin
		case(current_state)
			INST_DECODE :  begin
				case (inst_queue[15:13])
					3'b000, 3'b001 : rd <= inst_queue[4:1];	
					3'b011         : rd <= inst_queue[8:5];	
					default : 		rd <= rd;
				endcase
			end		
			default : 				rd <= rd;
		endcase
	end
end

// func
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		func <= 0;
	end
	else begin
		case(current_state)
			INST_DECODE :  begin
				case (inst_queue[15:13])
					3'b000, 3'b001 : func <= inst_queue[0];				
					default : 		func <= func;
				endcase
			end		
			default : 				func <= func;
		endcase
	end
end

// immediate
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		immediate <= 0;
	end
	else begin
		case(current_state)
			INST_DECODE :  begin
				case (inst_queue[15:13])
					3'b011, 3'b010, 3'b101 : immediate <= inst_queue[4:0];					
					default : 		immediate <= immediate;
				endcase
			end		
			default : 				immediate <= immediate;
		endcase
	end
end

// jump addr
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		j_addr <= 0;
	end
	else begin
		case(current_state)
			INST_DECODE :  begin
				case (inst_queue[15:13])
					3'b100 : 		j_addr <= inst_queue[12:0];					
					default : 		j_addr <= j_addr;
				endcase
			end		
			default : 				j_addr <= j_addr;
		endcase
	end
end

//---------------------------------------------//
//                    EXE                      //
//---------------------------------------------//

//---- ADD , SUB , Set less than, and MULT ----//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 							exe_result <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					3'b000 : begin
						case (func)
							1'b1 :						exe_result <= rs_data + rt_data;
							1'b0 : 						exe_result <= rs_data - rt_data;
						endcase
					end
					3'b001 : begin
						case (func)
							1'b1 : begin
								if (rs_data<rt_data) 	exe_result <= 1;
								else					exe_result <= 0;
							end
							1'b0 : 						exe_result <= rs_data * rt_data;
						endcase
					end
					3'b011 :							exe_result <= load_data;
					default : 							exe_result <= exe_result;							
				endcase			
			end
			default : 									exe_result <= exe_result;
		endcase
	end
end

//---- LOAD ----//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				load_flag <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					3'b011 : begin
						if (load_flag==1) 		load_flag <= 2;
						else if (load_flag==2)	load_flag <= 2;
						else             		load_flag <= 1;
					end
					default : 	load_flag <= 0;
				endcase
			end
			default : 			load_flag <= 0;
		endcase
	end
end
			
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				load_addr <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					3'b011 : 	load_addr <= (rs_data + immediate) *2 + OFFSET;
					default : 	load_addr <= 0;
				endcase
			end
			default : 			load_addr <= 0;
		endcase
	end
end

Load_from_DRAM_data load_exe(
	// basic
	.clk 				(clk),
	.rst_n 				(rst_n),
	.load_flag 			(load_flag[0]),
	.is_finished_load 	(is_finished_load),
	.raddr_base 		(load_addr),
	.r_temp_data		(load_data),
	
	//axi read address channel 
	.arid_m_inf      	(arid_m_inf[ID_WIDTH-1:0]),
	.araddr_m_inf		(araddr_m_inf[ADDR_WIDTH-1:0]),
	.arlen_m_inf		(arlen_m_inf[7 -1:0]),
	.arsize_m_inf		(arsize_m_inf[3 -1:0]),
	.arburst_m_inf		(arburst_m_inf[2 -1:0]),
	.arvalid_m_inf		(arvalid_m_inf[0]),
	.arready_m_inf		(arready_m_inf[0]),
	
	//axi read data channel
	.rid_m_inf			(rid_m_inf[ID_WIDTH-1:0]),
	.rdata_m_inf		(rdata_m_inf[DATA_WIDTH-1:0]),
	.rresp_m_inf		(rresp_m_inf[2 -1:0]),
	.rlast_m_inf		(rlast_m_inf[0]),
	.rvalid_m_inf		(rvalid_m_inf[0]),
	.rready_m_inf		(rready_m_inf[0])
);

//----- Store -----//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				store_flag <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					3'b010 : begin	
						if (store_flag==1) 		store_flag <= 2;
						else if (store_flag==2) store_flag <= 2;
						else					store_flag <= 1;
					end
					default : 	store_flag <= 0;
				endcase
			end
			default : 			store_flag <= 0;
		endcase
	end
end
			
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				store_addr <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					3'b010 : 	store_addr <= (rs_data + immediate) *2 + OFFSET;
					default : 	store_addr <= 0;
				endcase
			end
			default : 			store_addr <= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 				store_data <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					3'b010 : 	store_data <= rt_data;
					default : 	store_data <= 0;
				endcase
			end
			default : 			store_data <= 0;
		endcase
	end
end

Write_back_to_DRAM store_exe(
	// basic
	.clk				(clk),
	.rst_n				(rst_n),
	.store_flag			(store_flag[0]),
	.is_finished_store	(is_finished_store),
	.waddr_base			(store_addr),
	.store_data			(store_data),

	// axi write address channel  
	.awid_m_inf			(awid_m_inf),
	.awaddr_m_inf		(awaddr_m_inf),
	.awsize_m_inf		(awsize_m_inf),
	.awburst_m_inf		(awburst_m_inf),
	.awlen_m_inf		(awlen_m_inf),
	.awvalid_m_inf		(awvalid_m_inf),
	.awready_m_inf		(awready_m_inf),
	
	// axi write data channel
	.wdata_m_inf		(wdata_m_inf),
	.wlast_m_inf		(wlast_m_inf),
	.wvalid_m_inf		(wvalid_m_inf),
	.wready_m_inf		(wready_m_inf),
	
	// axi write response channel
	.bid_m_inf			(bid_m_inf),
	.bresp_m_inf		(bresp_m_inf),
	.bvalid_m_inf		(bvalid_m_inf),
	.bready_m_inf		(bready_m_inf)
);

//----- is finished exe -----//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 									is_finished_exe <= 0;
	else begin
		case(current_state)
			EXE : begin
				case (op_code)
					// ADD & SUB
					3'b000 : 						is_finished_exe <= 1;
					// Set & MULT
					3'b001 : 						is_finished_exe <= 1;
					// Load
					3'b011 :  begin
						if (is_finished_load==1)	is_finished_exe <= 1;
						else						is_finished_exe <= 0;
					end
					// Store
					3'b010 :  begin
						if (is_finished_store==1)	is_finished_exe <= 1;
						else						is_finished_exe <= 0;
					end
					default : 						is_finished_exe <= 0;							
				endcase			
			end
			default : 								is_finished_exe <= 0;
		endcase
	end
end

// program counter*2
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 									cur_pc <= OFFSET;
	else begin
		case(current_state)
			
			EXE : begin
				case (op_code)
					// ADD & SUB
					3'b000 : begin
						if (is_finished_exe==1)	cur_pc <= cur_pc + 2;
						else						cur_pc <= cur_pc;
					end
					// Set & MULT
					3'b001 : begin
						if (is_finished_exe==1)	cur_pc <= cur_pc + 2;
						else						cur_pc <= cur_pc;
					end
					// Load
					3'b011 :  begin
						if (is_finished_load==1)	cur_pc <= cur_pc + 2;
						else						cur_pc <= cur_pc;
					end
					// Store
					3'b010 :  begin
						if (is_finished_store==1)	cur_pc <= cur_pc + 2;
						else						cur_pc <= cur_pc;
					end
					// Branch
					3'b101 : begin
						if (rs_data==rt_data )		cur_pc <= cur_pc + 2 + immediate*2;
						else						cur_pc <= cur_pc + 2;
					end
					// Jump
					3'b100 : 						cur_pc <= j_addr;
					default : 						cur_pc <= cur_pc;							
				endcase			
			end
			default : 								cur_pc <= cur_pc;
		endcase
	end
end

//---------------------------------------------//
//                Write Back                    //
//---------------------------------------------//

// register
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		core_r0  <= 0;
		core_r1  <= 0;
		core_r2  <= 0;
		core_r3  <= 0;
		core_r4  <= 0;
		core_r5  <= 0;
		core_r6  <= 0;
		core_r7  <= 0;
		core_r8  <= 0;
		core_r9  <= 0;
		core_r10 <= 0;
		core_r11 <= 0;
		core_r12 <= 0;
		core_r13 <= 0;
		core_r14 <= 0;
		core_r15 <= 0;
	end
	else begin
		case(current_state)
			WRITE_BACK : begin
				case (op_code)
					// ADD & SUB & Set & MULT & Load
					3'b000,  3'b001, 3'b011 : begin	
						case (rd)
							4'd0 :  core_r0  <= exe_result;
							4'd1 :  core_r1  <= exe_result;
							4'd2 :  core_r2  <= exe_result;
							4'd3 :  core_r3  <= exe_result;
							4'd4 :  core_r4  <= exe_result;
							4'd5 :  core_r5  <= exe_result;
							4'd6 :  core_r6  <= exe_result;
							4'd7 :  core_r7  <= exe_result;
							4'd8 :  core_r8  <= exe_result;
							4'd9 :  core_r9  <= exe_result;
							4'd10 : core_r10 <= exe_result;
							4'd11 : core_r11 <= exe_result;
							4'd12 : core_r12 <= exe_result;
							4'd13 : core_r13 <= exe_result;
							4'd14 : core_r14 <= exe_result;
							4'd15 : core_r15 <= exe_result;
						endcase
					end
					default : 	begin
						core_r0  <= core_r0;
						core_r1  <= core_r1;
						core_r2  <= core_r2;
						core_r3  <= core_r3;
						core_r4  <= core_r4;
						core_r5  <= core_r5;
						core_r6  <= core_r6;
						core_r7  <= core_r7;
						core_r8  <= core_r8;
						core_r9  <= core_r9;
						core_r10 <= core_r10;
						core_r11 <= core_r11;
						core_r12 <= core_r12;
						core_r13 <= core_r13;
						core_r14 <= core_r14;
						core_r15 <= core_r15;
					end					
				endcase			
			end
			default : 	begin
						core_r0  <= core_r0;
						core_r1  <= core_r1;
						core_r2  <= core_r2;
						core_r3  <= core_r3;
						core_r4  <= core_r4;
						core_r5  <= core_r5;
						core_r6  <= core_r6;
						core_r7  <= core_r7;
						core_r8  <= core_r8;
						core_r9  <= core_r9;
						core_r10 <= core_r10;
						core_r11 <= core_r11;
						core_r12 <= core_r12;
						core_r13 <= core_r13;
						core_r14 <= core_r14;
						core_r15 <= core_r15;
			end	
		endcase
	end
end

// IO stall
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 			IO_stall <= 1;
	else begin
		case(current_state)
			DRAM_TO_CACHE : begin
				if (is_finished_IF==1 && jump_flag == 1) IO_stall <= 0;
				else		IO_stall <= 1;	
			end
			WRITE_BACK : 	IO_stall <= 0;

			default : 		IO_stall <= 1;	
		endcase
	end
end

endmodule			
//##############################################################//
//                 ***** Sub Module *****						//
//#############################################################//

//---------------------------------------------------------//
//   Submodule-1 : Read Inst from DRAM_inst to I_Cache     //
//---------------------------------------------------------//
module Read_from_DRAM_inst(
	// basic
	clk,
	rst_n,
	inst_fetch_flag,
	is_finished_IF,
	start_addr,
	
	//axi read address channel 
	arid_m_inf,
	araddr_m_inf,
	arlen_m_inf,
	arsize_m_inf,
	arburst_m_inf,
	arvalid_m_inf,
	arready_m_inf,
	raddr_base,
	
	//axi read data channel
	rid_m_inf,
	rdata_m_inf,
	rresp_m_inf,
	rlast_m_inf,
	rvalid_m_inf,
	rready_m_inf,
	
	//sram
	sram_in_addr,
	r_temp_data,
	WEN_IN
);


//-------DECLARATION--------------------------------------------//
parameter signed OFFSET = 16'h1000;
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// basic
input inst_fetch_flag, clk, rst_n;
output reg is_finished_IF;
output reg [ADDR_WIDTH-1:0]  start_addr;

// axi read address channel 
output       [ID_WIDTH-1:0]   arid_m_inf;
output  reg  [ADDR_WIDTH-1:0] araddr_m_inf;
output  wire [7 -1:0]         arlen_m_inf;
output       [3 -1:0]         arsize_m_inf;
output       [2 -1:0]         arburst_m_inf;
output  reg                   arvalid_m_inf;
input   wire                  arready_m_inf;
input   wire [ADDR_WIDTH-1:0] raddr_base;
// axi read data channel 
input   wire [ID_WIDTH-1:0]   rid_m_inf;
input   wire [DATA_WIDTH-1:0] rdata_m_inf;
input   wire [2 -1:0]         rresp_m_inf;
input   wire                  rlast_m_inf;
input   wire                  rvalid_m_inf;
output  reg                   rready_m_inf;
//SRAM
output reg                    WEN_IN;
output reg [7 -1:0]           sram_in_addr;
output reg [DATA_WIDTH-1:0]   r_temp_data;
// Parameter & Integer
parameter IDLE           = 2'b00;
parameter WAIT_ARREADY      = 2'b01;
parameter READ_FROM_DRAM = 2'b10;
parameter READ_AND_STORE = 2'b11;
// Reg & Wire
reg [1:0] current_state, next_state ; 
reg addr_flag;
//-------ASSIGN--------------------------------------------//
// Master //
assign arid_m_inf = 0;
assign arsize_m_inf = 3'b001;
assign arburst_m_inf = 2'b01;
assign arlen_m_inf = 7'd127;
//-------STATE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin 
			if (inst_fetch_flag==1) 					next_state = WAIT_ARREADY;
			else              							next_state = IDLE;
		end		
		WAIT_ARREADY : begin
			if (arready_m_inf==1 && arvalid_m_inf == 1) next_state = READ_FROM_DRAM;
			else 										next_state = WAIT_ARREADY;
		end
		READ_FROM_DRAM : begin
			if (sram_in_addr==127) 						next_state = IDLE;
			else                                      	next_state = READ_FROM_DRAM;
		end
		default : 										next_state = IDLE;
	endcase
end

//-------READ ADDRESS CHANNEL-------------------//
// ADDRESS ASSIGNMENT : 1000 to 1FFF //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		araddr_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (inst_fetch_flag==1) begin
					if (raddr_base<16'h107e) 					araddr_m_inf<= OFFSET;
					else if (raddr_base>=16'h1f00) 				araddr_m_inf<= 16'h1f00;
					else										araddr_m_inf<= raddr_base-16'd126;
				end
				else              						araddr_m_inf<= 0;
			end
			WAIT_ARREADY : begin
				if (arready_m_inf == 1)      			araddr_m_inf<= 0;  
				else									araddr_m_inf<= araddr_m_inf;
			end
			default : 									araddr_m_inf<= 0;
		endcase
	end
end

// Start addr
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		start_addr <= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (inst_fetch_flag==1) begin
					if (raddr_base<16'h107e) 			start_addr<= OFFSET;
					else if (raddr_base>=16'h1f00)      start_addr<= 16'h1f00;
					else								start_addr<= raddr_base-16'd126;
				end
				else              						start_addr<= start_addr;
			end
			WAIT_ARREADY : begin
				if (arready_m_inf == 1)      			start_addr<= start_addr;  
				else									start_addr<= start_addr;
			end
			default : 									start_addr<= start_addr;
		endcase
	end
end

// Read address valid //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		arvalid_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (inst_fetch_flag==1) 						arvalid_m_inf<= 1;
				else              								arvalid_m_inf<= 0;
			end
			WAIT_ARREADY : begin
				if (arready_m_inf == 1) 						arvalid_m_inf<= 0;
				else 											arvalid_m_inf<= arvalid_m_inf;
			end
			default : 											arvalid_m_inf<= 0;
		endcase
	end
end

//-------READ DATA CHANNEL----------------//

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 											rready_m_inf<= 0;
	else begin
		case(current_state)
			IDLE : 											rready_m_inf<= 0;
			WAIT_ARREADY : begin
				if (arready_m_inf==1 && arvalid_m_inf == 1) rready_m_inf <= 1;
				else 										rready_m_inf <= 0;
			end
			READ_FROM_DRAM : begin
				if (rlast_m_inf==1) 						rready_m_inf<= 0;
				else 										rready_m_inf<= 1;
			end
			default : 										rready_m_inf<= 0;
		endcase
	end
end


//-------SRAM PORT---------------------//

// DATA
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 											r_temp_data<= 0;
	else begin
		case(current_state)
			IDLE : 											r_temp_data<= 0;
			WAIT_ARREADY : 									r_temp_data <= r_temp_data;
			READ_FROM_DRAM : begin
				if (rvalid_m_inf==1 && rready_m_inf == 1 ) 	r_temp_data <= rdata_m_inf;
				else 										r_temp_data <= r_temp_data;
			end
			default : 										r_temp_data<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 											addr_flag<= 0;
	else begin
		case(current_state)
			IDLE : 											addr_flag<= 0;
			WAIT_ARREADY : 									addr_flag <= 0;
			READ_FROM_DRAM : begin
				if (rvalid_m_inf==1 && rready_m_inf == 1 ) 	addr_flag <= 1;
				else 										addr_flag <= addr_flag;
			end
			default : 										addr_flag<= 0;
		endcase
	end
end

// ADDRESS
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		sram_in_addr<= 0;
	end
	else begin
		case(current_state)
			IDLE : 																sram_in_addr<= 0;
			WAIT_ARREADY : 														sram_in_addr <= sram_in_addr;
			READ_FROM_DRAM : begin
				if (sram_in_addr==127)						        			sram_in_addr<= 0;
				else if (rvalid_m_inf==1 && rready_m_inf == 1 && addr_flag==1) 	sram_in_addr <= sram_in_addr+1;
				else 															sram_in_addr <= sram_in_addr;
			end
			default : sram_in_addr<= 0;
		endcase
	end
end

// WEN
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		WEN_IN<= 1;
	end
	else begin
		case(current_state)
			IDLE : 											WEN_IN<= 1;
			WAIT_ARREADY : begin
				if (arready_m_inf==1 && arvalid_m_inf == 1) WEN_IN<= 0;
				else										WEN_IN<= WEN_IN;
			end
			READ_FROM_DRAM : begin
				if (sram_in_addr==127)						WEN_IN<= 1;
				else if (rvalid_m_inf==1 && rready_m_inf == 1) 	WEN_IN <= 0;
				else 										WEN_IN <= WEN_IN;
			end
			default : 										WEN_IN<= 1;
		endcase
	end
end


//-------READ IS FINISHED OR NOT-------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						is_finished_IF<= 0;
	else begin
		case(current_state)
			IDLE : 						is_finished_IF<= 0;
			WAIT_ARREADY : 				is_finished_IF<= 0;
			READ_FROM_DRAM : begin
				if (sram_in_addr==127) 	is_finished_IF <= 1;
				else                   	is_finished_IF <= 0;
			end
			default : 					is_finished_IF<= 0;
		endcase
	end
end
endmodule

//---------------------------------------------------------------------//
//          Submodule-2 : Read Data from DRAM_data                     //
//---------------------------------------------------------------------//
module Load_from_DRAM_data(
	// basic
	clk,
	rst_n,
	load_flag,
	is_finished_load,
	raddr_base,
	r_temp_data,
	
	//axi read address channel 
	arid_m_inf,
	araddr_m_inf,
	arlen_m_inf,
	arsize_m_inf,
	arburst_m_inf,
	arvalid_m_inf,
	arready_m_inf,
	
	//axi read data channel
	rid_m_inf,
	rdata_m_inf,
	rresp_m_inf,
	rlast_m_inf,
	rvalid_m_inf,
	rready_m_inf,
);


//-------DECLARATION--------------------------------------------//
parameter signed OFFSET = 16'h1000;
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

// basic
input 							load_flag, clk, rst_n;
output reg 						is_finished_load;
input   wire [ADDR_WIDTH-1:0] 	raddr_base;
output reg   [DATA_WIDTH-1:0] 	r_temp_data;
// axi read address channel 
output       [ID_WIDTH-1:0]   	arid_m_inf;
output  reg  [ADDR_WIDTH-1:0] 	araddr_m_inf;
output  wire [7 -1:0]         	arlen_m_inf;
output       [3 -1:0]         	arsize_m_inf;
output       [2 -1:0]         	arburst_m_inf;
output  reg                   	arvalid_m_inf;
input   wire                  	arready_m_inf;

// axi read data channel 
input   wire [ID_WIDTH-1:0]   	rid_m_inf;
input   wire [DATA_WIDTH-1:0] 	rdata_m_inf;
input   wire [2 -1:0]         	rresp_m_inf;
input   wire                  	rlast_m_inf;
input   wire                  	rvalid_m_inf;
output  reg                   	rready_m_inf;

// Parameter & Integer
parameter IDLE           	= 2'b00;
parameter WAIT_ARREADY      = 2'b01;
parameter READ_FROM_DRAM 	= 2'b10;
parameter READ_AND_STORE 	= 2'b11;
// Reg & Wire
reg [1:0] current_state, next_state ; 

//-------ASSIGN--------------------------------------------//
// Master //
assign arid_m_inf 		= 0;
assign arsize_m_inf 	= 3'b001;
assign arburst_m_inf 	= 2'b01;
assign arlen_m_inf 		= 7'd0;
//-------STATE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin 
			if (load_flag==1) 					next_state = WAIT_ARREADY;
			else              							next_state = IDLE;
		end		
		WAIT_ARREADY : begin
			if (arready_m_inf==1 && arvalid_m_inf == 1) next_state = READ_FROM_DRAM;
			else 										next_state = WAIT_ARREADY;
		end
		READ_FROM_DRAM : begin
			if (rlast_m_inf==1) 						next_state = IDLE;
			else                                      	next_state = READ_FROM_DRAM;
		end
		default : 										next_state = IDLE;
	endcase
end

//-------READ ADDRESS CHANNEL--------------------------------------------//
// ADDRESS ASSIGNMENT : 1000 to 1FFF //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		araddr_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (load_flag==1) 						araddr_m_inf<= raddr_base;
				else              						araddr_m_inf<= 0;
			end
			WAIT_ARREADY : begin
				if (arready_m_inf == 1)      			araddr_m_inf<= 0;  
				else									araddr_m_inf<= araddr_m_inf;
			end
			default : 									araddr_m_inf<= 0;
		endcase
	end
end

// Read address valid //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
														arvalid_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (load_flag==1) 						arvalid_m_inf<= 1;
				else              						arvalid_m_inf<= 0;
			end
			WAIT_ARREADY : begin
				if (arready_m_inf == 1) 				arvalid_m_inf<= 0;
				else 									arvalid_m_inf<= arvalid_m_inf;
			end
			default : 									arvalid_m_inf<= 0;
		endcase
	end
end

//-------READ DATA CHANNEL--------------------------------------------//

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 											rready_m_inf<= 0;
	else begin
		case(current_state)
			IDLE : 											rready_m_inf<= 0;
			WAIT_ARREADY : begin
				if (arready_m_inf==1 && arvalid_m_inf == 1) rready_m_inf <= 1;
				else 										rready_m_inf <= 0;
			end
			READ_FROM_DRAM : begin
				if (rlast_m_inf==1) 						rready_m_inf<= 0;
				else 										rready_m_inf<= 1;
			end
			default : 										rready_m_inf<= 0;
		endcase
	end
end

// DATA
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 											r_temp_data<= 0;
	else begin
		case(current_state)
			IDLE : 											r_temp_data<= r_temp_data;
			WAIT_ARREADY : 									r_temp_data <= r_temp_data;
			READ_FROM_DRAM : begin
				if (rvalid_m_inf==1 && rready_m_inf == 1 ) 	r_temp_data <= rdata_m_inf;
				else 										r_temp_data <= r_temp_data;
			end
			default : 										r_temp_data<= r_temp_data;
		endcase
	end
end


//-------READ IS FINISHED OR NOT--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						is_finished_load<= 0;
	else begin
		case(current_state)
			IDLE : 						is_finished_load<= 0;
			WAIT_ARREADY : 				is_finished_load<= 0;
			READ_FROM_DRAM : begin
				if (rlast_m_inf==1) 	is_finished_load <= 1;
				else                   	is_finished_load <= 0;
			end
			default : 					is_finished_load<= 0;
		endcase
	end
end
endmodule





//---------------------------------------------------------------------//
//   				Submodule-3 : Write Data to DRAM				   //
//---------------------------------------------------------------------//
module Write_back_to_DRAM(
	// basic
	clk,
	rst_n,
	store_flag,
	is_finished_store,
	waddr_base,
	store_data,
	
	// axi write address channel  
	awid_m_inf,
	awaddr_m_inf,
	awsize_m_inf,
	awburst_m_inf,
	awlen_m_inf,
	awvalid_m_inf,
	awready_m_inf,
	
	// axi write data channel
	wdata_m_inf,
	wlast_m_inf,
	wvalid_m_inf,
	wready_m_inf,
	
	// axi write response channel
	bid_m_inf,
	bresp_m_inf,
	bvalid_m_inf,
	bready_m_inf,
);

//-------DECLARATION-------------------------//
parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 16, DRAM_NUMBER=2, WRIT_NUMBER=1;

input 						store_flag, clk, rst_n;
output reg 					is_finished_store;
input wire [ADDR_WIDTH-1:0] waddr_base;
input wire [DATA_WIDTH-1:0] store_data;

// axi write address channel 
output   		[ID_WIDTH-1:0]     	awid_m_inf;
output  reg 	[ADDR_WIDTH-1:0]    awaddr_m_inf;
output   		[3 -1:0]     		awsize_m_inf;
output   		[2 -1:0]     		awburst_m_inf;
output  wire 	[7 -1:0]     		awlen_m_inf;
output  reg           				awvalid_m_inf;
input   wire           				awready_m_inf;
// axi write data channel 
output  reg 	[DATA_WIDTH-1:0]    wdata_m_inf;
output  reg           				wlast_m_inf;
output  reg           				wvalid_m_inf;
input   wire           				wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]     	bid_m_inf;
input   wire [2 -1:0]    			bresp_m_inf;
input   wire           				bvalid_m_inf;
output  reg           				bready_m_inf;
// Parameter & Integer
parameter IDLE 			= 2'b00;
parameter WAIT_AWREADY 		= 2'b01;
parameter WRITE_BACK 	= 2'b10;
// Reg & Wire
reg [1:0]	current_state, next_state; 
reg ready_flag;
//-------ASSIGN-------------------------//
assign awid_m_inf 		= 0;
assign awsize_m_inf 	= 3'b001;
assign awburst_m_inf 	= 2'b01;
assign awlen_m_inf 		= 7'd0;
//-------STATE--------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin 
			if (store_flag==1) next_state = WAIT_AWREADY;
			else              next_state = IDLE;
		end
		WAIT_AWREADY: begin
			if (awready_m_inf==1 && awvalid_m_inf == 1) next_state = WRITE_BACK;
			else next_state = WAIT_AWREADY;
		end
		WRITE_BACK : begin
			if(is_finished_store==1)  	next_state = IDLE;
			else                    	next_state = WRITE_BACK;
		end
		default : next_state = IDLE;
	endcase
end

//-------WRITE ADDRESS CHANNEL-------------//
// ADDRESS ASSIGNMENT : 1000 to 1FFF //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		awaddr_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin 
				if (store_flag==1) 	awaddr_m_inf <= waddr_base;
				else               	awaddr_m_inf <= 0;
			end
			WAIT_AWREADY : 			awaddr_m_inf<= awaddr_m_inf;
			WRITE_BACK : 			awaddr_m_inf<= 0;
			default : 				awaddr_m_inf<= 0;
		endcase
	end
end

// Write address valid //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						awvalid_m_inf<= 0;
	else begin
		case(current_state)
			IDLE : 	begin
				if (store_flag==1) 		awvalid_m_inf <= 1;
					else               	awvalid_m_inf <= awvalid_m_inf;
				end
			WAIT_AWREADY : begin
				if (awready_m_inf==1) 	awvalid_m_inf <= 0;
				else 					awvalid_m_inf <= awvalid_m_inf;
			end
			default : awvalid_m_inf <= 0;
		endcase
	end
end
//-------WRITE DATA CHANNEL----------------//

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						wdata_m_inf<= 0;
	else begin
		case(current_state)
			IDLE : 						wdata_m_inf<= 0;
			WAIT_AWREADY : begin
				if (awready_m_inf==1) 	wdata_m_inf <= store_data;
				else 					wdata_m_inf <= wdata_m_inf;
			end
			WRITE_BACK :  begin
				if (wready_m_inf==1) 	wdata_m_inf <= 0;
				else                  	wdata_m_inf <= wdata_m_inf;
			end
			default : wdata_m_inf<= 0;
		endcase
	end
end

always@(*) begin
    if (!rst_n) 						wlast_m_inf= 0;
	else begin
		case(current_state)
			IDLE : 						wlast_m_inf= 0;
			WAIT_AWREADY : 				wlast_m_inf= 0;
			WRITE_BACK : begin
				if (wready_m_inf==1) 	wlast_m_inf= 1;
				else                  	wlast_m_inf= 0;
			end
			default : 					wlast_m_inf= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						wvalid_m_inf <= 0;
	else begin
		case(current_state)
			IDLE : 						wvalid_m_inf <= 0;
			WAIT_AWREADY : begin
				if (awready_m_inf==1) 	wvalid_m_inf <= 0;
				else 					wvalid_m_inf <= wvalid_m_inf;
			end
			WRITE_BACK :  begin
				if (wready_m_inf==1) 	wvalid_m_inf <= 0;
				else if (ready_flag==1) wvalid_m_inf <= 0;
				else                  	wvalid_m_inf <= 1;
			end
			default : 					wvalid_m_inf<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						ready_flag <= 0;
	else begin
		case(current_state)
			IDLE : 						ready_flag <= 0;
			WAIT_AWREADY :              ready_flag <= 0;
			WRITE_BACK :  begin
				if (wlast_m_inf==1)   	ready_flag <= 1;
				else                  	ready_flag <= ready_flag;
			end
			default : 					ready_flag<= 0;
		endcase
	end
end

//-------WRITE RESPONSE CHANNEL---------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						bready_m_inf<= 0;
	else begin
		case(current_state)
			IDLE : 						bready_m_inf<= 0;
			WAIT_AWREADY : begin
				if (awready_m_inf==1) 	bready_m_inf <= 0;
				else 					bready_m_inf <= bready_m_inf;
			end
			WRITE_BACK :  begin
				if (bvalid_m_inf==1) 	bready_m_inf <= 0;
				else                  	bready_m_inf <= 1;
			end
			default : 					bready_m_inf<= 0;
		endcase
	end
end


//-------WRITE IS FINISHED OR NOT---------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) 						is_finished_store<= 0;
	else begin
		case(current_state)
			IDLE : 						is_finished_store<= 0;
			WAIT_AWREADY : 				is_finished_store<= 0;
			WRITE_BACK : begin
				if (bvalid_m_inf==1) 	is_finished_store <= 1;
				else               		is_finished_store <= 0;
			end
			default : 					is_finished_store<= 0;
		endcase
	end
end
			
endmodule





















