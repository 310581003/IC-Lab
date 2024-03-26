
// outvalid, The latency between BVALID and BREADY, RREADY and RVALID should not 
//be larger than 300 cycles
module GLCM(
				clk,	
			  rst_n,	
	
			in_addr_M,
			in_addr_G,
			in_dir,
			in_dis,
			in_valid,
			out_valid,
	

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

parameter ID_WIDTH = 4 , ADDR_WIDTH = 32, DATA_WIDTH = 32;
input			  clk,rst_n;

// AXI Interface wire connecttion for pseudo DRAM read/write
/* Hint:
       your AXI-4 interface could be designed as convertor in submodule(which used reg for output signal),
	   therefore I declared output of AXI as wire in Poly_Ring
*/
   
// -----------------------------
// IO port
input [ADDR_WIDTH-1:0]      in_addr_M;
input [ADDR_WIDTH-1:0]      in_addr_G;
input [1:0]  	  		in_dir;
input [3:0]	    		in_dis;
input 			    	in_valid;
output reg 	              out_valid;
// -----------------------------


// axi write address channel 
output  wire [ID_WIDTH-1:0]        awid_m_inf;
output  wire [ADDR_WIDTH-1:0]    awaddr_m_inf;
output  wire [2:0]            awsize_m_inf;
output  wire [1:0]           awburst_m_inf;
output  wire [3:0]             awlen_m_inf;
output  wire                 awvalid_m_inf;
input   wire                 awready_m_inf;
// axi write data channel 
output  wire [ DATA_WIDTH-1:0]     wdata_m_inf;
output  wire                   wlast_m_inf;
output  wire                  wvalid_m_inf;
input   wire                  wready_m_inf;
// axi write response channel
input   wire [ID_WIDTH-1:0]         bid_m_inf;
input   wire [1:0]             bresp_m_inf;
input   wire              	   bvalid_m_inf;
output  wire                  bready_m_inf;
// -----------------------------
// axi read address channel 
output  wire [ID_WIDTH-1:0]       arid_m_inf;
output  wire [ADDR_WIDTH-1:0]   araddr_m_inf;
output  wire [3:0]            arlen_m_inf;
output  wire [2:0]           arsize_m_inf;
output  wire [1:0]          arburst_m_inf;
output  wire                arvalid_m_inf;
input   wire               arready_m_inf;
// -----------------------------
// axi read data channel 
input   wire [ID_WIDTH-1:0]         rid_m_inf;
input   wire [DATA_WIDTH-1:0]     rdata_m_inf;
input   wire [1:0]             rresp_m_inf;
input   wire                   rlast_m_inf;
input   wire                  rvalid_m_inf;
output  wire                  rready_m_inf;
// -----------------------------
//---------------------------------------------------------------------
//   Parameter & Integer
//---------------------------------------------------------------------
parameter IDLE = 3'b000;
parameter ASSIGN_ORIGIN_ADDR = 3'b001;
parameter ASSIGN_OFFSET_ADDR = 3'b010;
parameter FETCH_OFFSET = 3'b011;
parameter GLCM_CAL = 3'b100;
parameter WRITE_BACK_to_DRAM = 3'b101;

integer i, j;

//---------------------------------------------------------------------
//   Reg & Wire
//---------------------------------------------------------------------
// STATE //
reg [2:0] current_state, next_state;
// DRAM //
reg read_flag, write_flag;
reg [31:0] store_data;
// SRAM //
reg [7:0] A_IN;
reg [9:0] A_OUT;
reg [4:0] D_IN;
wire [4:0] Q_IN;
reg [7:0] Q_OUT, D_OUT;
reg WEN_IN, WEN_OUT;
// Get Input //
reg [ADDR_WIDTH-1:0] first_addr_M, first_addr_G;
reg [1:0] dir;
reg [3:0] dis;
// CAL //
reg wait_flag;
reg [7:0] glcm [31:0][31:0];
reg [7:0] origin_cnt, offset_cnt;
reg [4:0] origin_buf, offset_buf;
reg [4:0] out_row_cnt, out_col_cnt;
wire is_finished_read, is_finished_write;
wire wWEN_IN;
wire [7:0] wA_IN;
wire [4:0] wD_IN;
wire [9:0] wburst_count;

//---------------------------------------------------------------------
//   SRAM
//---------------------------------------------------------------------

RA1SH_mid_in  SRAM_IN(.Q(Q_IN),.CLK(clk),.CEN(1'b0),.WEN(WEN_IN),.A(A_IN),.D(D_IN),.OEN(1'b0));
//RA1SH_mid_out SRAM_OUT(.Q(Q_OUT),.CLK(clk),.CEN(1'b0),.WEN(WEN_OUT),.A(A_OUT),.D(D_OUT),.OEN(1'b0));

//---------------------------------------------------------------------
//   TOP DESIGN
//---------------------------------------------------------------------

//---------- State ----------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin
			if (is_finished_read==1) next_state = ASSIGN_ORIGIN_ADDR;
			else                     next_state = IDLE;
		end
		ASSIGN_ORIGIN_ADDR : begin
			if (wait_flag== 1)       next_state = ASSIGN_OFFSET_ADDR;
			else                     next_state = ASSIGN_ORIGIN_ADDR;
		end
		ASSIGN_OFFSET_ADDR : begin
			if (wait_flag== 0)       next_state = FETCH_OFFSET;
			else                     next_state = ASSIGN_OFFSET_ADDR;
		end
		FETCH_OFFSET :               next_state = GLCM_CAL;
		GLCM_CAL : begin
			if (origin_cnt==255)     next_state = WRITE_BACK_to_DRAM;
			else                     next_state = ASSIGN_ORIGIN_ADDR;
		end
		WRITE_BACK_to_DRAM : begin
			if (is_finished_write==1) next_state = IDLE;
			else                      next_state = WRITE_BACK_to_DRAM;		
		end
		default : next_state = IDLE;
	endcase
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		wait_flag<= 0;
	end
	else begin
		case(current_state)
			IDLE : wait_flag<= 0;
			ASSIGN_ORIGIN_ADDR : wait_flag<= 1;
			ASSIGN_OFFSET_ADDR : wait_flag<= 0;
			FETCH_OFFSET : wait_flag<= 0;
			GLCM_CAL :wait_flag<= 0;
			WRITE_BACK_to_DRAM :wait_flag<= 0;
			default : wait_flag<= 0;
		endcase
	end
end		

//---------- Get Input ----------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		first_addr_M <= 0;
		first_addr_G <= 0;
		dir <= 0;
		dis <= 0;	
	end
	else begin
		case(current_state)
			IDLE : begin
				if (in_valid==1)begin
					first_addr_M <= in_addr_M;
					first_addr_G <= in_addr_G;
					dir <= in_dir;
					dis <= in_dis;				
				end
				else begin
					first_addr_M <= first_addr_M;
					first_addr_G <= first_addr_G;
					dir <= dir;
					dis <= dis;									
				end			
			end
			
			WRITE_BACK_to_DRAM :begin
				first_addr_M <= 0;
				first_addr_G <= 0;
				dir <= 0;
				dis <= 0;
			end
			default : begin
				first_addr_M <= first_addr_M;
				first_addr_G <= first_addr_G;
				dir <= dir;
				dis <= dis;
			end
		endcase
	end
end

//-------READ AVAILABLE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		read_flag<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (in_valid==1) read_flag<= 1;
				else if (read_flag == 1) read_flag<= 0;
				else read_flag<= 0;
			end
			default : read_flag<= 0;
		endcase
	end
end
//-------READ FROM DRAM TO SRAM--------------------------------------------//
Read_from_DRAM R(
	// basic
	.clk(clk),
	.rst_n(rst_n),
	.read_flag(read_flag),
	.is_finished_read(is_finished_read),
	
	//axi read address channel 
	.arid_m_inf(arid_m_inf),
	.araddr_m_inf(araddr_m_inf),
	.arlen_m_inf(arlen_m_inf),
	.arsize_m_inf(arsize_m_inf),
	.arburst_m_inf(arburst_m_inf),
	.arvalid_m_inf(arvalid_m_inf),
	.arready_m_inf(arready_m_inf),
	.raddr_base(first_addr_M),
	
	//axi read data channel
	.rid_m_inf(rid_m_inf),
	.rdata_m_inf(rdata_m_inf),
	.rresp_m_inf(rresp_m_inf),
	.rlast_m_inf(rlast_m_inf),
	.rvalid_m_inf(rvalid_m_inf),
	.rready_m_inf(rready_m_inf),
	
	//SRAM
	.sram_in_addr(wA_IN),
	.r_temp_data(wD_IN),
	.WEN_IN(wWEN_IN)
);

//-------FETCH  PIXEL--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) A_IN <= 0;
	else begin
		case(current_state)
			IDLE : A_IN <= wA_IN;
			ASSIGN_ORIGIN_ADDR : A_IN <= origin_cnt;
			ASSIGN_OFFSET_ADDR : A_IN <= offset_cnt;
			default :            A_IN <= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) D_IN <= 0;
	else begin
		case(current_state)
			IDLE : D_IN <= wD_IN;
			ASSIGN_ORIGIN_ADDR : D_IN <= D_IN;
			ASSIGN_OFFSET_ADDR : D_IN <= D_IN;
			default :            D_IN <= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) WEN_IN <= 0;
	else begin
		case(current_state)
			IDLE : WEN_IN <= wWEN_IN;
			ASSIGN_ORIGIN_ADDR : WEN_IN <= 1;
			ASSIGN_OFFSET_ADDR : WEN_IN <= 1;
			default :            WEN_IN <= 1;
		endcase
	end
