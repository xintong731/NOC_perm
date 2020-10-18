module noc_intf(input clk, input reset, 
	 			input noc_to_dev_ctl, input[7:0] noc_to_dev_data,
				output reg noc_from_dev_ctl, output reg [7:0] noc_from_dev_data,
	 			output reg pushin, output reg firstin, input stopin,
				output reg [63:0] din, input pushout, input firstout,
				output stopout, input [63:0] dout);

integer count_id, count_id_d;//count packet operation
integer count_addr,count_addr_d;//count addr
integer count_data, count_data_d,b_count_data,b_count_data_d;//count data
integer count_din, count_din_d;//count 64bit data go to perm
integer t_count,t_count_d;
integer b_count_id,b_count_id_d;
integer dout_data,dout_data_d;
reg[1:0] t_alen,t_alen_d;
reg[2:0] t_dlen,t_dlen_d;
reg[7:0][7:0] t_addr,t_addr_d;
reg[7:0] t_des_id, t_des_id_d,t_sor_id,t_sor_id_d, b_des_id,b_des_id_d, b_sor_id,b_sor_id_d,mes_des_id,mes_des_id_d, mes_sor_id,mes_sor_id_d;
reg[7:0] t_data,t_data_d;
reg[1:0]RC,RC_d;
reg[7:0]actual_t_dlen, actual_t_dlen_d,actual_b_dlen, actual_b_dlen_d;
reg [2:0] mes, mes_d;
reg[3:0]mes_b,mes_b_d;
reg[7:0] addr,addr_d;//stopin from 1 to 0, send message
reg[7:0] data,data_d;
reg[7:0] b_addr,b_addr_d;
reg[7:0] b_data,b_data_d;
reg[63:0]din_d;
reg noc_from_dev_ctl_d;
reg[7:0] noc_from_dev_data_d;
reg[199:0][7:0]dout_temp,dout_temp_d;


enum reg[2:0]{//transfer
	T_IDLE,
	Read,
	Write
}t_cs, t_ns;

enum reg[2:0]{
	B_IDLE,
	Read_resp,
	Write_resp,
	Message
}b_cs,b_ns;


always @(posedge clk or posedge reset)begin
	if(reset)begin
		t_cs<=T_IDLE;
		count_id<=0;
		count_addr<=0;
		count_data<=0;
		t_count<=0;
		t_alen<=0;
		t_dlen<=0;
		t_addr<=0;
		t_des_id<=0;
		t_sor_id<=0;
		t_data<=0;
		RC<=0;
		actual_t_dlen<=0;
		mes<=0;
		mes_b<=0;
		din<=0;
		b_cs<=B_IDLE;
		b_des_id<=0;
		b_sor_id<=0;
		actual_b_dlen<=0;
		addr<=0;
		data<=0;
		b_addr<=0;
		b_data<=0;
		b_count_id<=0;
		noc_from_dev_ctl<=0;
   		noc_from_dev_data<=0;
		dout_temp<=0;
		b_count_data<=0;
		dout_data<=0;
		
	end else begin
			t_cs<= #1 t_ns;
			count_id<= #1 count_id_d;
			count_addr<= #1 count_addr_d;
			count_data<= #1 count_data_d;
			t_count<= #1 t_count_d;
			t_alen<= #1 t_alen_d;
			t_dlen<= #1 t_dlen_d;
			t_addr<= #1 t_addr_d;
			t_des_id<= #1 t_des_id_d;
			t_sor_id<= #1 t_sor_id_d;
			t_data<= #1 t_data_d;
			RC<= #1 RC_d;
			actual_t_dlen<= #1 actual_t_dlen_d;
			mes<= #1 mes_d;
			mes_b<= #1 mes_b_d;
			din<= #1 din_d;
			b_cs<= #1 b_ns;
			b_des_id<= #1 b_des_id_d;
			b_sor_id<= #1 b_sor_id_d;
			actual_b_dlen<= #1 actual_b_dlen_d;
			addr<= #1 addr_d;
			data<= #1 data_d;
			b_addr<= #1 b_addr_d;
			b_data<= #1 b_data_d;
			b_count_id<= #1 b_count_id_d;
			noc_from_dev_ctl<= #1 noc_from_dev_ctl_d;
   			noc_from_dev_data<= #1 noc_from_dev_data_d;
			dout_temp<= #1 dout_temp_d;
			b_count_data<= #1 b_count_data_d;
			dout_data<= #1 dout_data_d;
	end
end



