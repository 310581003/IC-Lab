module bridge(input clk, INF.bridge_inf inf);
import usertype::*;
//================================================================//
//                          READ                                 //
//================================================================//
logic [63:0]  write_data;


always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.AR_VALID <= 0;
	end
	else if(inf.C_in_valid==1 && inf.C_r_wb==1)begin
		inf.AR_VALID <= 1;
	end
	else if(inf.AR_READY==1)begin
		inf.AR_VALID <= 0;
	end
	else begin
		inf.AR_VALID <= inf.AR_VALID;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.AR_ADDR  <= 0;
	end
	else if(inf.C_in_valid==1 && inf.C_r_wb==1)begin
		inf.AR_ADDR  <= {1'b1,16'(inf.C_addr*8)};
	end
	else if(inf.AR_READY==1)begin
		inf.AR_ADDR  <= 0;
	end
	else begin
		inf.AR_ADDR  <= inf.AR_ADDR;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.R_READY <= 0;
	end
	else if(inf.AR_READY==1)begin
		inf.R_READY <= 1;
	end
	else if(inf.R_VALID==1)begin
		inf.R_READY <= 0;
	end
	else inf.R_READY <= inf.R_READY;
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.C_data_r    <= 0;
	end
	else if(inf.R_VALID==1 && inf.R_READY==1 )begin
		inf.C_data_r   <= inf.R_DATA;
	end
	else begin
		inf.C_data_r    <= 0;	
	end
end

//always_ff @(posedge clk or negedge inf.rst_n) begin
	//if(!inf.rst_n)begin
		//read_data    <= 0;
	//end
	//else if(inf.R_READY==1)begin
		//read_data <= inf.R_DATA;
	//end
	//else if(inf.R_VALID==1)begin
		//read_data <= read_data;
	//end
	//else read_data <= read_data;
//end

//================================================================//
//                          WRITE                                 //
//================================================================//

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.AW_VALID <= 0;
		inf.AW_ADDR  <= 0;
	end
	else if(inf.C_in_valid==1 && inf.C_r_wb==0 )begin
		inf.AW_VALID <= 1;
		inf.AW_ADDR  <= {1'b1,16'(inf.C_addr*8)};
	end
	else if(inf.AW_READY==1)begin
		inf.AW_VALID <= 0;
		inf.AW_ADDR  <= 0;
	end
	else begin
		inf.AW_VALID <= inf.AW_VALID;
		inf.AW_ADDR  <= inf.AW_ADDR;
	end
end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.W_VALID <= 0;
	end
	else if(inf.AW_READY==1)begin
		inf.W_VALID <= 1;
	end
	else if(inf.W_READY==1)begin
		inf.W_VALID <= 0;
	end
	else inf.W_VALID <= inf.W_VALID;
end
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		write_data <= 0;
	end
	else if(inf.C_in_valid==1 && inf.C_r_wb == 1'b0)begin
		write_data <= inf.C_data_w;
	end
	else write_data <= write_data;

end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.W_DATA <= 0;
	end
	else if (inf.W_READY==1)begin
		inf.W_DATA <= 0;
	end
	else if(inf.W_VALID==1)begin
		inf.W_DATA <= write_data;
	end
	
	else inf.W_DATA <= 0;

end

always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.B_READY <= 0;
	end
	else if(inf.AW_READY==1)begin
		inf.B_READY <= 1;
	end
	else if(inf.B_VALID==1 && inf.B_READY==1)begin
		inf.B_READY <= 0;
	end
	else inf.B_READY <= inf.B_READY;
end

//================================================================//
//                        Out Valid                                //
//================================================================//
always_ff @(posedge clk or negedge inf.rst_n) begin
    if(!inf.rst_n)begin
		inf.C_out_valid <= 0;
	end
	else if(inf.R_VALID==1 && inf.R_READY==1 )begin
		inf.C_out_valid <= 1;
	end
	else if(inf.B_VALID==1 && inf.B_READY==1 )begin
		inf.C_out_valid <= 1;
	end
	else begin
		inf.C_out_valid <= 0;	
	end
end

endmodule