end


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) origin_cnt <= 0;
	else begin
		case(current_state)
			IDLE : origin_cnt <= 0;
			ASSIGN_ORIGIN_ADDR : origin_cnt <= origin_cnt;
			ASSIGN_OFFSET_ADDR : begin
				if (wait_flag== 0) origin_cnt <= origin_cnt;
				else               origin_cnt <= origin_cnt;
			end
			GLCM_CAL : origin_cnt <= origin_cnt+1;
			default :            origin_cnt <= origin_cnt;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) origin_buf <= 0;
	else begin
		case(current_state)
			IDLE : origin_buf <= 0;
			ASSIGN_ORIGIN_ADDR : origin_buf <= 0;
			ASSIGN_OFFSET_ADDR : origin_buf <= Q_IN;
			default :            origin_buf <= origin_buf;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) offset_buf <= 0;
	else begin
		case(current_state)
			IDLE : offset_buf <= 0;
			ASSIGN_ORIGIN_ADDR : offset_buf <= 0;
			FETCH_OFFSET :       offset_buf <= Q_IN;
			default :            offset_buf <= offset_buf;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) offset_cnt <= 0;
	else begin
		case(current_state)
			IDLE : offset_cnt <= 0;
			ASSIGN_ORIGIN_ADDR : begin
				case(dir) 
					2'b01 : offset_cnt <= origin_cnt + 16*dis;
					2'b10 : offset_cnt <= origin_cnt + dis;
					2'b11 : offset_cnt <= origin_cnt + 16*dis + dis;
					default : offset_cnt <= offset_cnt;
				endcase
			end
			ASSIGN_OFFSET_ADDR : offset_cnt <= offset_cnt;
			default :            offset_cnt <= offset_cnt;
		endcase
	end
