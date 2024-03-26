
`include "../00_TESTBED/pseudo_DRAM.sv"
`include "Usertype_OS.sv"

program automatic PATTERN(input clk, INF.PATTERN inf);
import usertype::*;

//================================================================//
//                     Declaration                                //
//================================================================//
// DRAM
parameter init_DRAM = "../00_TESTBED/DRAM/dram.dat";
logic [7:0] golden_DRAM[((65536+256*8)-1) : (65536+0)];
initial $readmemh(init_DRAM,golden_DRAM);

//global
integer latency;
integer total_cycle;
integer total_latency;
integer i_pat;
integer SEED=2023;
integer SEED1=20;
integer SEED2=104;
integer patnum = 790; //790
integer random_number;
integer max_latency;
integer answer_count;
integer a,b,c,d,e,f,g;

reg[9*8:1]  reset_color       = "\033[1;0m";
reg[10*8:1] txt_black_prefix  = "\033[1;30m";
reg[10*8:1] txt_red_prefix    = "\033[1;31m";
reg[10*8:1] txt_green_prefix  = "\033[1;32m";
reg[10*8:1] txt_yellow_prefix = "\033[1;33m";
reg[10*8:1] txt_blue_prefix   = "\033[1;34m";

reg[10*8:1] bkg_black_prefix  = "\033[40;1m";
reg[10*8:1] bkg_red_prefix    = "\033[41;1m";
reg[10*8:1] bkg_green_prefix  = "\033[42;1m";
reg[10*8:1] bkg_yellow_prefix = "\033[43;1m";
reg[10*8:1] bkg_blue_prefix   = "\033[44;1m";
reg[10*8:1] bkg_white_prefix  = "\033[47;1m";

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
//-----------------Err-------------------------//
typedef enum logic [3:0] { 
	No_Err					= 4'b0000, //	No err
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
logic [63:0] buyer_info,seller_info;
logic golden_comp;
logic [31:0] golden_out;
logic [8:0] last_record [255:0];
logic history [255:0];
//================================================================//
//                    Randomization                               //
//================================================================//
//------ Random action --------//
class random_act_0;
    randc Action rand_act_0;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        rand_act_0 inside{
						Buy,
						Check, 
						Return	  };
    }
endclass

class random_act;
    randc Action rand_act;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        rand_act inside{
						Buy,
						Check,
						Deposit, 
						Return	  };
    }
endclass
//------ Random ID --------//
class random_user_id;
	
	rand User_id rand_user_id;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{ 
		rand_user_id inside{[0:255]}; 
	}

endclass

class random_seller_id;
	
	rand User_id rand_seller_id;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{ 
		rand_seller_id inside{[0:255]}; 
	}

endclass

class wrongID_seller_id;
	
	rand User_id seller_id4wrong_id;
	function new(int seed);
		this.srandom(seed);
	endfunction
	constraint limit{ 
		seller_id4wrong_id inside{[2:255]}; 
	}

endclass
//------ Random item ID --------//
class random_item_id;
    randc Item_id rand_item_id;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        rand_item_id inside{
						Large,
						Medium,
						Small	  };
    }
endclass

class wrongitem_item_id;
    randc Item_id item_id4wrong_item;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        item_id4wrong_item inside{
						Large,
						Medium};
    }
endclass
//------ Random item num --------//
class random_item_num;
    randc Item_num rand_item_num;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        rand_item_num inside{[1:63]};
    }
endclass

class wrongnum_item_num;
    randc Item_num item_num4wrong_num;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        item_num4wrong_num inside{[2:63]};
    }
endclass
//------ Random money amount --------//
class random_money;
    randc Money rand_money;
	function new(int seed);
		this.srandom(seed);
	endfunction
    constraint limit{
        rand_money inside{[0:65535]};
    }
endclass

random_act       act_rnd = new(SEED);
random_act_0       act_rnd_0 = new(SEED1);
random_user_id   user_id_rnd = new(SEED);
random_seller_id seller_id_rnd = new(SEED1);
random_item_id   item_id_rnd = new(SEED);
random_item_num  item_num_rnd = new(SEED);
random_money     money_rnd = new(SEED);
wrongID_seller_id seller_id4wrong_id_rand = new(SEED2);
wrongnum_item_num item_num4wrong_num_rand = new(SEED);
wrongitem_item_id item_id4wrong_item_rand = new(SEED);
//================================================================//
//                        Initial                                //
//================================================================//
initial begin

	max_latency = 0;
	reset_task;
	total_cycle = 0;
    total_latency = 0;
	
  	for (i_pat = 0; i_pat < patnum; i_pat = i_pat + 1)begin
		if (i_pat<=62) begin
			corner_case_task;
		end
		else begin
			input_task;
		end
        wait_out_valid_task;       
	    if (inf.out_valid === 1) begin					
			check_ans_task;	
	    end
	    @(negedge clk);
	end
	$finish;

end

//================================================================//
//                      Reset Task                               //
//================================================================//
integer i, j;
task reset_task; begin 
    inf.rst_n = 'b1;
	inf.id_valid = 0;
	inf.act_valid = 0;
	inf.item_valid = 0;
	inf.num_valid = 0;
	inf.amnt_valid = 0;	
	inf.D = 'dx;
	for(i=0;i<256;i=i+1)begin
			history[i] = 0;
	end
	for(i=0;i<256;i=i+1)begin
		last_record[i]=0;
	end
    #(1);  inf.rst_n = 0;
	#(7); inf.rst_n =1; release clk;
    

end endtask