always @(*)begin//tb to noc
	t_ns = t_cs;
	count_id_d = count_id;
	count_addr_d = count_addr;
	count_data_d = count_data;
	t_count_d = t_count;
	t_alen_d = t_alen;
	t_dlen_d = t_dlen;
	t_addr_d = t_addr;
	t_des_id_d = t_des_id;
	t_sor_id_d = t_sor_id;
	t_data_d = t_data;
	mes_d = mes;
	mes_b_d = mes_b;
	din_d = din;
	RC_d = RC;
	case(t_ns)
		T_IDLE:begin
    		//if(noc_to_dev_ctl)begin
			t_alen = 0;
			t_dlen = 0;
			t_addr = 0;
			count_id_d = 0;
			count_addr_d = 0;
			count_data_d = 0;
			pushin = 0;
			//mes_b_d = 0;
			//t_count_d = 0;
			
			if(noc_to_dev_ctl)begin
				case(noc_to_dev_data[2:0])
					0:begin
						//t_ns = NOP;
						mes_d = 0;
					end
					1:begin
						$display("read");
						t_ns = Read;
						t_alen_d = noc_to_dev_data[7:6];
						t_dlen_d = noc_to_dev_data[5:3];
						$display("ctl %b data %b %0t",noc_to_dev_ctl,noc_to_dev_data,$time);
						mes_d = 1;
					end
					2:begin
						$display("write");
						t_ns = Write;
						t_alen_d = noc_to_dev_data[7:6];
						t_dlen_d= noc_to_dev_data[5:3];
						$display("ctl %b data %b %0t",noc_to_dev_ctl,noc_to_dev_data,$time);
						mes_d = 2;
					end
				endcase
			end
		end
		Read:begin
			if(mes==1)begin

					if(count_id==0)begin
						t_des_id_d = noc_to_dev_data;
						count_id_d = count_id + 1;
					end else if(count_id==1)begin
						t_sor_id_d = noc_to_dev_data;
						count_id_d = count_id + 1;
					end else if(count_addr<2**t_alen)begin
						t_addr_d[count_addr] = noc_to_dev_data;
						count_addr_d = count_addr + 1;
					end else begin
						//RC=2'b00;
						mes_b_d = 3;
						t_ns = T_IDLE;
					end
			end	
		end
		Write:begin
			if(mes==2)begin
	if(count_id==0)begin
		t_des_id_d = noc_to_dev_data;
		count_id_d = count_id + 1;
	end else if(count_id==1)begin
		t_sor_id_d = noc_to_dev_data;
		count_id_d = count_id + 1;
	end else if(count_addr<2**t_alen)begin
		t_addr_d[count_addr] = noc_to_dev_data;
		count_addr_d = count_addr + 1;
	end else if(stopin==0)begin

			case(count_data%8)
				0:begin
					din[7:0] = noc_to_dev_data;
					pushin=0;
				end
				1:begin
					din[15:8] = noc_to_dev_data;
					pushin=0;
				end
				2:begin
					din[23:16] = noc_to_dev_data;
					pushin=0;
				end
				3:begin
					din[31:24] = noc_to_dev_data;
					pushin = 0;
				end
				4:begin
					din[39:32] = noc_to_dev_data;
					pushin = 0;
				end
				5:begin
					din[47:40] = noc_to_dev_data;
					pushin = 0;
				end
				6:begin
					din[55:48] = noc_to_dev_data;
					pushin = 0;
				end
				7:begin
					din[63:56] = noc_to_dev_data;
					pushin=1;
				end
			endcase
			//if((t_count = 7)begin
				//pushin = 1;
			//end else begin
				//pushin=0;
			//end
		if(count_data==(2**t_dlen)-1 )begin
			RC_d = 2'b00;
			mes_b_d = 4;
			actual_t_dlen_d = count_data + 1;
			t_ns = T_IDLE;
		end else begin
			count_data_d = count_data + 1;
		end
		if(t_count==199)begin
			t_count_d = 0;
			if(count_data<(2**t_dlen)-1)begin
				RC_d = 2'b10;
				mes_b_d = 4;
				actual_t_dlen_d = count_data;
			end else begin
				t_ns = T_IDLE;
			end
		end else begin
			t_count_d = t_count + 1;
		end
		if(t_count==7)
			firstin = 1;
			//pushin=1;
		else
			firstin = 0;
	end else if(stopin==1)begin
		RC_d = 2'b01;
		mes_b_d = 4;
		actual_t_dlen_d = 8'h02;
	end else begin
		t_ns = T_IDLE;
	end
end
end
	endcase
end