end

//-------GLCM CALCULATION--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		for (i=0;i<32;i=i+1) begin
			for (j=0;j<32;j=j+1)begin
				glcm [i][j] <= 0;
			end
		end
	end
	else begin
		case(current_state)
			IDLE : begin
				for (i=0;i<32;i=i+1) begin
					for (j=0;j<32;j=j+1)begin
						glcm [i][j] <= 0;
					end
				end
			end
			GLCM_CAL :  begin
				case(dir) 
					2'b01 : begin
						if ((16-(origin_cnt)/16)>dis) glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf]+1;
						else glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf];
					end
					2'b10 : begin
						if ((16-(origin_cnt)%16)>dis) glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf]+1;
						else glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf];
					end
					2'b11 : begin
						if ((16-(origin_cnt)/16)>dis && (16-(origin_cnt)%16)>dis) glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf]+1;
						else glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf];
					end
					default : glcm [origin_buf][offset_buf] <= glcm [origin_buf][offset_buf];
				endcase
			end
			default : begin
				for (i=0;i<32;i=i+1) begin
					for (j=0;j<32;j=j+1)begin
						glcm [i][j] <= glcm [i][j];
					end
				end
			end
		endcase
	end
end

//-------WRITE AVAILABLE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		write_flag<= 0;
	end
	else begin
		case(current_state)
			GLCM_CAL : begin
				if (origin_cnt==255)  write_flag<= 1;
				else                  write_flag<= 0;
			end
			WRITE_BACK_to_DRAM :
				if (is_finished_write==1) write_flag<= 0;
				else write_flag<= 1;
			default : write_flag<= 0;
		endcase
	end
