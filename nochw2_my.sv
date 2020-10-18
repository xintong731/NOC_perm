module noc_intf(input clk,rst,noc_to_dev_ctl,
		input[7:0] noc_to_dev_data,
		output reg noc_from_dev_ctl,
		output reg [7:0] noc_from_dev_data, 
		
		output reg pushin,firstin, 
		input stopin,
		output reg [63:0] din, 
		input  pushout, firstout, 
		output reg stopout, 
		input[63:0] dout); 
//decleratio space for write response
logic wr_go,wr_go_d;
logic [1:0]alen_d,alen;
logic [2:0]dlen_d,dlen;
logic [8:0]did_d,did,sr_id_d,sr_id;
logic [2:0]a_cnt_d,a_cnt;
logic err_d,err, rec_d,rec;
logic [6:0]ind_cnt_d,ind_cnt;
logic [7:0]p_cnt_d,p_cnt;
logic [5:0]push_cnt,push_cnt_d;
logic pushin_d,firstin_d;
logic [63:0]din_d;

logic noc_from_dev_ctl_d;
logic [7:0]noc_from_dev_data_d;
logic stopout_d;

enum logic [2:0] {wc_idle,
		  wc_did,
		  wc_sr,
		  wc_addr,
		  wc_wep}wc_cs,wc_ns;
		  
enum logic [1:0] {wr_idle}wr_cs,wr_ns; 
always@(*)begin
//recirculation block
wr_go_d=wr_go; //wr fsm
alen_d=alen;
dlen_d=dlen;
did_d=did;
sr_id_d=sr_id;
a_cnt_d=a_cnt;
err_d=err;
ind_cnt_d=ind_cnt;
p_cnt_d=p_cnt;
push_cnt_d=push_cnt;

pushin_d=pushin;
din_d=din;
firstin_d=firstin;

//noc_from_dev_ctl_d=noc_from_dev_ctl;
//noc_from_dev_data_d=noc_from_dev_data;
//stopout_d=stopout;
// state for write req
case(wc_cs)
	 wc_idle: begin
	      if(noc_to_dev_ctl && (3'b010==noc_to_dev_data[2:0])) begin
		alen_d=noc_to_dev_data[7:6];
		dlen_d=noc_to_dev_data[5:3];
		wc_ns=wc_did;
	      end else begin
		wc_ns=wc_idle;
		alen_d=0;
		dlen_d=0;
	      end
	 end
	 wc_did: begin 
		 did_d=noc_to_dev_data;
		 wc_ns=wc_sr;
	 end
	 wc_sr:begin
		 sr_id_d=noc_to_dev_data;
		 wc_ns=wc_addr;
	 end
	 wc_addr: begin
		if(a_cnt==2**alen)begin 
		    wc_ns=wc_wep;
		    a_cnt_d=0;
		end else begin
		  if(noc_to_dev_data !=0) begin 
		    err_d=1;
		    wc_ns=wc_idle;
		    a_cnt_d=0;			// a_cnt==0 all time accept in w_addr state;
		  end else begin 
		    a_cnt_d=a_cnt+1;
		    wc_ns=wc_addr; 		//i dont konw what to do withe addr ?
		  end 
		end
	 end
	 wc_wep:begin 
	      if(ind_cnt==2**dlen) begin
		ind_cnt_d=0; 
		wc_ns=wc_idle;
		pushin_d=0;
	      end else begin
		ind_cnt_d=ind_cnt+1;
		if(p_cnt<=6)begin
		    case(p_cnt)
			  0:din_d[7:0]=noc_to_dev_data;
			  1:din_d[15:8]=noc_to_dev_data;
			  2:din_d[23:16]=noc_to_dev_data;
			  3:din_d[31:24]=noc_to_dev_data;
			  4:din_d[39:32]=noc_to_dev_data;
			  5:din_d[47:40]=noc_to_dev_data;
			  6:din_d[55:48]=noc_to_dev_data;
		    endcase
			  p_cnt_d= p_cnt +1;
		end else begin 
			din_d[63:56]=noc_to_dev_data;
			p_cnt_d=0;
			pushin_d=1;
			push_cnt_d=push_cnt+1;
			firstin_d=0;
			wc_ns=wc_wep;
			if(ind_cnt==7)begin  firstin_d=1; end 
			if(push_cnt==23) begin
			  rec_d=1; 		//rec is flag for complet one data now write responce
			  pushin_d=0;
			  push_cnt_d=0;
			  wr_go_d=1;
			  wc_ns=wc_idle;
			end
		end
	    end
	end
  endcase
case (wr_cs)   // state for write response base on trigger wr_go
	wr_idle: begin
		if(wr_go) begin
		  wr_go=0;
		  wr_ns=wr_idle;//case:
		
		end else begin
		 wr_ns=wr_idle;
		end	
	end 
endcase//state for read responce base on trigger 
end 

always@(posedge clk or posedge rst) begin
	if (rst) begin
	  wc_cs<=wc_idle;
	  
	  wr_go<=0;
	  wr_go<=0; //wr fsm
	  alen<=0;
	  dlen<=0;
	  did<=0;
	  sr_id<=0;
	  a_cnt<=0;
	  err<=0;
	  ind_cnt<=0;
	  p_cnt<=0;
	  rec<= 0;
	  push_cnt<=0;
	  pushin<=0;
	  din<=0;
	  firstin<=0;
	  
	  wr_cs<=#1 wr_idle;

//	  noc_from_dev_ctl<= 0;
//	  noc_from_dev_data<= 0;
//	  stopout<= 0;
	 end else begin
	  wc_cs<= #1 wc_ns;
	  wr_go<= #1 wr_go_d; //wr fsm
	  alen<= #1 alen_d;
	  dlen<= #1 dlen_d;
	  did<= #1 did_d;
	  sr_id<= #1sr_id_d;
	  a_cnt<= #1 a_cnt_d;
	  err<= #1 err_d;
	  ind_cnt<= #1 ind_cnt_d;
	  p_cnt<= #1 p_cnt_d;
	  rec<= #1 rec_d;
	  push_cnt<= #1 push_cnt_d;
	  pushin<= #1 pushin_d;
	  din<= #1 din_d;
	  firstin<= #1 firstin_d;
	  
	  wr_cs<=#1 wr_ns;

//	  noc_from_dev_ctl<= #1noc_from_dev_ctl_d;
//	  noc_from_dev_data<= #1 noc_from_dev_data_d;
//	  stopout<= #1 stopout_d;

	 end
    end 
endmodule 
