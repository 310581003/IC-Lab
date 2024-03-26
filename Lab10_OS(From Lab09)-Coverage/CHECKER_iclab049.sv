//############################################################################
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//   (C) Copyright Laboratory System Integration and Silicon Implementation
//   All Right Reserved
//
//   File Name   : CHECKER.sv
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//############################################################################
//`include "Usertype_PKG.sv"

module Checker(input clk, INF.CHECKER inf);
import usertype::*;

//================================================================//
//                      Cover Group                               //
//================================================================//
//covergroup Spec1 @();
//	
//       finish your covergroup here
//	
//	
//endgroup

//declare other cover group

//declare the cover group 
//Spec1 cov_inst_1 = new();

//------------- Spec 1 ----------------//
covergroup Spec1 @(posedge clk iff (inf.amnt_valid));
	coverpoint inf.D.d_money{
		option.at_least = 10;
		bins range_1 = {[0:12000]};
		bins range_2 = {[12001:24000]};
		bins range_3 = {[24001:36000]};
		bins range_4 = {[36001:48000]};
		bins range_5 = {[48001:60000]};
	}
endgroup
Spec1 cov_inst_1 = new();

//------------- Spec 2 ----------------//
covergroup Spec2 @(posedge clk iff (inf.id_valid));
	coverpoint inf.D.d_id[0]{
		option.auto_bin_max = 256;
		option.at_least = 2;
		bins id [] = {[0:255]};
	}
endgroup
Spec2 cov_inst_2 = new();

//------------- Spec 3 ----------------//
covergroup Spec3 @(posedge clk iff (inf.act_valid));
	coverpoint inf.D.d_act[0]{
		option.at_least = 10;
		// Start from "Buy"
		bins buy_to_buy = (Buy=>Buy);
		bins buy_to_check = (Buy=>Check);
		bins buy_to_deposit = (Buy=>Deposit);
		bins buy_to_return = (Buy=>Return);	
		
		// Start from "Check"
		bins check_to_check = (Check=>Check);
		bins check_to_deposit = (Check=>Deposit);
		bins check_to_return = (Check=>Return);
		bins check_to_buy = (Check=>Buy);
		
		// Start from "Deposit"
		bins deposit_to_deposit = (Deposit=>Deposit);
		bins deposit_to_return = (Deposit=>Return);
		bins deposit_to_buy = (Deposit=>Buy);
		bins deposit_to_check = (Deposit=>Check);
		
		// Start from "Return"
		bins return_to_return = (Return=>Return);
		bins retur_to_buy = (Return=>Buy);
		bins retur_to_check = (Return=>Check);
		bins returt_to_deposit = (Return=>Deposit);
	}
endgroup
Spec3 cov_inst_3 = new();	

//------------- Spec 4 ----------------//
covergroup Spec4 @(posedge clk iff (inf.item_valid));
	coverpoint inf.D.d_item[0]{
		option.at_least = 20;
		bins item_type_1 = {Large};
		bins item_type_2 = {Medium};
		bins item_type_3 = {Small};
	}
endgroup
Spec4 cov_inst_4 = new();

//------------- Spec 5 ----------------//
covergroup Spec5 @(negedge clk iff (inf.out_valid));
	coverpoint inf.err_msg{
		option.at_least = 20;
		bins err_type_1 = {INV_Not_Enough};
		bins err_type_2 = {Out_of_money};
		bins err_type_3 = {INV_Full};
		bins err_type_4 = {Wallet_is_Full};
		bins err_type_5 = {Wrong_ID};
		bins err_type_6 = {Wrong_Num};
		bins err_type_7 = {Wrong_Item};
		bins err_type_8 = {Wrong_act};
	}
endgroup
Spec5 cov_inst_5 = new();

//------------- Spec 6 ----------------//
covergroup Spec6 @(negedge clk iff (inf.out_valid));
	coverpoint inf.complete{
		option.at_least = 200;
		bins comp [] = {[0:1]};
	}
endgroup
Spec6 cov_inst_6 = new();
//************************************ below assertion is to check your pattern ***************************************** 
//                                          Please finish and hand in it
// This is an example assertion given by TA, please write other assertions at the below
// assert_interval : assert property ( @(posedge clk)  inf.out_valid |=> inf.id_valid == 0)
// else
// begin
// 	$display("Assertion X is violated");
// 	$fatal; 
// end