end
//-------WRITE BACK--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		store_data<= 0;
	end
	else begin
		case(current_state)
			WRITE_BACK_to_DRAM : store_data <= {glcm [out_row_cnt][out_col_cnt+3],glcm [out_row_cnt][out_col_cnt+2],glcm [out_row_cnt][out_col_cnt+1],glcm [out_row_cnt][out_col_cnt]};
			default : store_data<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		out_row_cnt<= 0;
	end
	else begin
		case(current_state)
			WRITE_BACK_to_DRAM : begin
				if (wvalid_m_inf==1 && wready_m_inf==1) begin
					if (out_col_cnt<28) out_row_cnt <= out_row_cnt;
					else                 out_row_cnt <= out_row_cnt+1;
				end
			end
			default : out_row_cnt<= 0;
		endcase
	end
end


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		out_col_cnt<= 0;
	end
	else begin
		case(current_state)
			WRITE_BACK_to_DRAM : begin
				if (wvalid_m_inf==1 ) begin
					if(wvalid_m_inf==1 && wburst_count==0) out_col_cnt <= out_col_cnt+4;
					if (out_col_cnt<28 && wburst_count<14) out_col_cnt <= out_col_cnt+4;
					else                 out_col_cnt <= 0;
				end
			end
			default : out_col_cnt<= 0;
		endcase
	end
end

Write_back_to_DRAM W(
	// basic
	.clk(clk),
	.rst_n(rst_n),
	.write_flag(write_flag),
	.is_finished_write(is_finished_write),
	.waddr_base(first_addr_G),
	.store_data(store_data),
	
	// axi write address channel  
	.awid_m_inf(awid_m_inf),
	.awaddr_m_inf(awaddr_m_inf),
	.awsize_m_inf(awsize_m_inf),
	.awburst_m_inf(awburst_m_inf),
	.awlen_m_inf(awlen_m_inf),
	.awvalid_m_inf(awvalid_m_inf),
	.awready_m_inf(awready_m_inf),
	
	// axi write data channel
	.wdata_m_inf(wdata_m_inf),
	.wlast_m_inf(wlast_m_inf),
	.wvalid_m_inf(wvalid_m_inf),
	.wready_m_inf(wready_m_inf),
	
	// axi write response channel
	.bid_m_inf(bid_m_inf),
	.bresp_m_inf(bresp_m_inf),
	.bvalid_m_inf(bvalid_m_inf),
	.bready_m_inf(bready_m_inf),
	.wburst_count(wburst_count)
);
//-------WRITE AVAILABLE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		out_valid<= 0;
	end
	else begin
		case(current_state)
			WRITE_BACK_to_DRAM : begin
				if (is_finished_write==1)out_valid<= 1;
				else                     out_valid<= 0;
			end
			default : out_valid<= 0;
		endcase
	end
end
endmodule

