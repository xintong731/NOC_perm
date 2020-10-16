module noc_intf(input clk, input reset, 
	 			input noc_to_dev_ctl, input[7:0] noc_to_dev_data,
				output reg noc_from_dev_ctl, output reg [7:0] noc_from_dev_data,
	 			output reg pushin, output reg firstin, input stopin,
				output reg [63:0] din, input pushout, input firstout,
				output stopout, input [63:0] dout);

integer count_id, count_id_d;//count packet operation
integer count_addr,count_addr_d;//count addr
integer count_data, count_data_d;//count data
integer count_din, count_din_d;//count 64bit data go to perm
integer t_count,t_count_d;
reg[63:0] noc_din;
reg[1:0] t_alen,t_alen_d, b_alen,b_alen_d;
reg[2:0] t_dlen,t_dlen_d,b_dlen,b_dlen_d;
reg[7:0][7:0] t_addr,t_addr_d,b_addr,b_addr_d;
reg[7:0] t_des_id, t_des_id_d,t_sor_id,t_sor_id_d, b_des_id,b_des_id_d, b_sor_id,b_sor_id_d;
reg[7:0] t_data,t_data_d;
reg[1:0]RC,RC_d;
reg[7:0]actual_t_dlen, actual_t_dlen_d;
reg [2:0] mes, mes_d;
reg[7:0][7:0]din_temp,din_temp_d;
reg [3:0]mes_b,mes_b_d;
reg[7:0] stop_addr,stop_addr_d;//stopin from 1 to 0, send message
reg[7:0] stop_data,stop_data_d;

enum reg[2:0]{//transfer
	T_IDLE,
	NOP,
	Read,
	Write,
	Perm_write
}t_cs, t_ns;

always @(posedge clk or posedge reset)begin
	if(reset)begin
		t_cs<=T_IDLE;
		count_id<=0;
		count_addr<=0;
		count_data<=0;
		t_alen<=0;
		t_dlen<=0;
		t_addr<=0;
		t_des_id<=0;
		t_sor_id<=0;
		t_data<=0;
		RC<=0;
		actual_t_dlen<=0;
		mes<=0;
		din_temp<=0;
		mes_b<=0;
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
			din_temp<= #1 din_temp_d;
			mes_b<= #1 mes_b_d;

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
	din_temp_d = din_temp;
	mes_b_d = mes_b;
	case(t_cs)
		T_IDLE:begin
			t_alen = 0;
			t_dlen = 0;
			t_addr = 0;
			count_id_d = 0;
			count_addr_d = 0;
			count_data_d = 0;
			t_count_d = 0;
			flag_d = 0;
			if(noc_to_dev_ctl)begin
				case(noc_to_dev_data[2:0])
					0:begin
						t_ns = NOP;
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
						t_dlen_d = noc_to_dev_data[5:3];
						$display("ctl %b data %b %0t",noc_to_dev_ctl,noc_to_dev_data,$time);
						mes_d = 2;
					end
				endcase
			end
		end
		Read:begin
			if(noc_to_dev_ctl==0 && mes==1)begin
					if(count_id==0)begin
						t_des_id_d = noc_to_dev_data;
						count_id_d = count_id + 1;
					end else if(count_id==1)begin
						t_sor_id_d = noc_to_dev_data;
						count_id_d = count_id + 1;
					end else if(count_id==2 && count_addr<2**t_alen)begin
						t_addr_d[count_addr] = noc_to_dev_data;
						count_addr_d = count_addr + 1;
					end else begin
						RC=2'b00;
						mes_b_d = 3;
					end
			end	
		end
		Write:begin
			if(noc_to_dev_ctl==0 && mes==2)begin
					if(count_id==0)begin
						t_des_id_d = noc_to_dev_data;
						count_id_d = count_id + 1;
					end else if(count_id==1)begin
						t_sor_id_d = noc_to_dev_data;
						count_id_d = count_id + 1;
					end else if(count_id==2 && count_addr<2**t_alen)begin
						t_addr_d[count_addr] = noc_to_dev_data;
						count_addr_d = count_addr + 1;
					end else if(count_addr>=2**t_alen && t_count<200 && count_data<2**t_dlen)begin
						if((count_data+1)%8==0)begin
							t_ns = Perm_write;
						end else begin
							din_temp_d[count_data]= noc_to_dev_data;
							count_data_d = count_data + 1;
							t_count_d = t_count + 1;
							t_ns = Write;
						end
					end else if(count_data=2**t_dlen)begin
						RC_d = 2'b00
						mes_b_d = 4;
					end else if(t_count==200 && count_data<2**t_dlen)begin
						RC_d = 2‘b10;
						mes_b_d = 4;

					end
				//end
			end
		end
		Perm_write:begin
			if(stopin==0)begin
				pushin = 1;
				din = din_temp;
				din_temp_d = 0;
				t_ns = Write;
			end else begin
				RC_d = 2'b01;
				mes_b_d = 4;
				actual_t_dlen_d = 8'h02;
			end
		end
	endcase
end

always @(*)begin//noc to tb
	
end

always @(negedge stopin)begin
	stop_addr_d = 8'h42;
	stop_data_d = 8'h78;
end
endmodule
