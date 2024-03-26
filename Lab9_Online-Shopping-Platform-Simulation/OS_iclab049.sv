module OS(input clk, INF.OS_inf inf);
import usertype::*;
//================================================================//
//                     Declaration                                //
//================================================================//
//-----------------------FSM----------------------------------//
typedef enum logic  [4:0] {	S_IDLE			       = 5'd0,
							S_ACTION               = 5'd1,
							S_BUY                  = 5'd2,
							S_CHECK                = 5'd3,
							S_DEPOSIT			   = 5'd4,
							S_RETURN		       = 5'd5,
							S_OUT  			       = 5'd6} fsm_state;

fsm_state current_state, next_state;
//---------------------ID------------------------------//
User_id cur_user_id, cur_seller_id;
//------------------Action--------------------------//
Action cur_action;
//------------------Info--------------------------//
Shop_Info buyer_shop_info, seller_shop_info;
User_Info buyer_user_info, seller_user_info;
//------------------Buy--------------------------//
Item_id cur_item_id;
Item_num cur_item_num;
//----------------Deposit-----------------------//
Money cur_money_amnt;
//-----------------Error-------------------------//
typedef enum logic [3:0] { 
	No_Err					= 4'b0000, //	No error
	INV_Not_Enough	= 4'b0010, //	Seller's inventory is not enough
	Out_of_money		= 4'b0011, //	Out of money
	INV_Full				= 4'b0100, //	User's inventory is full 
	Wallet_is_Full	= 4'b1000, //	Wallet is full
	Wrong_ID				= 4'b1001, //	Wrong seller ID 
	Wrong_Num				= 4'b1100, //	Wrong number
	Wrong_Item			= 4'b1010, //	Wrong item
	Wrong_act				= 4'b1111  //	Wrong operation
}	Err_Msg ;
Err_Msg cur_err;
//---------------------Logic------------------------------//
logic [1:0]user_change_flag, seller_id_flag;
logic [2:0] is_finished ;
logic [8:0] last_record [255:0];
logic history [255:0];
integer i;
//================================================================//
//                          design                                //
//================================================================//

//------------------- STATE -----------------------//

always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		current_state <= S_IDLE;
	end
	else begin
		current_state <= next_state;
	end
end

always_comb begin
	if(!inf.rst_n) begin
		next_state = 0;
	end
	case(current_state)
		S_IDLE : begin
			if (inf.id_valid==1) next_state=S_ACTION;
			else                 next_state=S_IDLE;
		end
		S_ACTION : begin
			case(cur_action)
				Buy : 	    next_state=S_BUY;
				Check : 	next_state=S_CHECK;
				Deposit : 	next_state=S_DEPOSIT;	 
				Return : 	next_state=S_RETURN;
				default :   next_state=S_ACTION;
			endcase
		end
		S_BUY : begin
			if ((is_finished==3 && cur_err!=No_Err) || is_finished==5) 	next_state=S_OUT;
			else 															next_state=S_BUY;
		end
		S_CHECK : begin
			if (is_finished==7) 	next_state=S_OUT;
			else 					next_state=S_CHECK;
		end
		S_DEPOSIT : begin
			if ((is_finished==2 && cur_err!=No_Err)||is_finished==3) 	next_state=S_OUT;
			else 														next_state=S_DEPOSIT;
		end
		S_RETURN : begin
			if ((is_finished==3 && cur_err!=No_Err) || is_finished==5) 	next_state=S_OUT;
			else 															next_state=S_RETURN;
		end
		S_OUT : next_state=S_ACTION;
		default : next_state=S_IDLE;
	endcase
end		
		
//-------------------User ID------------------------------//
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_user_id <= 0;
	end
	else begin
		case(current_state)
			S_IDLE : begin
				if (inf.id_valid==1) cur_user_id <= inf.D.d_id[0];
				else                 cur_user_id <= cur_user_id;
			end
			S_ACTION : begin
				if (inf.id_valid==1) cur_user_id <= inf.D.d_id[0];
				else                 cur_user_id <= cur_user_id;
			end
			S_RETURN : cur_user_id <= cur_user_id;
			S_CHECK : cur_user_id <= cur_user_id;
			S_OUT : 	cur_user_id <= cur_user_id;
			default : cur_user_id <= cur_user_id;
		endcase
	end
end

//-----------------user_change_flag------------------------//
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		user_change_flag <= 2'd0;
	end
	else begin
		case(current_state)
			S_IDLE : begin
				if (inf.id_valid==1) user_change_flag <= 2'd1;
				else                 user_change_flag <= user_change_flag;
			end
			S_ACTION : begin
				if (inf.id_valid==1) user_change_flag <= 2'd1;
				else                 user_change_flag <= user_change_flag;
			end
			S_BUY : begin
				if (user_change_flag==1 && is_finished==0) user_change_flag <= 2'd2;
				else if (user_change_flag<=2 && is_finished==3 && cur_err==No_Err) user_change_flag <= 2'd3;
				else                 user_change_flag <= user_change_flag;
			end
			S_CHECK: begin
				if (is_finished==5  && user_change_flag == 1) user_change_flag <= 2'd2;
				else                 						 user_change_flag <= user_change_flag;
			end
			S_DEPOSIT : begin
				if (user_change_flag==1 && is_finished==0) user_change_flag <= 2'd2;
				else                 user_change_flag <= user_change_flag;
			end
			S_RETURN : begin
				if (user_change_flag==1 && is_finished==0) user_change_flag <= 2'd2;
				else if (user_change_flag<=2 && is_finished==3 && cur_err==No_Err) user_change_flag <= 2'd3;
				else                 user_change_flag <= user_change_flag;
			end
			S_OUT:                   user_change_flag <= 0;
			default :                user_change_flag <= 0;
		endcase
	end
end

//------------------Action--------------------------//
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_action <= No_action;
	end
	else begin
		case(current_state)
			S_ACTION : begin
				if (inf.act_valid==1) cur_action <= inf.D.d_act[0];
				else                 cur_action <= cur_action;
			end
			S_OUT : cur_action <= No_action;
			default : cur_action <= cur_action;
		endcase
	end
end

//-------------------seller_id_flag---------------------------//
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		seller_id_flag <= 0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				if (inf.id_valid==1) 	seller_id_flag <= 1;
				else if(seller_id_flag==1 && is_finished==1) seller_id_flag <= 2;
				else if (seller_id_flag==2 && is_finished==4 && cur_err==No_Err) seller_id_flag <= 3;
				else                 	seller_id_flag <= seller_id_flag;
			end
			S_CHECK : begin
				if (is_finished<=4 && inf.id_valid==1) 	seller_id_flag <= 1;
				else if(is_finished==6 && seller_id_flag==1) seller_id_flag <= 2;
				else 									seller_id_flag <= seller_id_flag;
			end
			S_DEPOSIT : begin
				if (inf.amnt_valid==1)     seller_id_flag <= 1;
				else if (seller_id_flag==1 &&is_finished==2)   seller_id_flag <= 2;
				else                       seller_id_flag <= seller_id_flag;  
			end
			S_RETURN : begin
				if (inf.id_valid==1) 	seller_id_flag <= 1;
				else if(seller_id_flag==1 && is_finished==1) seller_id_flag <= 2;
				else if (seller_id_flag==2 && is_finished==4 && cur_err==No_Err) seller_id_flag <= 3;
				else                 	seller_id_flag <= seller_id_flag;
			end
			
			default : seller_id_flag <= 0;
		endcase
	end
end

//--------------------Get input-----------------------------//

// Get item id
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_item_id <= No_item;
	end
	else begin
		case(current_state)
			S_BUY : begin
				if (inf.item_valid==1) 	cur_item_id <= inf.D.d_item[0];
				else                 	cur_item_id <= cur_item_id;
			end
			S_RETURN : begin
				if (inf.item_valid==1) 	cur_item_id <= inf.D.d_item[0];
				else                 	cur_item_id <= cur_item_id;
			end
			S_OUT : cur_item_id <= 0;
			default : cur_item_id <= cur_item_id;
		endcase
	end
end

// Get item number
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_item_num <= 0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				if (inf.num_valid==1) 	cur_item_num <= inf.D.d_item_num;
				else                 	cur_item_num <= cur_item_num;
			end
			S_RETURN : begin
				if (inf.num_valid==1) 	cur_item_num <= inf.D.d_item_num;
				else                 	cur_item_num <= cur_item_num;
			end
			S_OUT : cur_item_num <= cur_item_num;
			default : cur_item_num <= cur_item_num;
		endcase
	end
end

// Get seller id
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_seller_id <= 0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				if (inf.id_valid==1) 	cur_seller_id <= inf.D.d_id[0];
				else                 	cur_seller_id <= cur_seller_id;
			end
			S_CHECK : begin
				if (is_finished<=4 && inf.id_valid==1) 	cur_seller_id <= inf.D.d_id[0];
				else 									cur_seller_id <= cur_seller_id;
			end
			S_RETURN : begin
				if (inf.id_valid==1) 	cur_seller_id <= inf.D.d_id[0];
				else 					cur_seller_id <= cur_seller_id;
			end
			S_OUT : cur_seller_id <= 0;
			default : cur_seller_id <= cur_seller_id;
		endcase
	end
end

// Get deposit amount
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_money_amnt <= 0;
	end
	else begin
		case(current_state)
			S_DEPOSIT : begin
				if (inf.amnt_valid==1) 	cur_money_amnt <= inf.D.d_money;
				else                 	cur_money_amnt <= cur_money_amnt;
			end
			S_OUT : cur_money_amnt <= 0;
			default : cur_money_amnt <= cur_money_amnt;
		endcase
	end
end
//-----------------History & Record----------------------------//


always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		for(i=0;i<256;i=i+1)begin
			history[i] <= 0;
			last_record[i]<=0;
		end
		
	end
	else begin
		case(current_state)
			S_BUY : begin
				if (is_finished==3 && cur_err==No_Err ) begin
					history[cur_seller_id] <= 1 ;
					history[cur_user_id] <= 1 ;
					last_record[cur_seller_id] <= {1'd1,cur_user_id};
					last_record[cur_user_id] <= {1'd0,cur_seller_id};
				end
				else  begin
					for(i=0;i<256;i=i+1)begin
						history[i] <= history[i];
						last_record[i]<=last_record[i];
					end
				end
			end
			S_CHECK : begin
				if (is_finished<=4 && inf.id_valid==1) begin 
					history[cur_user_id] <= 0 ;
					history[inf.D.d_id[0]] <=0 ;
					last_record[inf.D.d_id[0]] <= last_record[inf.D.d_id[0]];
				end
				else if (is_finished==4 && inf.id_valid==0) begin
					history[cur_user_id] <= 0 ;
					last_record[cur_user_id] <= last_record[cur_user_id];
				end
				else begin
					for(i=0;i<256;i=i+1)begin
						history[i] <= history[i];
						last_record[i]<=last_record[i];
					end
				end
			end
			S_DEPOSIT : begin
				if (is_finished==2 && cur_err==No_Err) begin
					history[cur_user_id] <= 0 ;
					last_record[cur_user_id] <= last_record[cur_user_id];
				end
				else begin
					for(i=0;i<256;i=i+1)begin
						history[i] <= history[i];
						last_record[i]<=last_record[i];
					end
				end
			end
			S_RETURN : begin
				if (is_finished==3 && cur_err==No_Err) begin
					history[cur_user_id] <= 0 ;
					history[cur_seller_id] <= 0 ;
					for(i=0;i<256;i=i+1)begin
						last_record[i]<=last_record[i];
					end
				end
				else begin
					for(i=0;i<256;i=i+1)begin
						history[i] <= history[i];
						last_record[i]<=last_record[i];
					end
				end
			end
				
			default : begin
				for(i=0;i<256;i=i+1)begin
					history[i] <= history[i];
					last_record[i]<=last_record[i];
				end
			end
		endcase
	end
end
//-------------------Reflash info----------------------------//

//Buyer shop info
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		buyer_shop_info<=0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Get Buyer info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0)begin 
					// shop info
					buyer_shop_info.large_num <= inf.C_data_r[7:2];
					buyer_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					buyer_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					buyer_shop_info.level <= inf.C_data_r[21:20];
					buyer_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				else if(user_change_flag==0 && is_finished==0)begin 
					buyer_shop_info <= buyer_shop_info;
				end
				// Do "Buy"
				else if (is_finished==2) begin
					case (cur_item_id)
						Large: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d10 && seller_shop_info.large_num>=cur_item_num) begin
											buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
											buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
											buyer_shop_info.small_num <= buyer_shop_info.small_num;
											buyer_shop_info.level <= Platinum;
											buyer_shop_info.exp <= 12'd0;
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Gold : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d30 && seller_shop_info.large_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d60>='d4000)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Platinum;
												buyer_shop_info.exp <= 12'd0;
											end
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Gold;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d60;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Silver : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d50 && seller_shop_info.large_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d60>='d2500)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Gold;
												buyer_shop_info.exp <= 12'd0;
											end										
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Silver;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d60;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Copper : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d70 && seller_shop_info.large_num>=cur_item_num) begin										
											if (buyer_shop_info.exp+cur_item_num*'d60>='d1000)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Silver;
												buyer_shop_info.exp <= 12'd0;
											end
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num+cur_item_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Copper;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d60;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
							endcase	
						end
						Medium: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d10 && seller_shop_info.medium_num>=cur_item_num) begin
											buyer_shop_info.large_num <= buyer_shop_info.large_num;
											buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
											buyer_shop_info.small_num <= buyer_shop_info.small_num;
											buyer_shop_info.level <= Platinum;
											buyer_shop_info.exp <= 12'd0;
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Gold : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d30 && seller_shop_info.medium_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d40>='d4000)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Platinum;
												buyer_shop_info.exp <= 12'd0;
											end
											else begin
												buyer_shop_info.medium_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Gold;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d40;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Silver : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d50 && seller_shop_info.medium_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d40>='d2500)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Gold;
												buyer_shop_info.exp <= 12'd0;
											end										
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Silver;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d40;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Copper : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d70 && seller_shop_info.medium_num>=cur_item_num) begin	
											if (buyer_shop_info.exp+cur_item_num*'d40>='d1000)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Silver;
												buyer_shop_info.exp <= 12'd0;
											end
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num+cur_item_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num;
												buyer_shop_info.level <= Copper;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d40;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
							endcase	
						end
						Small: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d10 && seller_shop_info.small_num>=cur_item_num) begin
											buyer_shop_info.large_num <= buyer_shop_info.large_num;
											buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
											buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
											buyer_shop_info.level <= Platinum;
											buyer_shop_info.exp <= 12'd0;
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Gold : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d30 && seller_shop_info.small_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d20>='d4000)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
												buyer_shop_info.level <= Platinum;
												buyer_shop_info.exp <= 12'd0;
											end
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
												buyer_shop_info.level <= Gold;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d20;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Silver : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d50 && seller_shop_info.small_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d20>='d2500 )begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
												buyer_shop_info.level <= Gold;
												buyer_shop_info.exp <= 12'd0;
											end										
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
												buyer_shop_info.level <= Silver;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d20;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
									Copper : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d70 && seller_shop_info.small_num>=cur_item_num) begin
											if (buyer_shop_info.exp+cur_item_num*'d20>='d1000)begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
												buyer_shop_info.level <= Silver;
												buyer_shop_info.exp <= 12'd0;
											end
											else begin
												buyer_shop_info.large_num <= buyer_shop_info.large_num;
												buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
												buyer_shop_info.small_num <= buyer_shop_info.small_num+cur_item_num;
												buyer_shop_info.level <= Copper;
												buyer_shop_info.exp <= buyer_shop_info.exp+cur_item_num*'d20;
											end
										end
										else buyer_shop_info <= buyer_shop_info;
									end
							endcase	
						end
					endcase
				end
				else buyer_shop_info <= buyer_shop_info;
			end
			S_CHECK : begin
				if (is_finished==5  && inf.C_out_valid==1 && user_change_flag == 2)begin
					buyer_shop_info.large_num <= inf.C_data_r[7:2];
					buyer_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					buyer_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					buyer_shop_info.level <= inf.C_data_r[21:20];
					buyer_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				else buyer_shop_info <= buyer_shop_info;
			end
			S_DEPOSIT : begin
				if (user_change_flag==2 && inf.C_out_valid==1 && is_finished==0) begin
					buyer_shop_info.large_num <= inf.C_data_r[7:2];
					buyer_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					buyer_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					buyer_shop_info.level <= inf.C_data_r[21:20];
					buyer_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				else buyer_shop_info <= buyer_shop_info;
			end
			S_RETURN : begin
				// Get Buyer info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0)begin 
					// shop info
					buyer_shop_info.large_num <= inf.C_data_r[7:2];
					buyer_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					buyer_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					buyer_shop_info.level <= inf.C_data_r[21:20];
					buyer_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				else if(user_change_flag==0 && is_finished==0)begin 
					buyer_shop_info <= buyer_shop_info;
				end
				// Do "Return"
				else if (is_finished==2) begin
					if (history[cur_user_id]==0 || history[buyer_user_info.shop_history.seller_ID]==0 
						|| last_record[buyer_user_info.shop_history.seller_ID][8]!=1'b1
						|| (last_record[buyer_user_info.shop_history.seller_ID][8]==1 && last_record[buyer_user_info.shop_history.seller_ID][7:0]!=cur_user_id)
						|| last_record[cur_user_id][8]!=1'b0
						|| (last_record[cur_user_id][8]==1'b0 && last_record[cur_user_id][7:0]!=buyer_user_info.shop_history.seller_ID)
						|| buyer_user_info.shop_history.seller_ID != cur_seller_id
						|| buyer_user_info.shop_history[13:8]!=cur_item_num
						|| buyer_user_info.shop_history[15:14]!=cur_item_id) begin
						
						buyer_shop_info <= buyer_shop_info;
					end
					
					else begin
						case(cur_item_id)
							Large : begin
								buyer_shop_info.large_num <= buyer_shop_info.large_num-cur_item_num;
								buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
								buyer_shop_info.small_num <= buyer_shop_info.small_num;
								buyer_shop_info.level <= buyer_shop_info.level;
								buyer_shop_info.exp <= buyer_shop_info.exp;
							end
							Medium : begin
								buyer_shop_info.large_num <= buyer_shop_info.large_num;
								buyer_shop_info.medium_num <= buyer_shop_info.medium_num-cur_item_num;
								buyer_shop_info.small_num <= buyer_shop_info.small_num;
								buyer_shop_info.level <= buyer_shop_info.level;
								buyer_shop_info.exp <= buyer_shop_info.exp;
							end
							Small : begin
								buyer_shop_info.large_num <= buyer_shop_info.large_num;
								buyer_shop_info.medium_num <= buyer_shop_info.medium_num;
								buyer_shop_info.small_num <= buyer_shop_info.small_num-cur_item_num;
								buyer_shop_info.level <= buyer_shop_info.level;
								buyer_shop_info.exp <= buyer_shop_info.exp;
							end
						endcase
					end
				
				end
				else buyer_shop_info <= buyer_shop_info;
			end		
			default : buyer_shop_info <= buyer_shop_info;
		endcase
	end
end

//Buyer user info
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		buyer_user_info <= 0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Get Buyer info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0)begin 
					// user info
					buyer_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					buyer_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				else if(user_change_flag==0 && is_finished==0)begin 
					buyer_user_info <= buyer_user_info;
				end
				// Do "Buy"
				else if (is_finished==2) begin
					case (cur_item_id)
						Large: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d10 && seller_shop_info.large_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d300+'d10);
											buyer_user_info.shop_history[15:14] <= Large;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Gold : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d30 && seller_shop_info.large_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d300+'d30);
											buyer_user_info.shop_history[15:14] <= Large;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Silver : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d50 && seller_shop_info.large_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d300+'d50);
											buyer_user_info.shop_history[15:14] <= Large;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Copper : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d70 && seller_shop_info.large_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d300+'d70);
											buyer_user_info.shop_history[15:14] <= Large;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
							endcase	
						end
						Medium: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d10 && seller_shop_info.medium_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d200+'d10);
											buyer_user_info.shop_history[15:14] <= Medium;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Gold : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d30 && seller_shop_info.medium_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d200+'d30);
											buyer_user_info.shop_history[15:14] <= Medium;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Silver : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d50 && seller_shop_info.medium_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d200+'d50);
											buyer_user_info.shop_history[15:14] <= Medium;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Copper : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d70 && seller_shop_info.medium_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d200+'d70);
											buyer_user_info.shop_history[15:14] <= Medium;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
							endcase	
						end
						Small: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d10 && seller_shop_info.small_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d100+'d10);
											buyer_user_info.shop_history[15:14] <= Small;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Gold : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d30 && seller_shop_info.small_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d100+'d30);
											buyer_user_info.shop_history[15:14] <= Small;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Silver : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d50 && seller_shop_info.small_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d100+'d50);
											buyer_user_info.shop_history[15:14] <= Small;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
									Copper : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d70 && seller_shop_info.small_num>=cur_item_num) begin
											buyer_user_info.money <= buyer_user_info.money-(cur_item_num*'d100+'d70);
											buyer_user_info.shop_history[15:14] <= Small;
											buyer_user_info.shop_history[13:8] <= cur_item_num;
											buyer_user_info.shop_history[7:0] <= cur_seller_id;
										end
										else buyer_user_info <= buyer_user_info;
									end
							endcase	
						end				
					endcase
				end
				else buyer_user_info <= buyer_user_info;
			end
			S_CHECK : begin
				if (is_finished==5  && inf.C_out_valid==1 && user_change_flag == 2)begin
					buyer_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					buyer_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				else buyer_user_info <= buyer_user_info;
			end
			S_DEPOSIT : begin
				if (user_change_flag==2 && inf.C_out_valid==1 && is_finished==0) begin
					buyer_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					buyer_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				else if (seller_id_flag == 1 && is_finished==1) begin
					buyer_user_info.shop_history <= buyer_user_info.shop_history;
					if (buyer_user_info.money+cur_money_amnt<buyer_user_info.money) 	buyer_user_info.money <= buyer_user_info.money;
					else 																buyer_user_info.money <= buyer_user_info.money+cur_money_amnt;
				end	
				else buyer_user_info <= buyer_user_info;
			end
			S_RETURN : begin
				// Get Buyer info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0)begin 
					// user info
					buyer_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					buyer_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				else if(user_change_flag==0 && is_finished==0)begin 
					buyer_user_info <= buyer_user_info;
				end
				// Do "Return"
				else if (is_finished==2) begin
					if (history[cur_user_id]==0 || history[buyer_user_info.shop_history.seller_ID]==0 
						|| last_record[buyer_user_info.shop_history.seller_ID][8]!=1'b1
						|| (last_record[buyer_user_info.shop_history.seller_ID][8]==1 && last_record[buyer_user_info.shop_history.seller_ID][7:0]!=cur_user_id)
						|| last_record[cur_user_id][8]!=1'b0
						|| (last_record[cur_user_id][8]==1'b0 && last_record[cur_user_id][7:0]!=buyer_user_info.shop_history.seller_ID)
						|| buyer_user_info.shop_history.seller_ID != cur_seller_id
						|| buyer_user_info.shop_history[13:8]!=cur_item_num
						|| buyer_user_info.shop_history[15:14]!=cur_item_id) begin
							
							buyer_user_info <= buyer_user_info;
					end
					else begin
						case(cur_item_id)
							Large : begin
								buyer_user_info.money <= buyer_user_info.money + cur_item_num*'d300;
								buyer_user_info.shop_history <= buyer_user_info.shop_history;
							end
							Medium : begin
								buyer_user_info.money <= buyer_user_info.money + cur_item_num*'d200;
								buyer_user_info.shop_history <= buyer_user_info.shop_history;
							end
							Small : begin
								buyer_user_info.money <= buyer_user_info.money + cur_item_num*'d100;
								buyer_user_info.shop_history <= buyer_user_info.shop_history;
							end
						endcase
					end
				
				end
			
			end		
			default : buyer_user_info <= buyer_user_info;
		endcase
	end
end

// Seller shop info
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		seller_shop_info<=0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Get Buyer info
				if(seller_id_flag==2 && inf.C_out_valid==1 && is_finished==1)begin 
					// shop info
					seller_shop_info.large_num <= inf.C_data_r[7:2];
					seller_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					seller_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					seller_shop_info.level <= inf.C_data_r[21:20];
					seller_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				// Do "Buy"
				else if (is_finished==2) begin
					case (cur_item_id)
						Large: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d10 && seller_shop_info.large_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num-cur_item_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Gold : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d30 && seller_shop_info.large_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num-cur_item_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Silver : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d50 && seller_shop_info.large_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num-cur_item_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Copper : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d70 && seller_shop_info.large_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num-cur_item_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
							endcase	
						end
						Medium: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d10 && seller_shop_info.medium_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num-cur_item_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Gold : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d30 && seller_shop_info.medium_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num-cur_item_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Silver : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d50 && seller_shop_info.medium_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num-cur_item_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Copper : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d70 && seller_shop_info.medium_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num-cur_item_num;
											seller_shop_info.small_num <= seller_shop_info.small_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
							endcase	
						end
						Small: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d10 && seller_shop_info.small_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num-cur_item_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Gold : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d30 && seller_shop_info.small_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num-cur_item_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Silver : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d50 && seller_shop_info.small_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num-cur_item_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
									Copper : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d70 && seller_shop_info.small_num>=cur_item_num) begin
											seller_shop_info.large_num <= seller_shop_info.large_num;
											seller_shop_info.medium_num <= seller_shop_info.medium_num;
											seller_shop_info.small_num <= seller_shop_info.small_num-cur_item_num;
											seller_shop_info.level <= seller_shop_info.level;
											seller_shop_info.exp <= seller_shop_info.exp;
										end
										else seller_shop_info <= seller_shop_info;
									end
							endcase	
						end
					endcase
				end
				else seller_shop_info <= seller_shop_info;
			end
			S_CHECK : begin
				if (is_finished==6 && inf.C_out_valid==1 && seller_id_flag==2)begin
					seller_shop_info.large_num <= inf.C_data_r[7:2];
					seller_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					seller_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					seller_shop_info.level <= inf.C_data_r[21:20];
					seller_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				else seller_shop_info <= seller_shop_info;
			end
			S_RETURN : begin
				// Get Buyer info
				if(seller_id_flag==2 && inf.C_out_valid==1 && is_finished==1)begin 
					// shop info
					seller_shop_info.large_num <= inf.C_data_r[7:2];
					seller_shop_info.medium_num <= {inf.C_data_r[1:0], inf.C_data_r[15:12]};
					seller_shop_info.small_num <= {inf.C_data_r[11:8], inf.C_data_r[23:22]};
					seller_shop_info.level <= inf.C_data_r[21:20];
					seller_shop_info.exp <= {inf.C_data_r[19:16], inf.C_data_r[31:28], inf.C_data_r[27:24]};
				end
				// Do "Return"
				else if (is_finished==2) begin
					if (history[cur_user_id]==0 || history[buyer_user_info.shop_history.seller_ID]==0 
						|| last_record[buyer_user_info.shop_history.seller_ID][8]!=1'b1
						|| (last_record[buyer_user_info.shop_history.seller_ID][8]==1 && last_record[buyer_user_info.shop_history.seller_ID][7:0]!=cur_user_id)
						|| last_record[cur_user_id][8]!=1'b0
						|| (last_record[cur_user_id][8]==1'b0 && last_record[cur_user_id][7:0]!=buyer_user_info.shop_history.seller_ID)
						|| buyer_user_info.shop_history.seller_ID != cur_seller_id
						|| buyer_user_info.shop_history[13:8]!=cur_item_num
						|| buyer_user_info.shop_history[15:14]!=cur_item_id) begin
						
						seller_shop_info <= seller_shop_info;
					end
					else begin
						case(cur_item_id)
							Large : begin
								seller_shop_info.large_num <= seller_shop_info.large_num+cur_item_num;
								seller_shop_info.medium_num <= seller_shop_info.medium_num;
								seller_shop_info.small_num <= seller_shop_info.small_num;
								seller_shop_info.level <= seller_shop_info.level;
								seller_shop_info.exp <= seller_shop_info.exp;
							end
							Medium : begin
								seller_shop_info.large_num <= seller_shop_info.large_num;
								seller_shop_info.medium_num <= seller_shop_info.medium_num+cur_item_num;
								seller_shop_info.small_num <= seller_shop_info.small_num;
								seller_shop_info.level <= seller_shop_info.level;
								seller_shop_info.exp <= seller_shop_info.exp;
							end
							Small : begin
								seller_shop_info.large_num <= seller_shop_info.large_num;
								seller_shop_info.medium_num <= seller_shop_info.medium_num;
								seller_shop_info.small_num <= seller_shop_info.small_num+cur_item_num;
								seller_shop_info.level <= seller_shop_info.level;
								seller_shop_info.exp <= seller_shop_info.exp;
							end
						endcase
					end
				
				end
				else seller_shop_info <= seller_shop_info;
			end	
			default : seller_shop_info <= seller_shop_info;
		endcase
	end
end


// Seller user info
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		seller_user_info<=0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Get Buyer info
				if(seller_id_flag==2 && inf.C_out_valid==1 && is_finished==1)begin 
					// shop info
					seller_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					seller_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				// Do "Buy"
				else if (is_finished==2) begin
					seller_user_info.shop_history <= seller_user_info.shop_history;
					case (cur_item_id)
						Large: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d10 && seller_shop_info.large_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d300;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Gold : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d30 && seller_shop_info.large_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d300;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Silver : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d50 && seller_shop_info.large_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d300;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Copper : begin
										if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d70 && seller_shop_info.large_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d300;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
							endcase	
						end
						Medium: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d10 && seller_shop_info.medium_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d200;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Gold : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d30 && seller_shop_info.medium_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d200;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Silver : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d50 && seller_shop_info.medium_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d200;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Copper : begin
										if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d70 && seller_shop_info.medium_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d200;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
							endcase	
						end
						Small: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d10 && seller_shop_info.small_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d100;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Gold : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d30 && seller_shop_info.small_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d100;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Silver : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d50 && seller_shop_info.small_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d100;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
									Copper : begin
										if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d70 && seller_shop_info.small_num>=cur_item_num) begin
											if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money <= 16'd65535;
											else  														seller_user_info.money <= seller_user_info.money+cur_item_num*'d100;										
										end
										else seller_user_info.money <= seller_user_info.money;
									end
							endcase	
						end
					endcase
				end
				else seller_user_info <= seller_user_info;
			end
			S_CHECK : begin
				if (is_finished==6 && inf.C_out_valid==1 && seller_id_flag==2)begin
					seller_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					seller_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				else seller_user_info <= seller_user_info;
			end
			S_RETURN : begin
				// Get Buyer info
				if(seller_id_flag==2 && inf.C_out_valid==1 && is_finished==1)begin 
					// shop info
					seller_user_info.money <= {inf.C_data_r[39:36], inf.C_data_r[35:32], inf.C_data_r[47:44], inf.C_data_r[43:40]};
					seller_user_info.shop_history <= {inf.C_data_r[55:54], inf.C_data_r[53:52], inf.C_data_r[51:48], inf.C_data_r[63:56]};
				end
				// Do "Return"
				else if (is_finished==2) begin
					if (history[cur_user_id]==0 || history[buyer_user_info.shop_history.seller_ID]==0 
						|| last_record[buyer_user_info.shop_history.seller_ID][8]!=1'b1
						|| (last_record[buyer_user_info.shop_history.seller_ID][8]==1 && last_record[buyer_user_info.shop_history.seller_ID][7:0]!=cur_user_id)
						|| last_record[cur_user_id][8]!=1'b0
						|| (last_record[cur_user_id][8]==1'b0 && last_record[cur_user_id][7:0]!=buyer_user_info.shop_history.seller_ID)
						|| buyer_user_info.shop_history.seller_ID != cur_seller_id
						|| buyer_user_info.shop_history[13:8]!=cur_item_num
						|| buyer_user_info.shop_history[15:14]!=cur_item_id) begin
						
						seller_user_info <= seller_user_info;
					end
					else begin
						case(cur_item_id)
							Large : begin
								seller_user_info.money <= seller_user_info.money - cur_item_num*'d300;
								seller_user_info.shop_history <= seller_user_info.shop_history;
							end
							Medium : begin
								seller_user_info.money <= seller_user_info.money - cur_item_num*'d200;
								seller_user_info.shop_history <= seller_user_info.shop_history;
							end
							Small : begin
								seller_user_info.money <= seller_user_info.money - cur_item_num*'d100;
								seller_user_info.shop_history <= seller_user_info.shop_history;
							end
						endcase
					end
					
				end
				else seller_user_info <= seller_user_info;
			end	
			default : seller_user_info <= seller_user_info;
		endcase
	end
end
//------------------Err msg---------------------------//
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		cur_err<=No_Err;
	end
	else begin
		case(current_state)
			S_BUY : begin
				if (is_finished==2) begin
					case (cur_item_id)
						Large: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.large_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d300+'d10)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Gold : begin
										if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.large_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d300+'d30)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Silver : begin
										if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.large_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d300+'d50)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Copper : begin
										if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.large_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d300+'d70)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
							endcase	
						end
						Medium: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.medium_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d200+'d10)				cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Gold : begin
										if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.medium_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d200+'d30)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Silver : begin
										if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.medium_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d200+'d50)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Copper : begin
										if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.medium_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d200+'d70)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
							endcase	
						end
						Small: begin
							case (buyer_shop_info.level)
									Platinum : begin
										if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.small_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d100+'d10)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Gold : begin
										if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.small_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d100+'d30)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Silver : begin
										if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.small_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d100+'d50)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
									Copper : begin
										if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err <= INV_Full;
										else if (seller_shop_info.small_num<cur_item_num)						cur_err <= INV_Not_Enough;
										else if (buyer_user_info.money<cur_item_num*'d100+'d70)					cur_err <= Out_of_money;										
										else																	cur_err <= No_Err;
									end
							endcase	
						end
					endcase
				end
				else cur_err<=cur_err;
			end
			S_DEPOSIT : begin
				if (seller_id_flag == 1 && is_finished==1) begin
					if (buyer_user_info.money+cur_money_amnt<buyer_user_info.money) 	cur_err <= Wallet_is_Full;
					else 																cur_err <= No_Err;
				end
				else  cur_err<=cur_err;
			end
			S_RETURN : begin
				if (is_finished==2) begin
					
					if (history[cur_user_id]==0 || history[buyer_user_info.shop_history.seller_ID]==0 
						|| last_record[buyer_user_info.shop_history.seller_ID][8]!=1'b1
						|| (last_record[buyer_user_info.shop_history.seller_ID][8]==1 && last_record[buyer_user_info.shop_history.seller_ID][7:0]!=cur_user_id)
						|| last_record[cur_user_id][8]!=1'b0
						|| (last_record[cur_user_id][8]==1'b0 && last_record[cur_user_id][7:0]!=buyer_user_info.shop_history.seller_ID)) cur_err <= Wrong_act;
					else if (buyer_user_info.shop_history.seller_ID != cur_seller_id ) cur_err <= Wrong_ID;
				
					//if (history[cur_seller_id][cur_user_id]==0) cur_err <= Wrong_ID;
					//else if (history[cur_seller_id][cur_seller_id]==0 || history[cur_user_id][cur_user_id]==0 || buyer_user_info.shop_history[7:0]!=cur_seller_id 
								//|| last_record[cur_seller_id][7:0]!=cur_user_id || last_record[cur_seller_id][8]!=1) cur_err <= Wrong_act;
					else if (buyer_user_info.shop_history[13:8]!=cur_item_num) cur_err <= Wrong_Num;
					else if (buyer_user_info.shop_history[15:14]!=cur_item_id) cur_err <= Wrong_Item;
					
					
					
					else cur_err <= No_Err;
				end
				else cur_err<=cur_err;				
			end
			S_OUT : cur_err<=cur_err;
			default : cur_err<=No_Err;
		endcase
	end
end

//------------------- DRAM : Read & Write-----------------------//
// is_finished
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		is_finished<=0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Get User info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0) 	is_finished<=1;
				else if (user_change_flag==0 && is_finished==0)                      is_finished<=1;
				// Get Seller info
				else if(seller_id_flag==2 && inf.C_out_valid==1 && is_finished==1) 	is_finished<=2;
				// Reflash info or Error msg
				else if (is_finished==2)											is_finished<=3;
				// Write back to DRAM
				else if (user_change_flag == 3 && is_finished==3 && inf.C_out_valid == 1)	is_finished<=4;
				else if (seller_id_flag==3 &&is_finished==4 && inf.C_out_valid == 1)		is_finished<=5;
				else 																is_finished<=is_finished;
			end
			S_CHECK : begin
				if (is_finished<5) 	is_finished<=is_finished + 1;
				else if ((is_finished==5  && inf.C_out_valid==1 && user_change_flag == 2) || (is_finished==5  && user_change_flag == 0)) is_finished<=6;
				else if ((is_finished==6 && inf.C_out_valid==1 && seller_id_flag==2) || (is_finished==6 && seller_id_flag==0 && user_change_flag == 0) || (is_finished==6  && seller_id_flag==0 && user_change_flag == 2)) is_finished<=7;
				else 				is_finished<=is_finished;
			end
			S_DEPOSIT : begin
				// Get User info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0) 	is_finished<=1;
				else if (user_change_flag==0 && is_finished==0)                      is_finished<=1;
				// Get money amnt
				else if (seller_id_flag == 1 && is_finished==1) is_finished<=2;
				else if (seller_id_flag == 2 && is_finished==2 && inf.C_out_valid==1)  is_finished<=3;
				else 											is_finished<=is_finished;
			end
			S_RETURN : begin
				// Get User info
				if(user_change_flag==2 && inf.C_out_valid==1 && is_finished==0) 		is_finished<=1;
				else if (user_change_flag==0 && is_finished==0)                       	is_finished<=1;
				// Get Seller info
				else if(seller_id_flag==2 && inf.C_out_valid==1 && is_finished==1) 		is_finished<=2;
				// Reflash info or Error msg
				else if (is_finished==2)												is_finished<=3;
				// Write back to DRAM
				else if (user_change_flag == 3 &&is_finished==3 && inf.C_out_valid==1)	is_finished<=4;
				else if (seller_id_flag==3 && is_finished==4 && inf.C_out_valid==1)		is_finished<=5;
				else 																	is_finished<=is_finished;
			end
			default : is_finished<=0;
		endcase
	end
end
// C_in_valid  & C_addr
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		inf.C_in_valid<=0;
		inf.C_addr <= 0;
		inf.C_r_wb <= 0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Read Buyer info				
				if(user_change_flag==1 && is_finished==0)begin 
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;
					inf.C_r_wb <= 1'b1;
				end
				// Read Seller info
				else if(seller_id_flag==1 && is_finished==1)begin 
					inf.C_in_valid<=1;
					inf.C_addr <=  cur_seller_id;
					inf.C_r_wb <= 1'b1;
				end
				// Write Buyer info
				else if (user_change_flag<=2 && is_finished==3 && cur_err==No_Err)begin
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;
					inf.C_r_wb <= 1'b0;
				end
				// Write Seller info
				else if (seller_id_flag==2 && is_finished==4 && cur_err==No_Err)begin
					inf.C_in_valid<=1;
					inf.C_addr <= cur_seller_id;
					inf.C_r_wb <= 1'b0;
				end
				else begin
					inf.C_in_valid<=0;
					inf.C_addr <= 0;
					inf.C_r_wb <= 0;
				end
			end
			S_CHECK :begin
				if(is_finished==5  && user_change_flag == 1) begin				
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;
					inf.C_r_wb <= 1'b1;
				end
				else if(is_finished==6 && seller_id_flag==1) begin				
					inf.C_in_valid<=1;
					inf.C_addr <= cur_seller_id;
					inf.C_r_wb <= 1'b1;
				end
				else begin
					inf.C_in_valid<=0;
					inf.C_addr <= 0;
					inf.C_r_wb <= 0;
				end
			end
			S_DEPOSIT :begin
				if (user_change_flag==1 && is_finished==0) begin
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;
					inf.C_r_wb <= 1'b1;
				end
				else if (seller_id_flag==1 && is_finished==2 && cur_err==No_Err) begin
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;	
					inf.C_r_wb <= 1'b0;	
				end
				else begin
					inf.C_in_valid<=0;
					inf.C_addr <= 0;
					inf.C_r_wb <= 1'b0;	
				end
			end
			S_RETURN : begin
				// Read Buyer info
				if(user_change_flag==1 && is_finished==0)begin 
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;
					inf.C_r_wb <= 1'b1;
				end
				// Read Seller info
				else if(seller_id_flag==1 && is_finished==1)begin 
					inf.C_in_valid<=1;
					inf.C_addr <= cur_seller_id;
					inf.C_r_wb <= 1'b1;
				end
				// Write Buyer info
				else if (user_change_flag<=2 && is_finished==3 && cur_err==No_Err)begin
					inf.C_in_valid<=1;
					inf.C_addr <= cur_user_id;
					inf.C_r_wb <= 1'b0;
				end
				// Write Seller info
				else if (seller_id_flag==2 && is_finished==4 && cur_err==No_Err)begin
					inf.C_in_valid<=1;
					inf.C_addr <= cur_seller_id;
					inf.C_r_wb <= 1'b0;
				end
				else begin
					inf.C_in_valid<=0;
					inf.C_addr <= 0;
					inf.C_r_wb <= 1'b0;
				end
			end
			default : begin
				inf.C_in_valid<=0;
				inf.C_addr <= 0;
				inf.C_r_wb <= 1'b0;
			end
		endcase
	end
end
// C_in_valid  & C_addr
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		inf.C_data_w <=0;
	end
	else begin
		case(current_state)
			S_BUY : begin
				// Write Buyer info
				if (user_change_flag<=2 && is_finished==3 && cur_err==No_Err)begin
					inf.C_data_w <= {buyer_user_info[7:0], buyer_user_info[15:8], buyer_user_info[23:16], buyer_user_info[31:24],
									 buyer_shop_info[7:0], buyer_shop_info[15:8], buyer_shop_info[23:16], buyer_shop_info[31:24]};
				end
				// Write Seller info
				else if (seller_id_flag==2 && is_finished==4 && cur_err==No_Err)begin
					inf.C_data_w <= {seller_user_info[7:0], seller_user_info[15:8], seller_user_info[23:16], seller_user_info[31:24],
									 seller_shop_info[7:0], seller_shop_info[15:8], seller_shop_info[23:16], seller_shop_info[31:24]};
				end
				else begin
					inf.C_data_w <=0;
				end
			end
			S_DEPOSIT :begin
				if (seller_id_flag==1 && is_finished==2 && cur_err==No_Err) begin
					inf.C_data_w <= {buyer_user_info[7:0], buyer_user_info[15:8], buyer_user_info[23:16], buyer_user_info[31:24],
									 buyer_shop_info[7:0], buyer_shop_info[15:8], buyer_shop_info[23:16], buyer_shop_info[31:24]};
				end
				else begin
					inf.C_data_w<=0;	
				end
			end
			S_RETURN : begin
				// Write Buyer info
				if (user_change_flag<=2 && is_finished==3 && cur_err==No_Err)begin
					inf.C_data_w <= {buyer_user_info[7:0], buyer_user_info[15:8], buyer_user_info[23:16], buyer_user_info[31:24],
									 buyer_shop_info[7:0], buyer_shop_info[15:8], buyer_shop_info[23:16], buyer_shop_info[31:24]};
				end
				// Write Seller info
				else if (seller_id_flag==2 && is_finished==4 && cur_err==No_Err)begin
					inf.C_data_w <= {seller_user_info[7:0], seller_user_info[15:8], seller_user_info[23:16], seller_user_info[31:24],
									 seller_shop_info[7:0], seller_shop_info[15:8], seller_shop_info[23:16], seller_shop_info[31:24]};
				end
				else begin
					inf.C_data_w<=0;
				end
			end
			default : begin
				inf.C_data_w<=0;
			end
		endcase
	end
end


//-------------------OUTPUT---------------------------//
// out valid
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		inf.out_valid <= 0;
	end
	else begin
		case(current_state)
			S_OUT : inf.out_valid <= 1;
			default : inf.out_valid <= 0;
		endcase
	end
end

// out info
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		inf.out_info <= 0;
	end
	else begin
		case(current_state)
			S_OUT : begin
				case(cur_action)
					Buy : begin
						if (cur_err==No_Err) 	inf.out_info <= buyer_user_info;
						else                 	inf.out_info <= 32'd0;
					end
					Check : begin
						if (seller_id_flag==0) 	inf.out_info <= {16'd0, buyer_user_info.money};
						else 					inf.out_info <= {14'd0, seller_shop_info.large_num, seller_shop_info.medium_num, seller_shop_info.small_num};
					end
					Deposit : begin
						if (cur_err==No_Err)  inf.out_info <= {16'd0, buyer_user_info.money};
						else                    inf.out_info <= 32'd0; 
					end
					Return : begin
						if (cur_err==No_Err) 	inf.out_info <= {14'd0, buyer_shop_info.large_num, buyer_shop_info.medium_num, buyer_shop_info.small_num};
						else                 	inf.out_info <= 32'd0; 
					end
					default : inf.out_info <= 0;
				endcase
			end
			default : inf.out_info <= 0;
		endcase
	end
end
// error msg
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		inf.err_msg <= No_Err;
	end
	else begin
		case(current_state)
			S_OUT : begin
				case(cur_action)
					Buy : begin
						if (cur_err==No_Err) 	inf.err_msg <= No_Err;
						else                 	inf.err_msg <= cur_err;
					end
					Check : begin
						inf.err_msg <= No_Err;
					end
					Deposit : begin
						if (cur_err==No_Err)  inf.err_msg <= No_Err;
						else                    inf.err_msg <= cur_err; 
					end
					Return : begin
						if (cur_err==No_Err) 	inf.err_msg <= No_Err;
						else                 	inf.err_msg <= cur_err; 
					end
					default : inf.err_msg <= No_Err;
				endcase
			end
			default : inf.err_msg <= No_Err;
		endcase
	end
end
// complete
always_ff@(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n) begin
		inf.complete <= 1'd0;
	end
	else begin
		case(current_state)
			S_OUT : begin
				case(cur_action)
					Buy : begin
						if (cur_err==No_Err) 	inf.complete <= 1'd1;
						else                 	inf.complete <= 1'd0;
					end
					Check : begin
						inf.complete <= 1'd1;
					end
					Deposit : begin
						if (cur_err==No_Err)  inf.complete <= 1'd1;
						else                    inf.complete <= 1'd0; 
					end
					Return : begin
						if (cur_err==No_Err) 	inf.complete <= 1'd1;
						else                 	inf.complete <= 1'd0; 
					end
					default : inf.complete <= 1'd0;
				endcase
			end
			default : inf.complete <= 1'd0;
		endcase
	end
end
endmodule