//---------------------------------------------------------------------
//   Submodule-1 : Read Data from DRAM to SRAM
//---------------------------------------------------------------------
module Read_from_DRAM(
	// basic
	clk,
	rst_n,
	read_flag,
	is_finished_read,
	
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
input read_flag, clk, rst_n;
output reg is_finished_read;
// axi read address channel 
output   [3:0]   arid_m_inf;
output  reg [31:0]  araddr_m_inf;
output  wire [3:0]   arlen_m_inf;
output   [2:0]   arsize_m_inf;
output   [1:0]   arburst_m_inf;
output  reg         arvalid_m_inf;
input   wire         arready_m_inf;
input   wire [31:0]  raddr_base;
// axi read data channel 
input   wire [3:0]   rid_m_inf;
input   wire [31:0]  rdata_m_inf;
input   wire [1:0]   rresp_m_inf;
input   wire         rlast_m_inf;
input   wire         rvalid_m_inf;
output  reg         rready_m_inf;
//SRAM
output reg WEN_IN;
output reg [7:0] sram_in_addr;
output reg [4:0] r_temp_data;
// Parameter & Integer
parameter IDLE = 2'b00;
parameter GIVE_ADDR = 2'b01;
parameter READ_FROM_DRAM = 2'b10;
parameter READ_AND_STORE = 2'b11;
// Reg & Wire
reg [1:0] current_state, next_state ; 
reg [4:0] rburst_count;
wire [4:0] Q_IN;
reg [31:0] rdata_buf;
integer trim_cnt;

//-------ASSIGN--------------------------------------------//
// Master //
assign arid_m_inf = 0;
assign arsize_m_inf = 3'b010;
assign arburst_m_inf = 2'b01;
assign arlen_m_inf = 15;
//-------STATE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin 
			if (read_flag==1) next_state = GIVE_ADDR;
			else              next_state = IDLE;
		end
		GIVE_ADDR : begin
			if (arready_m_inf==1 && arvalid_m_inf == 1) next_state = READ_FROM_DRAM;
			else next_state = GIVE_ADDR;
		end
		READ_FROM_DRAM : begin
			if (rvalid_m_inf==1 && rready_m_inf == 1) next_state = READ_AND_STORE;
			else                                      next_state = READ_FROM_DRAM;
		end
		READ_AND_STORE : begin
			if (sram_in_addr==255)   next_state = IDLE;
			else if(rburst_count>=15 &&  rlast_m_inf==0 && (sram_in_addr==63 || sram_in_addr==127 || sram_in_addr==191)) next_state = GIVE_ADDR;
			else if (trim_cnt<3 || (sram_in_addr==62 || sram_in_addr==126 || sram_in_addr==190 || sram_in_addr==254) )     next_state = READ_AND_STORE;
			else                      next_state = READ_FROM_DRAM;
		end
		default : next_state = IDLE;
	endcase
end
//&& (sram_in_addr==63 || sram_in_addr==127 || sram_in_addr==191)
//-------READ ADDRESS CHANNEL--------------------------------------------//
// ADDRESS ASSIGNMENT : 1000 to 1FFF //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		araddr_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin
				if (read_flag==1) araddr_m_inf<= raddr_base;
				else              araddr_m_inf<= 0;
			end
			GIVE_ADDR :           araddr_m_inf<= araddr_m_inf;			
			READ_FROM_DRAM :      araddr_m_inf<= araddr_m_inf;	
			READ_AND_STORE : begin
				if(rburst_count>15 &&  rlast_m_inf==0) araddr_m_inf<= araddr_m_inf + 64;	
				else araddr_m_inf<= araddr_m_inf;
			end
			default : araddr_m_inf<= 0;
		endcase
	end
end
// BURST LENGTH//
//always@(posedge clk or negedge rst_n) begin
    //if (!rst_n) begin
		//arlen_m_inf<= 0;
	//end
	//else begin
		//case(current_state)
			//IDLE : begin
				//if (read_flag==1) arlen_m_inf<= 15;
				//else              arlen_m_inf<= 0;
			//end
			//GIVE_ADDR :           arlen_m_inf<= 15;
			//READ_FROM_DRAM :      arlen_m_inf<= 0;
			//READ_AND_STORE :      arlen_m_inf<= 15;
			
		//endcase
	//end
//end

// BURST COUNTER//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		rburst_count<= 0;
	end
	else begin
		case(current_state)
			IDLE : rburst_count<= 0;
			GIVE_ADDR : rburst_count<= 0;
			READ_FROM_DRAM : begin
				if (rvalid_m_inf==1 && rready_m_inf == 1) rburst_count <= rburst_count ;
				else rburst_count<= rburst_count;
			end			
			READ_AND_STORE : begin
				if ( trim_cnt==3) rburst_count <= rburst_count+1 ;
				else rburst_count<= rburst_count;
			end			
			default : rburst_count<= 0;
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
				if (read_flag==1) arvalid_m_inf<= 1;
				else              arvalid_m_inf<= 0;
			end
			GIVE_ADDR : begin
				if (arready_m_inf == 1) arvalid_m_inf<= 0;
				else arvalid_m_inf<= arvalid_m_inf;
			end
			READ_FROM_DRAM : arvalid_m_inf <= 0;
			READ_AND_STORE : begin
				if (sram_in_addr==255) arvalid_m_inf<= 0;
				else if (rburst_count>15 &&  rlast_m_inf==0) arvalid_m_inf <= 1;
				else arvalid_m_inf<= 0;
			end
			default : arvalid_m_inf<= 0;
		endcase
	end
end
//-------READ DATA CHANNEL--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		sram_in_addr<= 0;
	end
	else begin
		case(current_state)
			IDLE : sram_in_addr<= 0;
			GIVE_ADDR : sram_in_addr <= sram_in_addr;
			READ_FROM_DRAM : sram_in_addr <= sram_in_addr;
			READ_AND_STORE : begin
				if(sram_in_addr==255 && rburst_count==15 && trim_cnt==3 ) sram_in_addr <= 0;
				else if(trim_cnt==0 && (sram_in_addr==0 || sram_in_addr==64|| sram_in_addr==128 || sram_in_addr==192)) sram_in_addr <= sram_in_addr;
				else sram_in_addr <= sram_in_addr+1;
			end
			default : sram_in_addr<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		rdata_buf<= 0;
	end
	else begin
		case(current_state)
			IDLE : rdata_buf<= 0;
			GIVE_ADDR : rdata_buf <= rdata_buf;
			READ_FROM_DRAM : begin
				if (rvalid_m_inf==1 && rready_m_inf == 1 ) rdata_buf <= rdata_m_inf;
				else rdata_buf <= rdata_buf;
			end
			READ_AND_STORE : rdata_buf <= rdata_buf;
			default : rdata_buf<= 0;
		endcase
	end
end


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		r_temp_data<= 0;
	end
	else begin
		case(current_state)
			IDLE : r_temp_data<= 0;
			GIVE_ADDR : r_temp_data <= r_temp_data;
			READ_FROM_DRAM : r_temp_data<=r_temp_data;
			READ_AND_STORE : begin
				if(trim_cnt==0) r_temp_data<= rdata_buf[4:0];
				else if(trim_cnt==1) r_temp_data<= rdata_buf[12:8];
				else if(trim_cnt==2) r_temp_data<= rdata_buf[21:16];
				else if(trim_cnt==3) r_temp_data<= rdata_buf[28:24];
				else r_temp_data<=r_temp_data;
			end
			default : r_temp_data<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		trim_cnt<= 3;
	end
	else begin
		case(current_state)
			IDLE : trim_cnt<= 0;
			GIVE_ADDR : trim_cnt <= trim_cnt;
			READ_FROM_DRAM : trim_cnt<=0;
			READ_AND_STORE : begin
				if(trim_cnt<3) trim_cnt<= trim_cnt+1;
				else trim_cnt<=0;
			end
			default : trim_cnt<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		WEN_IN<= 1;
	end
	else begin
		case(current_state)
			IDLE : WEN_IN<= 1;
			GIVE_ADDR : WEN_IN<= 1;
			READ_FROM_DRAM : WEN_IN<= 1;
			READ_AND_STORE : begin
				if(sram_in_addr==255) WEN_IN<= 1;
				else if(trim_cnt==3) WEN_IN<= 0;
				else WEN_IN<=0;
			end
			default : WEN_IN<= 1;
		endcase
	end
end


always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		rready_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : rready_m_inf<= 0;
			GIVE_ADDR : begin
				if (arready_m_inf==1 && arvalid_m_inf == 1) rready_m_inf <= 0;
				else rready_m_inf <= 0;
			end
			READ_FROM_DRAM : begin
				if (rvalid_m_inf==1 && rready_m_inf==0 ) rready_m_inf<= 1;
				else rready_m_inf<= 0;
			end
			READ_AND_STORE : begin
				if (sram_in_addr==255)   rready_m_inf <= 0;
				else if(rburst_count==15 && trim_cnt==3) rready_m_inf <= 0;
				else if (trim_cnt<3)     rready_m_inf <= 0;
				else                      rready_m_inf <= 0;
			end
			default : rready_m_inf<= 0;
		endcase
	end
end
//-------READ IS FINISHED OR NOT--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		is_finished_read<= 0;
	end
	else begin
		case(current_state)
			IDLE : is_finished_read<= 0;
			GIVE_ADDR : is_finished_read<= 0;
			READ_FROM_DRAM : is_finished_read <=0;
			READ_AND_STORE : begin
				if (sram_in_addr==255) is_finished_read <= 1;
				else                   is_finished_read <= 0;
			end
			default : is_finished_read<= 0;
		endcase
	end
end
endmodule


//---------------------------------------------------------------------
//   Submodule-2 : Write Data from SRAM to DRAM
//---------------------------------------------------------------------
module Write_back_to_DRAM(
	// basic
	clk,
	rst_n,
	write_flag,
	is_finished_write,
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
	wburst_count
);

//-------DECLARATION--------------------------------------------//
input write_flag, clk, rst_n;
output reg is_finished_write;
input wire [31:0] waddr_base;
input wire [31:0] store_data;
// axi write address channel 
output   [3:0]     awid_m_inf;
output  reg [31:0]    awaddr_m_inf;
output   [2:0]     awsize_m_inf;
output   [1:0]     awburst_m_inf;
output  wire [3:0]     awlen_m_inf;
output  reg           awvalid_m_inf;
input   wire           awready_m_inf;
// axi write data channel 
output  reg [31:0]    wdata_m_inf;
output  reg           wlast_m_inf;
output  reg           wvalid_m_inf;
input   wire           wready_m_inf;
// axi write response channel
input   wire [3:0]     bid_m_inf;
input   wire [1:0]     bresp_m_inf;
input   wire           bvalid_m_inf;
output  reg [9:0] wburst_count;
output  reg           bready_m_inf;
// Parameter & Integer
parameter IDLE = 2'b00;
parameter PREPARE = 2'b01;
parameter WRITE_BACK = 2'b10;
// Reg & Wire
reg [1:0]current_state, next_state; 
reg [4:0] wlast_cnt;
//-------ASSIGN--------------------------------------------//
// Master //
assign awid_m_inf = 0;
assign awsize_m_inf = 3'b010;
assign awburst_m_inf = 2'b01;
assign awlen_m_inf = 15;
//-------STATE--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) current_state <= IDLE;
    else current_state <= next_state;
end

always@(*) begin
    case(current_state)
		IDLE : begin 
			if (write_flag==1) next_state = PREPARE;
			else              next_state = IDLE;
		end
		PREPARE: begin
			if (awready_m_inf==1 && awvalid_m_inf == 1) next_state = WRITE_BACK;
			else next_state = PREPARE;
		end
		WRITE_BACK : begin
			if(is_finished_write==1)  	next_state = IDLE;
			else if (bvalid_m_inf==1) 	next_state = PREPARE;
			else                    	next_state = WRITE_BACK;
		end
		default : next_state = IDLE;
	endcase
end

//-------WRITE ADDRESS CHANNEL--------------------------------------------//
// ADDRESS ASSIGNMENT : 1000 to 1FFF //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		awaddr_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : begin 
				if (write_flag==1) awaddr_m_inf <= waddr_base;
				else               awaddr_m_inf <= 0;
			end
			PREPARE : awaddr_m_inf<= awaddr_m_inf;
			WRITE_BACK : begin
				if (wlast_m_inf==1) awaddr_m_inf<= awaddr_m_inf+ 64;
				else 				awaddr_m_inf<= awaddr_m_inf;
			end
			default : awaddr_m_inf<= 0;
		endcase
	end
end
// BURST LENGTH//
//always@(posedge clk or negedge rst_n) begin
    //if (!rst_n) begin
		//awlen_m_inf<= 0;
	//end
	//else begin
		//case(current_state)
			//IDLE : begin 
				//if (write_flag==1) awlen_m_inf <= 15;
				//else               awlen_m_inf <= 0;
			//end
			//PREPARE : awlen_m_inf <= awlen_m_inf;
			//WRITE_BACK : awlen_m_inf <= 15;
			//default : awlen_m_inf <= 15;
		//endcase
	//end
//end

// BURST COUNTER//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		wburst_count<= 0;
	end
	else begin
		case(current_state)
			IDLE : wburst_count<= 0;
			PREPARE : wburst_count<= 0;
			WRITE_BACK : begin
				if (wvalid_m_inf==1 && wready_m_inf==1) wburst_count <= wburst_count+1;
				else wburst_count<= 0;
			end
			default : wburst_count<= 0;
		endcase
	end
end
// Write address valid //
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		awvalid_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : awvalid_m_inf<= 0;
			PREPARE : begin
				if (awready_m_inf==1) awvalid_m_inf <= 0;
				else awvalid_m_inf <= 1;
			end
			WRITE_BACK : begin
				if (bvalid_m_inf==1) awvalid_m_inf <= 1;
				else awvalid_m_inf <= 0;
			end
			default : awvalid_m_inf <= 0;
		endcase
	end
end
//-------WRITE DATA CHANNEL--------------------------------------------//

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		wdata_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : wdata_m_inf<= 0;
			PREPARE : wdata_m_inf<= 0;
			WRITE_BACK : begin
				if (wvalid_m_inf==1) wdata_m_inf <= store_data;
				else                 wdata_m_inf <= wdata_m_inf;
			end
			default : wdata_m_inf<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		wlast_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : wlast_m_inf<= 0;
			PREPARE : wlast_m_inf<= 0;
			WRITE_BACK : begin
				if (wburst_count==14) wlast_m_inf<= 1;
				else                  wlast_m_inf<= 0;
			end
			default : wlast_m_inf<= 0;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		wlast_cnt<= 0;
	end
	else begin
		case(current_state)
			IDLE : wlast_cnt<= 0;
			PREPARE : wlast_cnt<= wlast_cnt;
			WRITE_BACK : begin
				if (wburst_count==15) wlast_cnt<= wlast_cnt+1;
				else                  wlast_cnt<= wlast_cnt;
			end
			default : wlast_cnt<= wlast_cnt;
		endcase
	end
end

always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		wvalid_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : wvalid_m_inf<= 0;
			PREPARE : wvalid_m_inf<= 0;
			WRITE_BACK :  begin
				if (wburst_count>=15 || bvalid_m_inf==1) wvalid_m_inf<= 0;
				else                  wvalid_m_inf <= 1;
			end
			default : wvalid_m_inf<= 0;
		endcase
	end
end

//-------WRITE RESPONSE CHANNEL--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		bready_m_inf<= 0;
	end
	else begin
		case(current_state)
			IDLE : bready_m_inf<= 0;
			PREPARE : bready_m_inf<= 0;
			WRITE_BACK : bready_m_inf <= 1;
			default : bready_m_inf<= 0;
		endcase
	end
end


//-------WRITE IS FINISHED OR NOT--------------------------------------------//
always@(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
		is_finished_write<= 0;
	end
	else begin
		case(current_state)
			IDLE : is_finished_write<= 0;
			PREPARE : is_finished_write<= 0;
			WRITE_BACK : begin
				if (wlast_cnt==16) is_finished_write <= 1;
				else               is_finished_write <= 0;
			end
			default : is_finished_write<= 0;
		endcase
	end
end
			
endmodule