//write other assertions
//------------- Assertion 1 ----------------//
assert_interval_1 : assert property ( @(posedge inf.rst_n) !inf.rst_n |->((inf.err_msg==0)&&(inf.complete==0)&&(inf.out_valid==0)&&(inf.out_info==0)&&
																		  (inf.C_addr==0)&&(inf.C_data_w==0)&&(inf.C_in_valid==0)&&(inf.C_r_wb==0) &&
																		  (inf.C_out_valid==0)&&(inf.C_data_r==0)&&(inf.AR_VALID==0)&&(inf.AR_ADDR==0)&&
																		  (inf.R_READY==0)&&(inf.AW_VALID==0)&&(inf.AW_ADDR==0)&&(inf.W_VALID==0)&&
																		  (inf.W_DATA==0)&&(inf.B_READY==0)))
else
begin
	$display("Assertion 1 is violated");
	$fatal; 
end

//------------- Assertion 2 ----------------//
assert_interval_2 : assert property ( @(negedge clk) inf.out_valid |-> inf.complete |-> (inf.err_msg == 4'd0) )
else
begin
	$display("Assertion 2 is violated");
	$fatal; 
end

//------------- Assertion 3 ----------------//
assert_interval_3 : assert property ( @(negedge clk) inf.out_valid |-> (!inf.complete) |-> (inf.out_info == 32'd0) )
else
begin
	$display("Assertion 3 is violated");
	$fatal; 
end

//------------- Assertion 4  ----------------//
// id_valid
assert_interval_4_1 : assert property ( @(posedge clk) (inf.id_valid) |-> ##1 (!inf.id_valid) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// act_valid
assert_interval_4_2 : assert property ( @(posedge clk) (inf.act_valid) |-> ##1 (!inf.act_valid) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// item_valid
assert_interval_4_3 : assert property ( @(posedge clk) (inf.item_valid) |-> ##1 (!inf.item_valid) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// amnt_valid
assert_interval_4_4 : assert property ( @(posedge clk) (inf.amnt_valid) |-> ##1 (!inf.amnt_valid) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end

// num_valid
assert_interval_4_5 : assert property ( @(posedge clk) (inf.num_valid) |-> ##1 (!inf.num_valid) )
else
begin
	$display("Assertion 4 is violated");
	$fatal; 
end



//------------- Assertion 5  ----------------//
assert_interval_5 : assert property ( @(posedge clk) 
((inf.id_valid |-> inf.act_valid==0) and (inf.id_valid |-> inf.item_valid==0) and (inf.id_valid |-> inf.num_valid==0) and (inf.id_valid |-> inf.amnt_valid==0) and
 (inf.act_valid |-> inf.id_valid==0) and (inf.act_valid |-> inf.item_valid==0) and (inf.act_valid |-> inf.num_valid==0) and (inf.act_valid |-> inf.amnt_valid==0)and
 (inf.item_valid |-> inf.id_valid==0)and(inf.item_valid |-> inf.act_valid==0)and (inf.item_valid |-> inf.num_valid==0)and(inf.item_valid |-> inf.amnt_valid==0)and
 (inf.num_valid |-> inf.id_valid==0)and(inf.num_valid |-> inf.act_valid==0)and (inf.num_valid |-> inf.item_valid==0)and(inf.num_valid |-> inf.amnt_valid==0)and
 (inf.amnt_valid |-> inf.id_valid==0)and(inf.amnt_valid |-> inf.act_valid==0)and (inf.amnt_valid |-> inf.item_valid==0)and(inf.amnt_valid |-> inf.num_valid==0))
 )
else
begin
 	$display("Assertion 5 is violated");
 	$fatal; 
end

//------------- Assertion 6  ----------------//
Action cur_action;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		cur_action <= 0;
	end
	else if(inf.act_valid)begin
		cur_action <= inf.D.d_act[0];
	end
	else if(inf.out_valid)begin
		cur_action <= 0;
	end
	else begin
		cur_action <= cur_action;
	end
	
end
//---Make sure whether "act_valid" had rise---//
logic is_actvalid_pos_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		is_actvalid_pos_flag <= 0;
	end
	else if(inf.act_valid)begin
		is_actvalid_pos_flag <= 1;
	end
	else if(inf.out_valid)begin
		is_actvalid_pos_flag <= 0;
	end
	else begin
		is_actvalid_pos_flag <= is_actvalid_pos_flag;
	end
	
end


//---All cases : user id_valid---//
logic user_id_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		user_id_flag <= 0;
	end
	else if(is_actvalid_pos_flag==0 &&  inf.id_valid==1)begin
		user_id_flag <= 1;
	end
	else if(inf.act_valid==1)begin
		user_id_flag <= 0;
	end
	else if(inf.out_valid)begin
		user_id_flag <= 0;
	end
	else begin
		user_id_flag <= user_id_flag;
	end	
end



//---Check : seller id_valid---//
logic seller_id_flag;
integer counter;
always_ff @(negedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		counter <= 0;
	end
	else if(inf.act_valid && inf.D.d_act[0]==Check)begin
		counter <= counter + 1;
	end
	else if(inf.out_valid==1)begin
		counter <= 0;
	end
	else if (counter >=1)begin
		counter <= counter +1;
	end
	else begin
		counter <= counter ;
	end
	
end
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		seller_id_flag <= 0;
	end
	else if(counter<=6 && inf.id_valid==1 && is_actvalid_pos_flag==1)begin
		seller_id_flag <= 1;
	end
	else if(inf.out_valid)begin
		seller_id_flag <= 0;
	end
	else begin
		seller_id_flag <= seller_id_flag;
	end	
end

//---Buy or Return---//
//act_valid
logic BR_act_valid_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		BR_act_valid_flag <= 0;
	end
	else if(is_actvalid_pos_flag==0 &&  inf.act_valid==1 && (inf.D.d_act[0]==Buy || inf.D.d_act[0]==Return))begin
		BR_act_valid_flag <= 1;
	end
	else if(BR_act_valid_flag==1 && inf.item_valid==1)begin
		BR_act_valid_flag <= 0;
	end
	else if(inf.out_valid)begin
		BR_act_valid_flag <= 0;
	end
	else begin
		BR_act_valid_flag <= BR_act_valid_flag;
	end	
end
//item_valid
logic item_valid_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		item_valid_flag <= 0;
	end
	else if(is_actvalid_pos_flag==1 &&  inf.item_valid==1)begin
		item_valid_flag <= 1;
	end
	else if(is_actvalid_pos_flag==1 && item_valid_flag==1 && inf.num_valid==1)begin
		item_valid_flag <= 0;
	end
	else if(inf.out_valid)begin
		item_valid_flag <= 0;
	end
	else begin
		item_valid_flag <= item_valid_flag;
	end	
end
//num_valid
logic num_valid_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		num_valid_flag <= 0;
	end
	else if(item_valid_flag==1 &&  inf.num_valid==1)begin
		num_valid_flag <= 1;
	end
	else if(is_actvalid_pos_flag==1 && num_valid_flag==1 && inf.id_valid==1)begin
		num_valid_flag <= 0;
	end
	else if(inf.out_valid)begin
		num_valid_flag <= 0;
	end
	else begin
		num_valid_flag <= num_valid_flag;
	end	
end
//---Check---//
logic C_act_valid_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		C_act_valid_flag <= 0;
	end
	else if(is_actvalid_pos_flag==0 &&  inf.act_valid==1 && inf.D.d_act[0]==Check)begin
		C_act_valid_flag <= 1;
	end
	else if(C_act_valid_flag==1 && inf.id_valid==1)begin
		C_act_valid_flag <= 0;
	end
	else if(inf.out_valid)begin
		C_act_valid_flag <= 0;
	end
	else begin
		C_act_valid_flag <= C_act_valid_flag;
	end	
end
//---Deposit---//
logic D_act_valid_flag;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		D_act_valid_flag <= 0;
	end
	else if(is_actvalid_pos_flag==0 &&  inf.act_valid==1 && inf.D.d_act[0]==Deposit)begin
		D_act_valid_flag <= 1;
	end
	else if(D_act_valid_flag==1 && inf.amnt_valid==1)begin
		D_act_valid_flag <= 0;
	end
	else if(inf.out_valid)begin
		D_act_valid_flag <= 0;
	end
	else begin
		D_act_valid_flag <= D_act_valid_flag;
	end	
end
//is_finished
logic is_finished;
always_ff @(posedge clk or negedge inf.rst_n)begin
	if(!inf.rst_n)begin
		is_finished <= 0;
	end
	else if(is_actvalid_pos_flag==1 && (cur_action==Buy || cur_action==Return) && inf.id_valid==1)begin
		is_finished <= 1;
	end
	else if(is_actvalid_pos_flag==1 && cur_action==Check && ((counter==6 && seller_id_flag==0) || inf.id_valid==1))begin
		is_finished <= 1;
	end
	else if(is_actvalid_pos_flag==1 && cur_action==Deposit && inf.amnt_valid==1)begin
		is_finished <= 1;
	end
	else if(inf.out_valid)begin
		is_finished <= 0;
	end
	else begin
		is_finished <= is_finished;
	end	
end


// All cases : id_valid -> act_valid
assert_interval_6_1_1 : assert property	( @(posedge clk)( user_id_flag |=> !inf.id_valid && !inf.item_valid && !inf.num_valid && !inf.amnt_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_1_2 : assert property	( @(negedge clk) ( (inf.id_valid && !is_actvalid_pos_flag) |=> ##[1:5] inf.act_valid ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_1_3 : assert property	( @(negedge clk) ( (inf.id_valid && !is_actvalid_pos_flag) |=>  !inf.act_valid ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

// Buy or Return : act_valid -> item_valid
assert_interval_6_2_1 : assert property	( @(posedge clk)( BR_act_valid_flag |=> !inf.id_valid && !inf.act_valid && !inf.num_valid && !inf.amnt_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_2_2 : assert property	( @(negedge clk)((inf.act_valid && (inf.D.d_act[0]==Buy || inf.D.d_act[0]==Return))|=> ##[1:5] inf.item_valid ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_2_3 : assert property	( @(negedge clk) ( (inf.act_valid ) |=>  (!inf.item_valid && !inf.num_valid && !inf.amnt_valid && !inf.id_valid)))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	


// Buy or Return: item_valid -> num_valid
assert_interval_6_3_1 : assert property	( @(posedge clk)( item_valid_flag|=> !inf.id_valid && !inf.act_valid && !inf.item_valid && !inf.amnt_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_3_2 : assert property	( @(negedge clk)((inf.item_valid)|=> ##[1:5] inf.num_valid ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

// Buy or Return: num_valid -> id_valid
assert_interval_6_4_1 : assert property	( @(posedge clk)( num_valid_flag |=> !inf.num_valid && !inf.act_valid && !inf.item_valid && !inf.amnt_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

assert_interval_6_4_2 : assert property	( @(negedge clk)((inf.num_valid)|=> ##[1:5] inf.id_valid ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

// Check : act_valid -> id_valid ??????????
assert_interval_6_5_1 : assert property	( @(posedge clk)( C_act_valid_flag |-> !inf.num_valid && !inf.act_valid && !inf.item_valid && !inf.amnt_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

assert_interval_6_5_2 : assert property	( @(negedge clk)((inf.act_valid && (inf.D.d_act[0]==Check))|=> !inf.id_valid ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_5_3 : assert property (@(posedge clk)((counter>=6) |=> !inf.id_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

// Deposit : act_valid -> amnt_valid
assert_interval_6_6_1 : assert property	( @(posedge clk)( D_act_valid_flag |=> !inf.num_valid && !inf.act_valid && !inf.item_valid && !inf.id_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

assert_interval_6_6_2 : assert property	( @(negedge clk)((inf.act_valid && (inf.D.d_act[0]==Deposit))|=> ##[1:5] (inf.amnt_valid) ))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end	

assert_interval_6_6_3 : assert property	( @(posedge clk)( (inf.item_valid||inf.num_valid||inf.amnt_valid) |-> is_actvalid_pos_flag))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end

// All cases : finish
assert_interval_6_7 : assert property	( @(posedge clk)( is_finished |-> !inf.id_valid &&!inf.num_valid && !inf.act_valid && !inf.item_valid && !inf.amnt_valid))
else
begin
	$display("Assertion 6 is violated");
	$fatal; 
end


//------------- Assertion 7  ----------------//
assert_interval_7 : assert property ( @(negedge clk) (inf.out_valid) |-> ##1 (!inf.out_valid) )
else
begin
	$display("Assertion 7 is violated");
	$fatal; 
end

//------------- Assertion 8  ----------------//
assert_interval_8 : assert property ( @(posedge clk) (inf.out_valid) |-> ((!inf.id_valid && !inf.act_valid)##1(!inf.id_valid&& !inf.act_valid)##[1:9] inf.id_valid || inf.act_valid))
else
begin
	$display("Assertion 8 is violated");
	$fatal; 
end

//------------- Assertion 9  ----------------//
// All cases : if user_id changes
// assert_interval_9_1 : assert property	( @(negedge clk) ( (inf.id_valid && !is_actvalid_pos_flag) |=> ##[1:10000] inf.out_valid ))
// else
// begin
	// $display("Assertion 9 is violated");
	// $fatal; 
// end	

// All cases : if user_id don't change
// assert_interval_9_2 : assert property	( @(negedge clk) ( (inf.act_valid && !user_change_flag) |=> ##[1:10000] inf.out_valid ))
// else
// begin
	// $display("Assertion 9 is violated");
	// $fatal; 
// end

// Buy/Check/Return : seller id rises
assert_interval_9_1 : assert property	( @(negedge clk) ( (inf.id_valid && is_actvalid_pos_flag ) |-> ##[1:9999] inf.out_valid ))
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

// Check : seller id don't rise
assert_interval_9_2 : assert property	( @(negedge clk) ( (counter==6 && seller_id_flag==0) |-> ##[1:9994] inf.out_valid ))
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

// Deposit 
assert_interval_9_3 : assert property	( @(negedge clk) ( inf.amnt_valid |-> ##[1:9999] inf.out_valid ))
else
begin
	$display("Assertion 9 is violated");
	$fatal; 
end

endmodule