always @(posedge clk)begin//noc to tb
	b_ns = b_cs;
	addr_d = addr;
	data_d = data;
	b_count_id_d = b_count_id;
	noc_from_dev_ctl_d = noc_from_dev_ctl;
	noc_from_dev_data_d = noc_from_dev_data;
	dout_temp_d = dout_temp;
	dout_data_d = dout_data;
	b_count_data_d = b_count_data;
	if(mes_b)begin
		case(b_cs)
			B_IDLE:begin
			b_count_id_d = 0;
				case(mes_b)

					3:begin//read response
  						noc_from_dev_ctl_d= 1;
						noc_from_dev_data_d= {RC,6'b000011};
						b_ns = Read_resp;
						//mes_b_d = 0;
					end
					4:begin//write response
						noc_from_dev_ctl_d= 1;
						noc_from_dev_data_d = {RC,6'b000100};
						b_ns = Write_resp;
						//mes_b_d = 0;
					end
					5:begin//message
						noc_from_dev_ctl_d= 1;
						noc_from_dev_data = {8'b11011101};
						b_ns = Message;
					end
					default:begin
						noc_from_dev_ctl_d= 0;
						noc_from_dev_data_d = 0;
						b_ns = B_IDLE;
					end
				endcase
			end
			Read_resp:begin
				noc_from_dev_ctl_d = 0;
				if(firstout && pushout)begin
					dout_temp_d[dout_data] = dout;
					dout_data_d = dout_data + 1;
				end else if(pushout)begin
					if(dout_data==24)begin
						stopout = 1;
						b_count_data_d = 0;
					end else begin
						dout_temp_d[dout_data] = dout;
						dout_data_d = dout_data + 1;
					end
				
				end
			if(b_count_id<3)begin
				mes_b_d = 3;
				if(b_count_id==0)begin
					noc_from_dev_data_d = t_sor_id;
					b_count_id_d = b_count_id + 1;
				end else if(b_count_id==1)begin
					noc_from_dev_data_d = t_des_id;
					b_count_id_d = b_count_id + 1;
				end else if(b_count_id==2)begin
					noc_from_dev_data_d = actual_t_dlen;
					b_count_id_d = b_count_id + 1;
				end
			end else begin
			
			noc_from_dev_data = dout_temp[b_count_data];
			if(b_count_data==199)begin
				b_count_data_d=0;
				if(count_data<(2**t_dlen)-1)begin
					RC_d = 2'b10;
					mes_b_d = 3;
					actual_t_dlen_d = count_data;
				end else begin
					mes_b_d = 0;
					b_count_data_d = 0;
				end
			end else begin
				mes_b_d = 3;
				b_count_data_d = b_count_data + 1;
			end else begin

				b_ns = B_IDLE;
				mes_b_d = 0;
			end


			end	
			Write_resp:begin
				noc_from_dev_ctl_d = 0;
			if(b_count_id<3)begin
				mes_b_d = 4;
				if(b_count_id==0)begin
					noc_from_dev_data_d = t_sor_id;
					b_count_id_d = b_count_id + 1;
					//mes_b_d = 4;
				end else if(b_count_id==1)begin
					noc_from_dev_data_d = t_des_id;
					b_count_id_d = b_count_id + 1;
					//mes_b_d = 4;
				end else if(b_count_id==2)begin
					noc_from_dev_data_d = actual_t_dlen;
					b_count_id_d = b_count_id + 1;
				end
			end else begin
				b_ns = B_IDLE;
				mes_b_d = 0;
			end
			end
			Message:begin
				noc_from_dev_ctl_d = 0;
			if(b_count_id<4)begin
				mes_b_d = 5;
				if(b_count_id==0)begin
					noc_from_dev_data_d = t_sor_id;
					b_count_id_d = b_count_id + 1;
				end else if(b_count_id==1)begin
					noc_from_dev_data_d = t_des_id;
					b_count_id_d = b_count_id + 1;
				end else if(b_count_id==2)begin
					noc_from_dev_data_d = addr;
					b_count_id_d = b_count_id + 1;
				end else if(b_count_id==3)begin
					noc_from_dev_data_d = data;
					b_count_id_d = b_count_id + 1;
				end
			end else begin
				b_ns = B_IDLE;
				mes_b_d = 0;
			end
			end
			
		endcase
	end
end

always @(negedge stopin)begin
	addr_d = 8'h42;
	data_d = 8'h78;
	mes_b_d = 5;
end
always @(posedge pushout)begin
	addr_d = 8'h17;
	data_d = 8'h12;
	mes_b_d = 5;
end
endmodule
