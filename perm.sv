`timescale 1ns/10ps
module perm_blk(input clk, input rst, input pushin, output reg stopin,input firstin, input [63:0] din,

		output reg [2:0] m1rx, output reg [2:0] m1ry,
		input [63:0] m1rd,
		output reg [2:0] m1wx, output reg [2:0] m1wy,output reg m1wr,
		output reg [63:0] m1wd,

		output reg [2:0] m2rx, output reg [2:0] m2ry,
		input [63:0] m2rd,
		output reg [2:0] m2wx, output reg [2:0] m2wy,output reg m2wr,
		output reg [63:0] m2wd,

		output reg [2:0] m3rx, output reg [2:0] m3ry,
		input [63:0] m3rd,
		output reg [2:0] m3wx, output reg [2:0] m3wy,output reg m3wr,
		output reg [63:0] m3wd,

		output reg [2:0] m4rx, output reg [2:0] m4ry,
		input [63:0] m4rd,
		output reg [2:0] m4wx, output reg [2:0] m4wy,output reg m4wr,
		output reg [63:0] m4wd,

		output reg pushout, input stopout, output reg firstout, output reg [63:0] dout);
/*****************input var**************/
enum logic [1:0] {in_idle,
		   in_m1,
		   in_r1w2} in_cs,in_ns; //input states 
	  
logic [2:0]  in_m1_x, in_m1_y,in_m1_x_d,in_m1_y_d,in_m1r_x, in_m1r_x_d, in_m1r_y, in_m1r_y_d;
logic [63:0] in_m1_data,in_m1_data_d,in_m1r_data,in_m1r_data_d;
logic [2:0]  m2w_x, m2w_x_d, m2w_y, m2w_y_d,m2r_x,m2r_x_d,m2r_y,m2r_y_d,tx,tx_d;
logic [63:0] m2w_data,m2w_data_d,acc_c_d,acc_c,acc_d,acc_d_d;
logic [2:0]  m3w_x, m3w_x_d, m3w_y, m3w_y_d,m3r_x,m3r_x_d,m3r_y,m3r_y_d;
logic [63:0] m3w_data,m3w_data_d,acc_chi,acc_chi_d;
logic [2:0]  chi_x,chi_x_d;
logic m1_full_d,m1_full,stopin_d,m1wr_d,m2wr_d,m3wr_d,m4wr_d,accdone,accdone_d,togle,togle_d,m4_full_d,m4_full,m2b_d,m2b;
logic [4:0]round, round_d;
logic [2:0]  m4w_x, m4w_x_d, m4w_y, m4w_y_d,m4r_x,m4r_x_d,m4r_y,m4r_y_d;
logic [63:0] m4w_data,m4w_data_d;

logic pushout_d,firstout_d;
//logic [63:0]dout_d;
/*******************************constant reg for rotation and stuff********/
const reg [5:0]ro_pi_rot[4:0][4:0] ='{'{14,56,61,2,18},
				      '{8,21,15,45,41},
				      '{39,25,43,10,3},
				      '{20,55,6,44,36},
				      '{27,28,62,1,0}};//ASSIGNMET IS BOTTOM LEFT IS Y=0X=4,Y=0X=3,Y=0X=2,Y=0X=1,Y=0X=0

/**************calcultaion FSM var **********************/
enum logic [3:0]{cal_theta_idle,         
		theta_acc_m1,
		theta_incx,
		cal_d_idle,
		acu_d_m3,
		cal_adash_ro,
		cal_chi,
		cal_chi2,
		cal_chi1,
		cal_chi0,
		cal_chi_y,
		take_breathe} cal_theta_cs,cal_theta_ns; // SM for theta 
/*****************output FSM*****************************************/
enum logic [2:0] {out_idle,
		  out_start} out_cs,out_ns;

  ////////////////////combinational block//////////
 
always@(*)begin
/*********Re-cerculation******************/
	in_ns=in_cs; // M1 FF's
	cal_theta_ns=cal_theta_cs;
	out_ns=out_cs;
	
	in_m1_x_d=in_m1_x;
	in_m1_y_d=in_m1_y;
	in_m1r_x_d=in_m1r_x;
	in_m1r_y_d=in_m1r_y;
	in_m1_data_d=in_m1_data;
	
	m2b_d=m2b;
	
	m1wx=in_m1_x;
	m1wy=in_m1_y;
	m1rx=in_m1r_x;
	m1ry=in_m1r_y;
	m1wd=in_m1_data;
	m1wr_d=m1wr;

	stopin_d=stopin;      //flag ff's
	m1_full_d=m1_full;
	m4_full_d=m4_full;

	acc_c_d=acc_c;		// theta c acculumatar
	acc_d_d=acc_d;		// theta d acculumatar s
	tx_d=tx;
	togle_d=togle;
	accdone_d=accdone;
	
	m2w_x_d=m2w_x;
	m2w_y_d=m2w_y;
	m2w_data_d=m2w_data;
	m2r_x_d=m2r_x;
	m2r_y_d=m2r_y;

	m2wx=m2w_x;
	m2wy=m2w_y;
	m2wd=m2w_data;
	m2wr_d=m2wr;
	m2rx=m2r_x;
	m2ry=m2r_y;

	m3w_x_d=m3w_x;
	m3w_y_d=m3w_y;
	m3w_data_d=m3w_data;
	m3r_x_d=m3r_x;
	m3r_y_d=m3r_y;

	m3wx=m3w_x;
	m3wy=m3w_y;
	m3wd=m3w_data;
	m3wr_d=m3wr;
	m3rx=m3r_x;
	m3ry=m3r_y;
	
	m4w_x_d=m4w_x;
	m4w_y_d=m4w_y;
	m4w_data_d=m4w_data;
	m4r_x_d=m4r_x;
	m4r_y_d=m4r_y;

	m4wx=m4w_x;
	m4wy=m4w_y;
	m4wd=m4w_data;
	m4wr_d=m4wr;
	m4rx=m4r_x;
	m4ry=m4r_y;	
	
	m4_full_d=m4_full; 
	
	chi_x_d=chi_x;
	acc_chi_d=acc_chi;
	round_d=round;

	pushout_d=pushout;
	//dout=m4rd; 
	firstout_d=firstout;
/***********************input_FSM*****************************/
	case(in_cs)
		in_idle:begin
			if(m1_full) begin
			    in_ns=in_idle;
			    stopin_d=1'b1;
			end else if(firstin && pushin) begin
			     m1wr_d=1;
			     //in_m1_x_d=in_m1_x+1;
			     in_m1_data_d=din;
			     //stopin_d=1'b0;
			     in_ns=in_m1;
			end else begin
			    m1wr_d=0;
			    in_ns=in_idle;
			  //stopin_d=1'b0;
			end
		end	
		in_m1 : begin 
			if(pushin) begin
			  m1wr_d=1'b1;
			  in_m1_data_d=din;
				  if(in_m1_x ==4 && in_m1_y ==4) begin
				    m1wr_d=0;
				    m1_full_d=1;
					if(~m2b)begin    //m2b flags an on-going permutuation i.e. stopin from m2 
					    m2w_data_d=m1rd;
					    m2wr_d=1;
					    in_m1r_x_d=in_m1r_x+1;
					    in_ns=in_r1w2;
					  end else begin
					    in_ns=in_m1;  //cannot reset in_m1_x and im_m1_y here.
					  end
				  end else if (in_m1_x <=3) begin
				    in_ns=in_m1;
				    in_m1_x_d= in_m1_x+1;
				    if(in_m1_x_d ==4 && in_m1_y ==4) stopin_d=1;
				  end else  begin
				    in_m1_x_d=0;
				    in_m1_y_d= in_m1_y+1;
				    in_ns = in_m1;
				  end
			end else  begin  
			  in_ns= in_m1;
			  m1wr_d=1'b0; end 
		end
		in_r1w2: begin
			m2w_data_d=m1rd;
			if(in_m1r_x ==4 && in_m1r_y ==4) begin ///`````````````read`m1``````//
			    if(m2b)begin
			      in_ns = in_idle;
			      m1_full_d=0;
			      stopin_d=0; // stopin 1>0 after one cycle data changes to new 
			     
			      in_m1_x_d= 0;	in_m1_y_d= 0; // m1 write prointer reset 
			      in_m1r_x_d= 0;	in_m1r_y_d= 0;// m1 read prointer reset
			      m2w_x_d=0;	m2w_y_d=0;    // m2 write prointer reset 
			    end else  begin
			      in_ns=in_r1w2; // we will retain all pointers
			    end
			end else if (in_m1r_x <=3) begin
			  in_ns=in_r1w2;
			  in_m1r_x_d= in_m1r_x+1;
			end else  begin
			  in_m1r_x_d=0;
			  in_m1r_y_d= in_m1r_y+1;
			  in_ns = in_r1w2;
			end
     
			if(m2w_x ==4 && m2w_y ==4) begin///```````` write`m2```no state transition here 26cycle ///
			      m2b_d=1;
			      m2wr_d=0;
			end else if (m2w_x <=3) begin
			      m2w_x_d= m2w_x+1;
			end else  begin
			    m2w_x_d=0;
			    m2w_y_d= m2w_y+1;
			end
		end
		default: $display("no state input state macshine down at state %b at time=%t",in_cs,$time); 
	endcase
 /*******************************************purmutaion_FSM****/
	case(cal_theta_cs)    //0
		cal_theta_idle: begin
			if(m2b)begin 
			  cal_theta_ns = theta_acc_m1;
			  m1wr_d=0; in_m1_x_d=0; in_m1_y_d=0;//for proper reapeatation we need clean reg
			  m4wr_d=0; m4w_x_d=0; m4w_y_d=0;
			  chi_x_d=0; m2r_y_d=0; m2r_y_d=0;
			  
			  acc_c_d= acc_c^m2rd;
			  
			  if(m2r_y<=3) begin
				  in_m1r_y_d=in_m1r_y+1;
				  cal_theta_ns = cal_theta_idle;
			  end else begin 
				    cal_theta_ns = theta_acc_m1;
			  
			  end
			end else 
			  cal_theta_ns= cal_theta_idle;
		end 
		theta_acc_m1: begin //1
			//	acc_c_d= acc_c^m1rd;
			//	$display("read %h form m1 form loc %d,%d acc_c=%h",in_m1r_data,in_m1r_x,in_m1r_y,acc_c);
			//	in_m1r_y_d=in_m1r_y+1;   //<----look, to dbug c val
				if(in_m1r_y==4 && in_m1r_x==4) begin 
						m2w_data_d=acc_c;
						m2wr_d=1'b1;
						acc_c_d=64'b0;
						in_m1r_y_d=0;
						cal_theta_ns=cal_d_idle;
				end else if(in_m1r_y ==4) begin
						cal_theta_ns=theta_incx;
						in_m1r_y_d=0;
						in_m1r_x_d= in_m1r_x+1;
						m2w_data_d=acc_c;
						m2wr_d=1'b1;
				end else cal_theta_ns= theta_acc_m1;
		end
		theta_incx: begin //2
				m2w_x_d=m2w_x+1;
				m2w_y_d=1'b0;
				cal_theta_ns=cal_theta_idle;
				acc_c_d=64'b0;
				m2wr_d=1'b0;
			//	$display("wrote %h to m2 at loc %d,%d",acc_c,m2w_x,m2w_y);
		end
		cal_d_idle: begin //3
				m3wr_d=1'b0;
				m3w_y_d=1'b0;
				m2wr_d=1'b0;
				 if(accdone && tx<=4) begin 
					  m3w_x_d=tx;
					  m3w_data_d=acc_d;
					  m3wr_d=1'b1;
					  tx_d=tx+1;
					  accdone_d=1'b0;
					  acc_d_d=64'b0;
					  if(tx_d == 5)begin
						cal_theta_ns=cal_adash_ro;
						togle_d=1'b0;
						in_m1r_x_d=1'b0; in_m1r_y_d=1'b0;
						m3r_x_d=1'b0; m3r_y_d=1'b0;//reading m1 for next state
					  end else begin
						cal_theta_ns=cal_d_idle;
						togle_d=1'b0;
					  end 
				 end
				 else if  (tx<=4) begin
				      if(~togle)begin 
						   if (tx==0)m2r_x_d=4; 
						   else  m2r_x_d= tx-1;
					togle_d=~togle;
					end else begin
					      if(tx==4) m2r_x_d=0;
					      else m2r_x_d=tx+1;
					togle_d=~togle; 
				      end
				      cal_theta_ns=acu_d_m3;
				end else   $display("problem in %s",cal_theta_idle);	   
		end	
		acu_d_m3 : begin //4
			    if (togle)begin acc_d_d=acc_d^m2rd; end 
			    else begin 
			    acc_d_d=acc_d^rot(m2rd,1);
			    accdone_d=1'b1;
			    end
			   cal_theta_ns= cal_d_idle;
		end 
		cal_adash_ro:begin //5
			tx_d=3'b0;
			m3wr_d=1'b0;
			m2w_data_d=rot((m1rd^m3rd),ro_pi_rot[in_m1r_y][in_m1r_x]);//1) do  adash--->2)do rotation
			/*$display("rotation of %d at loc %d,%d ",ro_pi_rot[in_m1r_y][in_m1r_x],in_m1r_y,in_m1r_x);
			$display("\n %h form m1 form loc %d,%d ",m2w_data_d,m2r_x_d,m2r_y_d);
			$display("\nread %h form m3 form loc %d,%d\n>>>>>read %h form m1 form loc %d,%d \n >>>>>> m2w_data=%h",m3rd,m3r_x,m3r_y,m1rd,in_m1r_x,in_m1r_y,m2w_data_d);*/
			m2w_x_d=in_m1r_y;
			m2w_y_d=((2*in_m1r_x)+(3*in_m1r_y))%5;	// check to debug//----->3)do new addres so M2 has result of ro_pi
			m2wr_d=1'b1;					// Enabel the write of M2
			if(in_m1r_x<=3)begin
				in_m1r_x_d=in_m1r_x+1'b1;
				m3r_x_d=in_m1r_x_d;
				cal_theta_ns=cal_adash_ro;
			end else if(in_m1r_y<=3) begin
				in_m1r_y_d=in_m1r_y+1'b1;
				in_m1r_x_d=1'b0;
				m3r_x_d=1'b0;
				cal_theta_ns=cal_adash_ro;
			end else begin
				cal_theta_ns=cal_chi;
				in_m1r_x_d=1'b0; in_m1r_y_d=1'b0;
				m3r_x_d=1'b0; m3r_y_d=1'b0;
				chi_x_d=1'b0;m2r_y_d=1'b0; m3w_y_d=1'b0; //chi prep
			end 
		end
		cal_chi:begin //6
			m1wr_d=0;			// disabling write as we come from m1 cal_chi0
			m4wr_d=0;			// disabling write as we come from m4 cal_chi0
			m2wr_d=1'b0;			// Dis ableing the  write as we come for ro_pi
			m2w_data_d=64'b0;		// to make me feel good, all reg, not in use is set 0...do it for rest of the design. 
			m2w_x_d=0;m2w_y_d=0;
			m2r_x_d=(chi_x+2)%5;
			cal_theta_ns=cal_chi2;
			if(round<=22)
				in_m1_x_d=chi_x;
			else
				m4w_x_d=chi_x;
			
		end
		cal_chi2:begin //7
			acc_chi_d=m2rd;
			m2r_x_d=(chi_x+1)%5;
			cal_theta_ns=cal_chi1;
		end
		cal_chi1:begin  //8
			acc_chi_d=(~m2rd)&acc_chi;
			m2r_x_d=chi_x;
			cal_theta_ns=cal_chi0;
		end
		cal_chi0:begin	//state 9
			 if (round<=22) begin   
				if ((chi_x==3'b0)&&(in_m1_y==0)) in_m1_data_d=(acc_chi^m2rd)^rc(round);
				else in_m1_data_d=acc_chi^m2rd;
				acc_chi_d=0;
				//in_m1_x_d=chi_x;
				m1wr_d=1'b1;                          //enabelig write to m1 
				if(chi_x<=3) begin
					chi_x_d=chi_x+1'b1;
					cal_theta_ns=cal_chi;
				end else if(m2r_y<=3) begin
					cal_theta_ns=cal_chi_y;
				end else begin
					round_d=round+1'b1;
					in_m1r_x_d=3'b0;              // prepration for theta_idle
					$display("\n end of round %d ",round_d);
					cal_theta_ns=cal_theta_idle;
				end 
		      end else begin		 
			if(~m4_full)begin
				if ((chi_x==3'b0)&&(m4w_y==0)) m4w_data_d=(acc_chi^m2rd)^rc(round);
				else m4w_data_d=acc_chi^m2rd;
				acc_chi_d=0;
				//$display("\n final 24th round %h to loc m3 %d,%d ",m4w_data_d,m4w_x_d,m4w_y);
				m4wr_d=1'b1;             //enabelig write to m4 
				//m4w_x_d=chi_x;
				if(chi_x<=3) begin
					chi_x_d=chi_x+1'b1;
					cal_theta_ns=cal_chi;
					//if(chi_x_d==4)$display("\n final 24th round to am chi_x_d %d ",chi_x_d);
				end else if(m2r_y<=3) begin
					cal_theta_ns=cal_chi_y;
					//$display("\n final 24th round m4w_y %d,m2r_y=%d ",m4w_x_d,m2r_y);
				end else begin
					cal_theta_ns=take_breathe;
					 $display("\n final 24th round over ");
				end 
			 
			 end else begin 
				cal_theta_ns=cal_chi0;
			 end 
		     end
		end 
		cal_chi_y: begin //10
			  cal_theta_ns=cal_chi;
			  if (round<= 22) begin 
			      m2r_y_d=m2r_y+1'b1;
			      in_m1_y_d=in_m1_y+1'b1;
			      in_m1_x_d=0;
			      chi_x_d=0;
			      m1wr_d=0;
			  end else begin
			      m2r_y_d=m2r_y+1'b1;
			      m4w_y_d=m4w_y+1'b1;
			      m4w_x_d=0;
			      chi_x_d=0;
			      m4wr_d=0;
			  end     
		end 
		take_breathe:begin //11
			m1wr_d=0; 
			in_m1_x_d=0; 
			in_m1_y_d=0; 
			m4wr_d=0; 
			m4w_x_d=0; 
			m4w_y_d=0;
			chi_x_d=0;
			m2r_y_d=0;
			m2r_y_d=0;
			round_d=0;
			
			m1_full_d=0;
			m4_full_d=1;
			
		
		cal_theta_ns = cal_theta_idle;
		end 
		default: begin
		 $display("no state out state macshine down at state %b at %t",cal_theta_cs,$time);
		end 
	endcase
/*************************************output FSM************************************************************/

      case (out_cs)
	  out_idle: begin
// 		     
		  if(m4_full) begin
			pushout_d=1;
			firstout_d=1;
			if(stopout)begin
				out_ns=out_start;
			end else begin
				m4r_x_d=m4r_x+1;
				out_ns=out_start;
			end
		  end else begin
			out_ns=out_idle;
			pushout_d=0;
			m4r_x_d=0;
			m4r_y_d=0;
		  end
	  end
	  out_start: begin 
		  //firstout_d=0;
		  if(stopout)begin
			if(m4rx==0 && m4ry==0)firstout_d=1;
			else firstout_d=0;
			out_ns=out_start;
			//m4r_x_d=m4r_x+1;
		  end else begin
			     firstout_d=0;
			if(m4r_x<=3)begin
			      m4r_x_d=m4r_x+1;
			      out_ns=out_start;
			end else if(m4r_y<=3)begin
			      m4r_x_d=0;
			      m4r_y_d=m4r_y+1;
			      out_ns=out_start;
			end else begin
			      out_ns=out_idle;
			      //pushout_d=0;
			      m4_full_d=0;
			end
		  end
	  end
	  default:  $display("no state out state macshine down at state %b at %t",out_cs,$time);
endcase
                	
end 

always@(posedge clk or posedge rst) begin 
	if(rst) begin
		in_cs <=in_idle;
		in_m1_x<=0;
		in_m1_y<=0;
		in_m1r_x<=0;
		in_m1r_y<=0;
		in_m1_data<=0;
		in_m1r_data<=0;
		m1wr<=0;	
		stopin<=0;
		m1_full<=0;
		m2b<=0;
		cal_theta_cs<= cal_theta_idle;
		m2w_x<=2'b0;
		m2w_y<=2'b0;
		m2w_data<=64'b0;
		m2wr<=1'b0;
		m2r_x<=2'b0;
		m2r_y<=2'b0;
	
		acc_c<=2'b0;	
		acc_d<=2'b0;
		togle<=1'b0;
		tx<=0;
		accdone<=1'b0;
		
		m3w_x<=2'b0;
		m3w_y<=2'b0;
		m3w_data<=64'b0;
		m3wr<=0;
		m3r_x<=2'b0;
		m3r_y<=2'b0;
		
		m4w_x<=2'b0;
		m4w_y<=2'b0;
		m4w_data<=64'b0;
		m4wr<=0;
		m4r_x<=2'b0;
		m4r_y<=2'b0;
		m4_full<=1'b0;
		
		chi_x<=2'b0;
		acc_chi<=64'b0;
		round<=4'b0;
		
		out_cs<=out_idle;
		
		pushout<=0;
		dout<=0;
		firstout<=0;
	end else begin
		in_cs <= #1 in_ns;
		
		in_m1_x<= #1 in_m1_x_d;
		in_m1_y <=#1 in_m1_y_d;
		in_m1r_x<=#1 in_m1r_x_d;
		in_m1r_y<=#1 in_m1r_y_d;
		in_m1_data <= #1 in_m1_data_d;
		in_m1r_data <= #1 m1rd;
		m1wr <= #1 m1wr_d;
		
		m2b<=#1 m2b_d;

		stopin <= #1 stopin_d;
		m1_full<= #1 m1_full_d;

		cal_theta_cs<= #1 cal_theta_ns;
		
		m2w_x<= #1 m2w_x_d;
		m2w_y<=#1 m2w_y_d;
		m2w_data<=#1 m2w_data_d;
		m2wr<=#1 m2wr_d; 
		m2r_x<=#1 m2r_x_d;
		m2r_y<=#1 m2r_y_d;
		
		acc_c<=#1 acc_c_d;
		acc_d<=#1 acc_d_d;
		togle<=#1 togle_d;
		tx<=#1 tx_d;
		accdone<=#1 accdone_d;
		
		m3w_x<=#1 m3w_x_d;
		m3w_y<=#1 m3w_y_d;
		m3w_data<=#1 m3w_data_d;
		m3wr<= #1 m3wr_d;
		m3r_x<=#1 m3r_x_d;
		m3r_y<=#1 m3r_y_d;
		
		m4w_x<=#1 m4w_x_d;
		m4w_y<=#1 m4w_y_d;
		m4w_data<=#1 m4w_data_d;
		m4wr<= #1 m4wr_d;
		m4r_x<=#1 m4r_x_d;
		m4r_y<=#1 m4r_y_d;
		
		m4_full<=#1 m4_full_d;
		
		chi_x<=#1 chi_x_d; 
		acc_chi<=#1 acc_chi_d;
		round<= #1 round_d;
		
		out_cs<=#1 out_ns;
		
		pushout<= #1 pushout_d;
		dout<= #1 m4rd;
		firstout<=#1 firstout_d; 
	end
end

/*********** rc val function*/
function logic [63:0] rc (input logic[4:0] ir);
  	case(ir)
		0: rc=64'h0000000000000001;
		1: rc=64'h0000000000008082;
		2: rc=64'h800000000000808A;
		3: rc=64'h8000000080008000;
		4: rc=64'h000000000000808B;
		5: rc=64'h0000000080000001;
		6: rc=64'h8000000080008081;
		7: rc=64'h8000000000008009;
		8: rc=64'h000000000000008A;
		9: rc=64'h0000000000000088;
		10: rc=64'h0000000080008009;
		11: rc=64'h000000008000000A;
		12: rc=64'h000000008000808B;
		13: rc=64'h800000000000008B;
		14: rc=64'h8000000000008089;
		15: rc=64'h8000000000008003;
		16: rc=64'h8000000000008002;
		17: rc=64'h8000000000000080;
		18: rc=64'h000000000000800A;
		19: rc=64'h800000008000000A;
		20: rc=64'h8000000080008081;
		21: rc=64'h8000000000008080;
		22: rc=64'h0000000080000001;
		23: rc=64'h8000000080008008;
	   default:rc=64'h0000000000000000;//  Not sure, kept to avoide latch
	endcase
endfunction 
/******************************************/
function logic [63:0] rot(input [63:0] x, input int y );
reg [127:0] temp;
temp = {64'b0,x}<<y;
rot= temp[127:64]|temp[63:0];
endfunction
endmodule :perm_blk