//================================================================//
//                   Corner  case Task                             //
//================================================================//
integer check_seller_flag;
integer t;
task corner_case_task; begin
	if (i_pat==0) t = $urandom_range(1, 5);
    else          t = $urandom_range(1, 9);
	
    for(i = 0; i < t; i = i + 1)begin   	
		@(negedge clk);
	end
	check_seller_flag=0;
	if (i_pat == 0) begin
		// Do Buy suceed (buyer_id : 0, seller_id : 1, item_id : small, item_num : 1)
		cur_action = Buy;
		//id_valid
		inf.id_valid = 1;
		cur_user_id = 0;
		inf.D = {8'd0, cur_user_id} ;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		//act_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.act_valid = 1;
		inf.D = {12'd0, cur_action};
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;
		//item_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.item_valid = 1;
		cur_item_id = Small;
		inf.D  = {14'd0, cur_item_id};
		@(negedge clk);
		inf.item_valid = 0;
		inf.D = 'dx;
		// num_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.num_valid = 1;
		cur_item_num = 1;
		inf.D = {10'd0, cur_item_num};
		@(negedge clk);
		inf.num_valid = 0;
		inf.D = 'dx;
		// seller id_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		cur_seller_id = 1;
		inf.id_valid = 1;
		inf.D = {8'd0, cur_seller_id};
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		
		Do_buy_task;
	end
	
	//Wrong ID//
	else if(i_pat >0 && i_pat<21) begin
		cur_action = Return;
		inf.id_valid = 0;
		cur_user_id = 0;
		//act_valid
		inf.act_valid = 1;
		inf.D = {12'd0, cur_action};
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;
		//item_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.item_valid = 1;
		cur_item_id = Small;
		inf.D  = {14'd0, cur_item_id};
		@(negedge clk);
		inf.item_valid = 0;
		inf.D = 'dx;
		//num_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.num_valid = 1;
		cur_item_num = 1;
		inf.D = {10'd0, cur_item_num};
		@(negedge clk);
		inf.num_valid = 0;
		inf.D = 'dx;
		//seller id_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		// g = seller_id4wrong_id_rand.randomize();
		// cur_seller_id = seller_id4wrong_id_rand.seller_id4wrong_id;
		cur_seller_id = i_pat+1;
		inf.id_valid = 1;
		inf.D = {8'd0, cur_seller_id};
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		
		Do_return_task;	
	end
	//Wrong number//
	else if(i_pat >20 && i_pat<41) begin
		cur_action = Return;
		inf.id_valid = 0;
		cur_user_id = 0;
		// act_valid
		inf.act_valid = 1;
		inf.D = {12'd0, cur_action};
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;
		// item_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.item_valid = 1;
		cur_item_id = Small;
		inf.D  = {14'd0, cur_item_id};
		@(negedge clk);
		inf.item_valid = 0;
		inf.D = 'dx;
		// num_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.num_valid = 1;
		g = item_num4wrong_num_rand.randomize();
		cur_item_num = item_num4wrong_num_rand.item_num4wrong_num;
		inf.D = {10'd0, cur_item_num};
		@(negedge clk);
		inf.num_valid = 0;
		inf.D = 'dx;
		// seller id_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		cur_seller_id = 1;
		inf.id_valid = 1;
		inf.D = {8'd0, cur_seller_id};
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		
		Do_return_task;
				
	end
	// wrong item id
	else if(i_pat >40 && i_pat<61) begin
		cur_action = Return;
		inf.id_valid = 0;
		cur_user_id = 0;
		// act_valid
		inf.act_valid = 1;
		inf.D = {12'd0, cur_action};
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;
		// item_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.item_valid = 1;
		g = item_id4wrong_item_rand.randomize();
		cur_item_id = item_id4wrong_item_rand.item_id4wrong_item;
		inf.D  = {14'd0, cur_item_id};
		@(negedge clk);
		inf.item_valid = 0;
		inf.D = 'dx;
		// num_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.num_valid = 1;
		cur_item_num = 1;
		inf.D = {10'd0, cur_item_num};
		@(negedge clk);
		inf.num_valid = 0;
		inf.D = 'dx;
		// seller id_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		cur_seller_id = 1;
		inf.id_valid = 1;
		inf.D = {8'd0, cur_seller_id};
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		
		Do_return_task;
				
	end
	else if (i_pat==61) begin
		cur_action = Check;
		inf.id_valid = 1;
		if(inf.id_valid==1) begin
			cur_user_id = 241;
			inf.D = {8'd0, cur_user_id} ;
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
		end
		else  cur_user_id =cur_user_id ;

		inf.act_valid = 1;
		inf.D = {12'd0, cur_action};
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;
		
	
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.id_valid = 1;
		if(inf.id_valid==1) begin
			//e = seller_id_rnd.randomize();
			//cur_seller_id = seller_id_rnd.rand_seller_id;
			cur_seller_id = 245;
			inf.D = {8'd0, cur_seller_id};
			check_seller_flag=1;
		end
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		
		// repeat(2) @(negedge clk);
		// inf.id_valid = 1;
		// inf.D = {8'd0, cur_seller_id};
		// @(negedge clk);
		// inf.id_valid = 0;
		
		Do_check_task;
	end
	else if (i_pat==62) begin
		cur_action = Return;
		//id_valid
		inf.id_valid = 1;
		cur_user_id = 0;
		inf.D = {8'd0, cur_user_id} ;
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		//act_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.act_valid = 1;
		inf.D = {12'd0, cur_action};
		@(negedge clk);
		inf.act_valid = 0;
		inf.D = 'dx;
		//item_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.item_valid = 1;
		cur_item_id = Small;
		inf.D  = {14'd0, cur_item_id};
		@(negedge clk);
		inf.item_valid = 0;
		inf.D = 'dx;
		// num_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		inf.num_valid = 1;
		cur_item_num = 1;
		inf.D = {10'd0, cur_item_num};
		@(negedge clk);
		inf.num_valid = 0;
		inf.D = 'dx;
		// seller id_valid
		t = $urandom_range(1, 5);
		repeat(t) @(negedge clk);
		cur_seller_id = 1;
		inf.id_valid = 1;
		inf.D = {8'd0, cur_seller_id};
		@(negedge clk);
		inf.id_valid = 0;
		inf.D = 'dx;
		
		Do_return_task;
	
	
	end

end endtask

//================================================================//
//                       Gen ID Task                            //
//================================================================//
integer u_id,s_id;
task gen_id_task; begin
		if (i_pat>=63 && i_pat<=279) begin
			u_id = i_pat-63;
			s_id = i_pat-40;
		end
		else if (i_pat>=279 && i_pat<=318)begin
			u_id = i_pat-63;
			e = seller_id_rnd.randomize();
			s_id = seller_id_rnd.rand_seller_id;
		end
		// else begin
			// a = user_id_rnd.randomize();
			// e = seller_id_rnd.randomize();
			// u_id = user_id_rnd.rand_user_id;
			// s_id = seller_id_rnd.rand_seller_id;
		// end
end endtask
//================================================================//
//                      Input Task                               //
//================================================================//


task input_task; begin
	check_seller_flag=0;
	// Gap
    t = $urandom_range(1, 9);
	
    for(i = 0; i < t; i = i + 1)begin   	
		@(negedge clk);
	end
	if (i_pat>=62 && i_pat<=278)begin
		b = act_rnd_0.randomize() ;
		cur_action = act_rnd_0.rand_act_0;
	end
	else begin
		b = act_rnd.randomize() ;
		cur_action = act_rnd.rand_act;
	end
	case (cur_action)
		Buy : begin
			if (i_pat<=318) begin
				gen_id_task;
				inf.id_valid = 1;
				cur_user_id = u_id;
				cur_seller_id = s_id;
				inf.D = {8'd0, cur_user_id} ;
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
				t = $urandom_range(1, 5);
				repeat(t) @(negedge clk);
			end
			else begin
				inf.id_valid = $urandom_range(0, 1);
				if(inf.id_valid==1) begin
					a = user_id_rnd.randomize();
					cur_user_id = user_id_rnd.rand_user_id;
					
					inf.D = {8'd0, cur_user_id} ;
					@(negedge clk);
					inf.id_valid = 0;
					inf.D = 'dx;
					t = $urandom_range(1, 5);
				    repeat(t) @(negedge clk);
				end
				else  cur_user_id =cur_user_id ;
				e = seller_id_rnd.randomize();
				cur_seller_id = seller_id_rnd.rand_seller_id;
				while (cur_seller_id == cur_user_id)begin
					e = seller_id_rnd.randomize();
					cur_seller_id = seller_id_rnd.rand_seller_id;
				end
			end
			inf.act_valid = 1;
			inf.D = {12'd0, cur_action};
			@(negedge clk);
			inf.act_valid = 0;
			inf.D = 'dx;
			
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
			inf.item_valid = 1;
			c = item_id_rnd.randomize();
			cur_item_id = item_id_rnd.rand_item_id;
			inf.D  = {14'd0, cur_item_id};
			@(negedge clk);
			inf.item_valid = 0;
			inf.D = 'dx;
			
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
			inf.num_valid = 1;
			d = item_num_rnd.randomize();
			cur_item_num = item_num_rnd.rand_item_num;
			inf.D = {10'd0, cur_item_num};
			@(negedge clk);
			inf.num_valid = 0;
			inf.D = 'dx;
			
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);	
			inf.id_valid = 1;
			inf.D = {8'd0, cur_seller_id};
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
			
			Do_buy_task;	
		end
		Check : begin
			if (i_pat<=318) begin
				inf.id_valid = 1;
				gen_id_task;
				cur_user_id = u_id;
				cur_seller_id =s_id;
				inf.D = {8'd0, cur_user_id} ;
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
				t = $urandom_range(1, 5);
				repeat(t) @(negedge clk);
			end
			else begin
				inf.id_valid = $urandom_range(0, 1);
				if(inf.id_valid==1) begin
					a = user_id_rnd.randomize();
					cur_user_id = user_id_rnd.rand_user_id;
					inf.D = {8'd0, cur_user_id} ;
					@(negedge clk);
					inf.id_valid = 0;
					inf.D = 'dx;
					t = $urandom_range(1, 5);
				    repeat(t) @(negedge clk);
				end
				else  cur_user_id =cur_user_id ;
			end
			inf.act_valid = 1;
			inf.D = {12'd0, cur_action};
			@(negedge clk);
			inf.act_valid = 0;
			inf.D = 'dx;
			
		
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
			if (i_pat<=317) begin
				inf.id_valid = 1;
				if(inf.id_valid==1) begin
					inf.D = {8'd0, cur_seller_id};
					check_seller_flag=1;
				end
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
			end
			else begin
				inf.id_valid = $urandom_range(0, 1);
				if(inf.id_valid==1) begin
					e = seller_id_rnd.randomize();
					cur_seller_id = seller_id_rnd.rand_seller_id;
					inf.D = {8'd0, cur_seller_id};
					check_seller_flag=1;
				end
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
			end
			
			Do_check_task;		
		end	
		
		Deposit : begin
			if (i_pat<=318) begin
				inf.id_valid = 1;
				gen_id_task;
				cur_user_id = u_id;
				inf.D = {8'd0, cur_user_id} ;
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
				t = $urandom_range(1, 5);
				repeat(t) @(negedge clk);
			end
			else begin
				inf.id_valid = $urandom_range(0, 1);
				if(inf.id_valid==1) begin
					a = user_id_rnd.randomize();
					cur_user_id = user_id_rnd.rand_user_id;
					inf.D = {8'd0, cur_user_id} ;
					@(negedge clk);
					inf.id_valid = 0;
					inf.D = 'dx;
					t = $urandom_range(1, 5);
				    repeat(t) @(negedge clk);
				end
				else  cur_user_id =cur_user_id ;
			end
			
			inf.act_valid = 1;
			inf.D = {12'd0, cur_action};
			@(negedge clk);
			inf.act_valid = 0;
			inf.D = 'dx;
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);			
			
			inf.amnt_valid = 1;
			f = money_rnd.randomize();
			cur_money_amnt = money_rnd.rand_money;
			inf.D = {12'd0, cur_money_amnt};
			@(negedge clk);	
			inf.amnt_valid = 0;
			inf.D = 'dx;
			
			Do_deposit_task;
		
		end
		Return : begin
			if (i_pat<=318) begin
				inf.id_valid = 1;
				gen_id_task;
				cur_user_id = u_id;
				cur_seller_id = s_id;
				inf.D = {8'd0, cur_user_id} ;
				@(negedge clk);
				inf.id_valid = 0;
				inf.D = 'dx;
				t = $urandom_range(1, 5);
				repeat(t) @(negedge clk);
			end
			else begin
				inf.id_valid = $urandom_range(0, 1);
				if(inf.id_valid==1) begin
					a = user_id_rnd.randomize();
					cur_user_id = user_id_rnd.rand_user_id;
					inf.D = {8'd0, cur_user_id} ;
					@(negedge clk);
					inf.id_valid = 0;
					inf.D = 'dx;
					t = $urandom_range(1, 5);
				    repeat(t) @(negedge clk);
				end
				else  cur_user_id =cur_user_id ;
				e = seller_id_rnd.randomize();
				cur_seller_id = seller_id_rnd.rand_seller_id;
				while (cur_seller_id == cur_user_id)begin
					e = seller_id_rnd.randomize();
					cur_seller_id = seller_id_rnd.rand_seller_id;
				end
			end
			inf.act_valid = 1;
			inf.D = {12'd0, cur_action};
			@(negedge clk);
			inf.act_valid = 0;
			inf.D = 'dx;
			
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
			inf.item_valid = 1;
			c = item_id_rnd.randomize();
			cur_item_id = item_id_rnd.rand_item_id;
			inf.D  = {14'd0, cur_item_id};
			@(negedge clk);
			inf.item_valid = 0;
			inf.D = 'dx;
			
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
			inf.num_valid = 1;
			d = item_num_rnd.randomize();
			cur_item_num = item_num_rnd.rand_item_num;
			inf.D = {10'd0, cur_item_num};
			@(negedge clk);
			inf.num_valid = 0;
			inf.D = 'dx;
			
			t = $urandom_range(1, 5);
			repeat(t) @(negedge clk);
			
			inf.id_valid = 1;
			inf.D = {8'd0, cur_seller_id};
			@(negedge clk);
			inf.id_valid = 0;
			inf.D = 'dx;
			
			Do_return_task;
			
		
		end
	endcase
	inf.id_valid = 0;
	inf.act_valid = 0;
	inf.item_valid = 0;
	inf.num_valid = 0;
	inf.amnt_valid = 0;	
	inf.D = 'dx;	
end endtask

//================================================================//
//                      Do Buy Task                               //
//================================================================//
task Do_buy_task; begin
	buyer_info = {golden_DRAM[65536+7+cur_user_id*8] , golden_DRAM[65536+6+cur_user_id*8] , golden_DRAM[65536+5+cur_user_id*8] , golden_DRAM[65536+4+cur_user_id*8] , 
					golden_DRAM[65536+3+cur_user_id*8], golden_DRAM[65536+2+cur_user_id*8], golden_DRAM[65536+1+cur_user_id*8], golden_DRAM[65536+0+cur_user_id*8]};
	buyer_shop_info.large_num = buyer_info[7:2];
	buyer_shop_info.medium_num = {buyer_info[1:0], buyer_info[15:12]};
	buyer_shop_info.small_num = {buyer_info[11:8], buyer_info[23:22]};
	buyer_shop_info.level = buyer_info[21:20];
	buyer_shop_info.exp = {buyer_info[19:16], buyer_info[31:28], buyer_info[27:24]};

	buyer_user_info.money = {buyer_info[39:36], buyer_info[35:32], buyer_info[47:44], buyer_info[43:40]};
	buyer_user_info.shop_history = {buyer_info[55:54], buyer_info[53:52], buyer_info[51:48], buyer_info[63:56]};

	seller_info = {golden_DRAM[65536+7+cur_seller_id*8] , golden_DRAM[65536+6+cur_seller_id*8] , golden_DRAM[65536+5+cur_seller_id*8] , golden_DRAM[65536+4+cur_seller_id*8] , 
				golden_DRAM[65536+3+cur_seller_id*8], golden_DRAM[65536+2+cur_seller_id*8], golden_DRAM[65536+1+cur_seller_id*8], golden_DRAM[65536+0+cur_seller_id*8]};
	seller_shop_info.large_num = seller_info[7:2];
	seller_shop_info.medium_num = {seller_info[1:0], seller_info[15:12]};
	seller_shop_info.small_num = {seller_info[11:8], seller_info[23:22]};
	seller_shop_info.level = seller_info[21:20];
	seller_shop_info.exp = {seller_info[19:16], seller_info[31:28], seller_info[27:24]};

	seller_user_info.money = {seller_info[39:36], seller_info[35:32], seller_info[47:44], seller_info[43:40]};
	seller_user_info.shop_history = {seller_info[55:54], seller_info[53:52], seller_info[51:48], seller_info[63:56]};
	case (cur_item_id)
		Large: begin
			case (buyer_shop_info.level)
					Platinum : begin
						//-----------Complete--------------//
						if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d10 && seller_shop_info.large_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d300;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num-cur_item_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// shop info
							buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
							buyer_shop_info.medium_num = buyer_shop_info.medium_num;
							buyer_shop_info.small_num = buyer_shop_info.small_num;
							buyer_shop_info.level = Platinum;
							buyer_shop_info.exp = 12'd0;
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d300+'d10);
							buyer_user_info.shop_history[15:14] = Large;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 	cur_err = INV_Full;
							else if (seller_shop_info.large_num<cur_item_num)						cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d300+'d10)					cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Gold : begin
						//-----------Complete--------------//
						if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d30 && seller_shop_info.large_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d300;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num-cur_item_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d300+'d30);
							buyer_user_info.shop_history[15:14] = Large;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d60>='d4000)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Platinum;
								buyer_shop_info.exp = 12'd0;
							end
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Gold;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d60;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
						//err
							if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 		cur_err = INV_Full;
							else if (seller_shop_info.large_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d300+'d30)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Silver : begin
						//-----------Complete--------------//
						if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d50 && seller_shop_info.large_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d300;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num-cur_item_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//						
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d300+'d50);
							buyer_user_info.shop_history[15:14] = Large;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d60>='d2500)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Gold;
								buyer_shop_info.exp = 12'd0;
							end										
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Silver;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d60;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 	cur_err = INV_Full;
							else if (seller_shop_info.large_num<cur_item_num)						cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d300+'d50)					cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Copper : begin
						//-----------Complete--------------//
						if (buyer_shop_info.large_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d300+'d70 && seller_shop_info.large_num>=cur_item_num) begin										
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d300>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d300;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num-cur_item_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d300+'d70);
							buyer_user_info.shop_history[15:14] = Large;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d60>='d1000)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Silver;
								buyer_shop_info.exp = 12'd0;
							end
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num+cur_item_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Copper;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d60;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.large_num+cur_item_num<buyer_shop_info.large_num) 		cur_err = INV_Full;
							else if (seller_shop_info.large_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d300+'d70)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
			endcase	
		end
		Medium: begin
			case (buyer_shop_info.level)
					Platinum : begin
						//-----------Complete--------------//
						if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d10 && seller_shop_info.medium_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d200;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num-cur_item_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d200+'d10);
							buyer_user_info.shop_history[15:14] = Medium;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							buyer_shop_info.large_num = buyer_shop_info.large_num;
							buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
							buyer_shop_info.small_num = buyer_shop_info.small_num;
							buyer_shop_info.level = Platinum;
							buyer_shop_info.exp = 12'd0;
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err = INV_Full;
							else if (seller_shop_info.medium_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d200+'d10)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Gold : begin
						//-----------Complete--------------//
						if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d30 && seller_shop_info.medium_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d200;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num-cur_item_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d200+'d30);
							buyer_user_info.shop_history[15:14] = Medium;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d40>='d4000)begin							
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Platinum;
								buyer_shop_info.exp = 12'd0;
							end
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Gold;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d40;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err = INV_Full;
							else if (seller_shop_info.medium_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d200+'d30)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Silver : begin
						//-----------Complete--------------//
						if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d50 && seller_shop_info.medium_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d200;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num-cur_item_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;	
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d200+'d50);
							buyer_user_info.shop_history[15:14] = Medium;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d40>='d2500)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Gold;
								buyer_shop_info.exp = 12'd0;
							end										
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Silver;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d40;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err = INV_Full;
							else if (seller_shop_info.medium_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d200+'d50)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Copper : begin
						//-----------Complete--------------//
						if (buyer_shop_info.medium_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d200+'d70 && seller_shop_info.medium_num>=cur_item_num) begin	
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d200>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d200;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num-cur_item_num;
							seller_shop_info.small_num = seller_shop_info.small_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d200+'d70);
							buyer_user_info.shop_history[15:14] = Medium;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d40>='d1000)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Silver;
								buyer_shop_info.exp = 12'd0;
							end
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num+cur_item_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num;
								buyer_shop_info.level = Copper;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d40;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.medium_num+cur_item_num<buyer_shop_info.medium_num) 	cur_err = INV_Full;
							else if (seller_shop_info.medium_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d200+'d70)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;	
							//complete
							golden_comp = 0;							
						end
					end
			endcase	
		end
		Small: begin
			case (buyer_shop_info.level)
					Platinum : begin
						//-----------Complete--------------//
						if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d10 && seller_shop_info.small_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d100;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num-cur_item_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d100+'d10);
							buyer_user_info.shop_history[15:14] = Small;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							buyer_shop_info.large_num = buyer_shop_info.large_num;
							buyer_shop_info.medium_num = buyer_shop_info.medium_num;
							buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
							buyer_shop_info.level = Platinum;
							buyer_shop_info.exp = 12'd0;
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 		cur_err = INV_Full;
							else if (seller_shop_info.small_num<cur_item_num)							cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d100+'d10)						cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Gold : begin
						//-----------Complete--------------//
						if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d30 && seller_shop_info.small_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d100;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num-cur_item_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d100+'d30);
							buyer_user_info.shop_history[15:14] = Small;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d20>='d4000)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
								buyer_shop_info.level = Platinum;
								buyer_shop_info.exp = 12'd0;
							end
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
								buyer_shop_info.level = Gold;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d20;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err = INV_Full;
							else if (seller_shop_info.small_num<cur_item_num)						cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d100+'d30)					cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Silver : begin
						//-----------Complete--------------//
						if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d50 && seller_shop_info.small_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d100;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num-cur_item_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d100+'d50);
							buyer_user_info.shop_history[15:14] = Small;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d20>='d2500)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
								buyer_shop_info.level = Gold;
								buyer_shop_info.exp = 12'd0;
							end										
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
								buyer_shop_info.level = Silver;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d20;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err = INV_Full;
							else if (seller_shop_info.small_num<cur_item_num)						cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d100+'d50)					cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;
							//complete
							golden_comp = 0;
						end
					end
					Copper : begin
						//-----------Complete--------------//
						if (buyer_shop_info.small_num+cur_item_num<=63 && buyer_user_info.money>=cur_item_num*'d100+'d70 && seller_shop_info.small_num>=cur_item_num) begin
							//------seller-----------//
							// user info
							if (seller_user_info.money+cur_item_num*'d100>='d65535) 	seller_user_info.money = 16'd65535;
							else  														seller_user_info.money = seller_user_info.money+cur_item_num*'d100;
							// shop info
							seller_shop_info.large_num = seller_shop_info.large_num;
							seller_shop_info.medium_num = seller_shop_info.medium_num;
							seller_shop_info.small_num = seller_shop_info.small_num-cur_item_num;
							seller_shop_info.level = seller_shop_info.level;
							seller_shop_info.exp = seller_shop_info.exp;
							//------buyer-----------//
							// user info
							buyer_user_info.money = buyer_user_info.money-(cur_item_num*'d100+'d70);
							buyer_user_info.shop_history[15:14] = Small;
							buyer_user_info.shop_history[13:8] = cur_item_num;
							buyer_user_info.shop_history[7:0] = cur_seller_id;
							// shop info
							if (buyer_shop_info.exp+cur_item_num*'d20>='d1000)begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
								buyer_shop_info.level = Silver;
								buyer_shop_info.exp = 12'd0;
							end
							else begin
								buyer_shop_info.large_num = buyer_shop_info.large_num;
								buyer_shop_info.medium_num = buyer_shop_info.medium_num;
								buyer_shop_info.small_num = buyer_shop_info.small_num+cur_item_num;
								buyer_shop_info.level = Copper;
								buyer_shop_info.exp = buyer_shop_info.exp+cur_item_num*'d20;
							end
							//err
							cur_err = No_Err;
							//out info
							golden_out = buyer_user_info;
							//complete
							golden_comp = 1;
						end
						
						//-------------err----------------//
						else begin
							//err
							if (buyer_shop_info.small_num+cur_item_num<buyer_shop_info.small_num) 	cur_err = INV_Full;
							else if (seller_shop_info.small_num<cur_item_num)						cur_err = INV_Not_Enough;
							else if (buyer_user_info.money<cur_item_num*'d100+'d70)					cur_err = Out_of_money;
							//out info
							golden_out = 32'd0;	
							//complete
							golden_comp = 0;
						end
					end
			endcase	
		end
	endcase 
	
	//record
	if (cur_err==No_Err) begin
		history[cur_seller_id] = 1 ;
		history[cur_user_id] = 1 ;
		last_record[cur_seller_id] = {1'd1,cur_user_id};
		last_record[cur_user_id] = {1'd0,cur_seller_id};
	end
		
	//Store back to golden DRAM
	buyer_info = {buyer_user_info[7:0], buyer_user_info[15:8], buyer_user_info[23:16], buyer_user_info[31:24],
					buyer_shop_info[7:0], buyer_shop_info[15:8], buyer_shop_info[23:16], buyer_shop_info[31:24]};
	
	
	golden_DRAM[65536+7+cur_user_id*8] = buyer_info[63:56];
	golden_DRAM[65536+6+cur_user_id*8] = buyer_info[55:48];
	golden_DRAM[65536+5+cur_user_id*8] = buyer_info[47:40];
	golden_DRAM[65536+4+cur_user_id*8] = buyer_info[39:32];
	golden_DRAM[65536+3+cur_user_id*8] = buyer_info[31:24];
	golden_DRAM[65536+2+cur_user_id*8] = buyer_info[23:16];
	golden_DRAM[65536+1+cur_user_id*8] = buyer_info[15:8];
	golden_DRAM[65536+0+cur_user_id*8] = buyer_info[7:0];

	seller_info = {seller_user_info[7:0], seller_user_info[15:8], seller_user_info[23:16], seller_user_info[31:24],
					seller_shop_info[7:0], seller_shop_info[15:8], seller_shop_info[23:16], seller_shop_info[31:24]};
	
	golden_DRAM[65536+7+cur_seller_id*8]  =seller_info[63:56];
	golden_DRAM[65536+6+cur_seller_id*8]=seller_info[55:48];
	golden_DRAM[65536+5+cur_seller_id*8]=seller_info[47:40];
	golden_DRAM[65536+4+cur_seller_id*8]=seller_info[39:32];
	golden_DRAM[65536+3+cur_seller_id*8]=seller_info[31:24];
	golden_DRAM[65536+2+cur_seller_id*8]=seller_info[23:16];
	golden_DRAM[65536+1+cur_seller_id*8]=seller_info[15:8];
	golden_DRAM[65536+0+cur_seller_id*8]=seller_info[7:0];
end endtask
//================================================================//
//                    Do Check Task                               //
//================================================================//
task Do_check_task; begin
	//err
	cur_err = No_Err;
	//complete
	golden_comp = 1;
	//out info
	if (check_seller_flag==0) begin
		buyer_info = {golden_DRAM[65536+7+cur_user_id*8] , golden_DRAM[65536+6+cur_user_id*8] , golden_DRAM[65536+5+cur_user_id*8] , golden_DRAM[65536+4+cur_user_id*8] , 
					golden_DRAM[65536+3+cur_user_id*8], golden_DRAM[65536+2+cur_user_id*8], golden_DRAM[65536+1+cur_user_id*8], golden_DRAM[65536+0+cur_user_id*8]};
		
		buyer_shop_info.large_num = buyer_info[7:2];
		buyer_shop_info.medium_num = {buyer_info[1:0], buyer_info[15:12]};
		buyer_shop_info.small_num = {buyer_info[11:8], buyer_info[23:22]};
		buyer_shop_info.level = buyer_info[21:20];
		buyer_shop_info.exp = {buyer_info[19:16], buyer_info[31:28], buyer_info[27:24]};
	
		buyer_user_info.money = {buyer_info[39:36], buyer_info[35:32], buyer_info[47:44], buyer_info[43:40]};
		buyer_user_info.shop_history = {buyer_info[55:54], buyer_info[53:52], buyer_info[51:48], buyer_info[63:56]};
	
		golden_out = {16'd0, buyer_user_info.money};
	end
	else begin
		//err
		cur_err = No_Err;
		//out info
		buyer_info = {golden_DRAM[65536+7+cur_user_id*8] , golden_DRAM[65536+6+cur_user_id*8] , golden_DRAM[65536+5+cur_user_id*8] , golden_DRAM[65536+4+cur_user_id*8] , 
					golden_DRAM[65536+3+cur_user_id*8], golden_DRAM[65536+2+cur_user_id*8], golden_DRAM[65536+1+cur_user_id*8], golden_DRAM[65536+0+cur_user_id*8]};
		buyer_shop_info.large_num = buyer_info[7:2];
		buyer_shop_info.medium_num = {buyer_info[1:0], buyer_info[15:12]};
		buyer_shop_info.small_num = {buyer_info[11:8], buyer_info[23:22]};
		buyer_shop_info.level = buyer_info[21:20];
		buyer_shop_info.exp = {buyer_info[19:16], buyer_info[31:28], buyer_info[27:24]};

		buyer_user_info.money = {buyer_info[39:36], buyer_info[35:32], buyer_info[47:44], buyer_info[43:40]};
		buyer_user_info.shop_history = {buyer_info[55:54], buyer_info[53:52], buyer_info[51:48], buyer_info[63:56]};

		seller_info = {golden_DRAM[65536+7+cur_seller_id*8] , golden_DRAM[65536+6+cur_seller_id*8] , golden_DRAM[65536+5+cur_seller_id*8] , golden_DRAM[65536+4+cur_seller_id*8] , 
					golden_DRAM[65536+3+cur_seller_id*8], golden_DRAM[65536+2+cur_seller_id*8], golden_DRAM[65536+1+cur_seller_id*8], golden_DRAM[65536+0+cur_seller_id*8]};
		seller_shop_info.large_num = seller_info[7:2];
		seller_shop_info.medium_num = {seller_info[1:0], seller_info[15:12]};
		seller_shop_info.small_num = {seller_info[11:8], seller_info[23:22]};
		seller_shop_info.level = seller_info[21:20];
		seller_shop_info.exp = {seller_info[19:16], seller_info[31:28], seller_info[27:24]};

		seller_user_info.money = {seller_info[39:36], seller_info[35:32], seller_info[47:44], seller_info[43:40]};
		seller_user_info.shop_history = {seller_info[55:54], seller_info[53:52], seller_info[51:48], seller_info[63:56]};
		
		golden_out = {14'd0, seller_shop_info.large_num, seller_shop_info.medium_num, seller_shop_info.small_num};
	end
	//record
	case (check_seller_flag)
		1'd0 : begin
			history[cur_user_id] = 0 ;
			last_record[cur_user_id] = last_record[cur_user_id];
		end
		1'd1 : begin
			history[cur_user_id] = 0 ;
			history[cur_seller_id] =0 ;
			last_record[cur_user_id] = last_record[cur_user_id];
		end
	endcase

end endtask

//================================================================//
//                   Do Deposit Task                               //
//================================================================//
task Do_deposit_task; begin
	buyer_info = {golden_DRAM[65536+7+cur_user_id*8] , golden_DRAM[65536+6+cur_user_id*8] , golden_DRAM[65536+5+cur_user_id*8] , golden_DRAM[65536+4+cur_user_id*8] , 
					golden_DRAM[65536+3+cur_user_id*8], golden_DRAM[65536+2+cur_user_id*8], golden_DRAM[65536+1+cur_user_id*8], golden_DRAM[65536+0+cur_user_id*8]};
	buyer_shop_info.large_num = buyer_info[7:2];
	buyer_shop_info.medium_num = {buyer_info[1:0], buyer_info[15:12]};
	buyer_shop_info.small_num = {buyer_info[11:8], buyer_info[23:22]};
	buyer_shop_info.level = buyer_info[21:20];
	buyer_shop_info.exp = {buyer_info[19:16], buyer_info[31:28], buyer_info[27:24]};

	buyer_user_info.money = {buyer_info[39:36], buyer_info[35:32], buyer_info[47:44], buyer_info[43:40]};
	buyer_user_info.shop_history = {buyer_info[55:54], buyer_info[53:52], buyer_info[51:48], buyer_info[63:56]};
	
	//------------err---------------//
	if (buyer_user_info.money+cur_money_amnt < buyer_user_info.money)begin 
		buyer_user_info.money = buyer_user_info.money;
		//err
		cur_err = Wallet_is_Full;
		//complete
		golden_comp = 0;
		//out info
		golden_out = 32'd0;
	end
	//-----------Complete---------------//
	else begin
		buyer_user_info.money = buyer_user_info.money+cur_money_amnt;
		//err
		cur_err = No_Err;
		//complete
		golden_comp = 1;
		//out info
		golden_out = {16'd0, buyer_user_info.money};
	end
	//record
	if (cur_err==No_Err) begin
		history[cur_user_id] = 0 ;
		last_record[cur_user_id] = last_record[cur_user_id];
	end
	
	// Store back to golden DRAM
	buyer_info = {buyer_user_info[7:0], buyer_user_info[15:8], buyer_user_info[23:16], buyer_user_info[31:24],
					buyer_shop_info[7:0], buyer_shop_info[15:8], buyer_shop_info[23:16], buyer_shop_info[31:24]};
	
	golden_DRAM[65536+7+cur_user_id*8] = buyer_info[63:56];
	golden_DRAM[65536+6+cur_user_id*8] = buyer_info[55:48];
	golden_DRAM[65536+5+cur_user_id*8] = buyer_info[47:40];
	golden_DRAM[65536+4+cur_user_id*8] = buyer_info[39:32];
	golden_DRAM[65536+3+cur_user_id*8] = buyer_info[31:24];
	golden_DRAM[65536+2+cur_user_id*8] = buyer_info[23:16];
	golden_DRAM[65536+1+cur_user_id*8] = buyer_info[15:8];
	golden_DRAM[65536+0+cur_user_id*8] = buyer_info[7:0];
	
end endtask

//================================================================//
//                    Do Return Task                              //
//================================================================//
task Do_return_task; begin
	buyer_info = {golden_DRAM[65536+7+cur_user_id*8] , golden_DRAM[65536+6+cur_user_id*8] , golden_DRAM[65536+5+cur_user_id*8] , golden_DRAM[65536+4+cur_user_id*8] , 
					golden_DRAM[65536+3+cur_user_id*8], golden_DRAM[65536+2+cur_user_id*8], golden_DRAM[65536+1+cur_user_id*8], golden_DRAM[65536+0+cur_user_id*8]};
	buyer_shop_info.large_num = buyer_info[7:2];
	buyer_shop_info.medium_num = {buyer_info[1:0], buyer_info[15:12]};
	buyer_shop_info.small_num = {buyer_info[11:8], buyer_info[23:22]};
	buyer_shop_info.level = buyer_info[21:20];
	buyer_shop_info.exp = {buyer_info[19:16], buyer_info[31:28], buyer_info[27:24]};

	buyer_user_info.money = {buyer_info[39:36], buyer_info[35:32], buyer_info[47:44], buyer_info[43:40]};
	buyer_user_info.shop_history = {buyer_info[55:54], buyer_info[53:52], buyer_info[51:48], buyer_info[63:56]};

	seller_info = {golden_DRAM[65536+7+cur_seller_id*8] , golden_DRAM[65536+6+cur_seller_id*8] , golden_DRAM[65536+5+cur_seller_id*8] , golden_DRAM[65536+4+cur_seller_id*8] , 
					golden_DRAM[65536+3+cur_seller_id*8], golden_DRAM[65536+2+cur_seller_id*8], golden_DRAM[65536+1+cur_seller_id*8], golden_DRAM[65536+0+cur_seller_id*8]};
	seller_shop_info.large_num = seller_info[7:2];
	seller_shop_info.medium_num = {seller_info[1:0], seller_info[15:12]};
	seller_shop_info.small_num = {seller_info[11:8], seller_info[23:22]};
	seller_shop_info.level = seller_info[21:20];
	seller_shop_info.exp = {seller_info[19:16], seller_info[31:28], seller_info[27:24]};

	seller_user_info.money = {seller_info[39:36], seller_info[35:32], seller_info[47:44], seller_info[43:40]};
	seller_user_info.shop_history = {seller_info[55:54], seller_info[53:52], seller_info[51:48], seller_info[63:56]};
	//---------------------err--------------------------//
	// Wrong act
	if (history[cur_user_id]==0 || history[buyer_user_info.shop_history.seller_ID]==0 
		|| last_record[buyer_user_info.shop_history.seller_ID][8]!=1'b1
		|| (last_record[buyer_user_info.shop_history.seller_ID][8]==1 && last_record[buyer_user_info.shop_history.seller_ID][7:0]!=cur_user_id)
		|| last_record[cur_user_id][8]!=1'b0
		|| (last_record[cur_user_id][8]==1'b0 && last_record[cur_user_id][7:0]!=buyer_user_info.shop_history.seller_ID)) begin
			//err msg
			cur_err = Wrong_act;
			//complete
			golden_comp = 0;
			//out info
			golden_out = 32'd0;
	end	
	else if (buyer_user_info.shop_history.seller_ID != cur_seller_id ) begin
			//err msg
			cur_err = Wrong_ID;
			//complete
			golden_comp = 0;
			//out info
			golden_out = 32'd0;
	end
	else if (buyer_user_info.shop_history[13:8]!=cur_item_num) begin
		//err msg
		cur_err = Wrong_Num;
		//complete
		golden_comp = 0;
		//out info
		golden_out = 32'd0;
	end
	else if (buyer_user_info.shop_history[15:14]!=cur_item_id) begin
		//err msg
		cur_err = Wrong_Item;
		//complete
		golden_comp = 0;
		//out info
		golden_out = 32'd0;
	
	end
	
	//---------------------Complete--------------------------//
	else begin
		case(cur_item_id)
			Large : begin
				//buyer
				buyer_shop_info.large_num = buyer_shop_info.large_num-cur_item_num;
				buyer_shop_info.medium_num = buyer_shop_info.medium_num;
				buyer_shop_info.small_num = buyer_shop_info.small_num;
				buyer_shop_info.level = buyer_shop_info.level;
				buyer_shop_info.exp = buyer_shop_info.exp;
				buyer_user_info.money = buyer_user_info.money + cur_item_num*'d300;
				buyer_user_info.shop_history = buyer_user_info.shop_history;
				
				//seller
				seller_shop_info.large_num = seller_shop_info.large_num+cur_item_num;
				seller_shop_info.medium_num = seller_shop_info.medium_num;
				seller_shop_info.small_num = seller_shop_info.small_num;
				seller_shop_info.level = seller_shop_info.level;
				seller_shop_info.exp = seller_shop_info.exp;
				seller_user_info.money = seller_user_info.money - cur_item_num*'d300;
				seller_user_info.shop_history = seller_user_info.shop_history;
			end
			Medium : begin
				//buyer
				buyer_shop_info.large_num = buyer_shop_info.large_num;
				buyer_shop_info.medium_num = buyer_shop_info.medium_num-cur_item_num;
				buyer_shop_info.small_num = buyer_shop_info.small_num;
				buyer_shop_info.level = buyer_shop_info.level;
				buyer_shop_info.exp = buyer_shop_info.exp;
				buyer_user_info.money = buyer_user_info.money + cur_item_num*'d200;
				buyer_user_info.shop_history = buyer_user_info.shop_history;
				
				//seller
				seller_shop_info.large_num = seller_shop_info.large_num;
				seller_shop_info.medium_num = seller_shop_info.medium_num+cur_item_num;
				seller_shop_info.small_num = seller_shop_info.small_num;
				seller_shop_info.level = seller_shop_info.level;
				seller_shop_info.exp = seller_shop_info.exp;
				seller_user_info.money = seller_user_info.money - cur_item_num*'d200;
				seller_user_info.shop_history = seller_user_info.shop_history;
			end
			Small : begin
				//buyer
				buyer_shop_info.large_num = buyer_shop_info.large_num;
				buyer_shop_info.medium_num = buyer_shop_info.medium_num;
				buyer_shop_info.small_num = buyer_shop_info.small_num-cur_item_num;
				buyer_shop_info.level = buyer_shop_info.level;
				buyer_shop_info.exp = buyer_shop_info.exp;
				buyer_user_info.money = buyer_user_info.money + cur_item_num*'d100;
				buyer_user_info.shop_history = buyer_user_info.shop_history;
				
				//seller
				seller_shop_info.large_num = seller_shop_info.large_num;
				seller_shop_info.medium_num = seller_shop_info.medium_num;
				seller_shop_info.small_num = seller_shop_info.small_num+cur_item_num;
				seller_shop_info.level = seller_shop_info.level;
				seller_shop_info.exp = seller_shop_info.exp;
				seller_user_info.money = seller_user_info.money - cur_item_num*'d100;
				seller_user_info.shop_history = seller_user_info.shop_history;
			end
		endcase
		//err
		cur_err = No_Err;
		//complete
		golden_comp = 1;
		//out info
		golden_out = {14'd0, buyer_shop_info.large_num, buyer_shop_info.medium_num, buyer_shop_info.small_num};
	end
	
	//record
	if (cur_err==No_Err) begin
		history[cur_user_id] = 0 ;
		history[cur_seller_id] = 0 ;
		for(i=0;i<256;i=i+1)begin
			last_record[i]=last_record[i];
		end
	end
	//Store back to golden DRAM
	buyer_info = {buyer_user_info[7:0], buyer_user_info[15:8], buyer_user_info[23:16], buyer_user_info[31:24],
					buyer_shop_info[7:0], buyer_shop_info[15:8], buyer_shop_info[23:16], buyer_shop_info[31:24]};
		
	golden_DRAM[65536+7+cur_user_id*8] = buyer_info[63:56];
	golden_DRAM[65536+6+cur_user_id*8] = buyer_info[55:48];
	golden_DRAM[65536+5+cur_user_id*8] = buyer_info[47:40];
	golden_DRAM[65536+4+cur_user_id*8] = buyer_info[39:32];
	golden_DRAM[65536+3+cur_user_id*8] = buyer_info[31:24];
	golden_DRAM[65536+2+cur_user_id*8] = buyer_info[23:16];
	golden_DRAM[65536+1+cur_user_id*8] = buyer_info[15:8];
	golden_DRAM[65536+0+cur_user_id*8] = buyer_info[7:0];

	
	seller_info = {seller_user_info[7:0], seller_user_info[15:8], seller_user_info[23:16], seller_user_info[31:24],
					 seller_shop_info[7:0], seller_shop_info[15:8], seller_shop_info[23:16], seller_shop_info[31:24]};
	 	
	golden_DRAM[65536+7+cur_seller_id*8]  =seller_info[63:56];
	golden_DRAM[65536+6+cur_seller_id*8]=seller_info[55:48];
	golden_DRAM[65536+5+cur_seller_id*8]=seller_info[47:40];
	golden_DRAM[65536+4+cur_seller_id*8]=seller_info[39:32];
	golden_DRAM[65536+3+cur_seller_id*8]=seller_info[31:24];
	golden_DRAM[65536+2+cur_seller_id*8]=seller_info[23:16];
	golden_DRAM[65536+1+cur_seller_id*8]=seller_info[15:8];
	golden_DRAM[65536+0+cur_seller_id*8]=seller_info[7:0];
	
end endtask


//================================================================//
//                 Wait out valid Task                             //
//================================================================//
task wait_out_valid_task; begin
    latency = 0;
    while(inf.out_valid !== 1'b1) begin
	latency = latency + 1;
      
     @(negedge clk);
   end
   total_latency = total_latency + latency;
end endtask

//================================================================//
//                 Check answer Task                             //
//================================================================//
task check_ans_task; begin
    if(inf.err_msg !== cur_err || inf.complete !== golden_comp || inf.out_info !== golden_out) begin
        
		$display ("Wrong Answer");
        //repeat(9) @(negedge clk);
        $finish;
    end
	
    
end endtask
endprogram