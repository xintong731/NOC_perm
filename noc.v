module noc_intf(input clk, input reset, 
	 			input noc_to_dev_ctl, input[7:0] noc_to_dev_data,
	 			input stopin, input pushout, input firstout,
	 			output reg noc_from_dev_ctl, output reg [7:0] noc_from_dev_data,
	 			output pushin, output firstin, output stopout)

integer count_id, count_id_d;//count packet operation
integer count_addr,count_addr_d;//count addr
integer count_data, count_data_d;//count data
integer count_din, count_din_d;//count 64bit data go to perm
reg[63:0] noc_din;
reg[1:0] w_alen,r_alen;
reg[2:0] w_dlen,r_dlen;
reg[63:0] w_addr,r_addr;
reg[7:0] w_des_id, w_sor_id, r_des_id, r_sor_id;
reg[127:0]w_data;
reg[1:0]RC;



always @(posedge clk or posedge reset)begin
	if(reset)begin
		//cs<=NOP;
		noc_to_dev_data[2:0]<=0;
		count_id<=0;
		end else begin
			count_id<= #1 count_id_d;
			count_addr<= #1 count_addr_d;
			count_data<= #1 count_data_d;
		end
	end
end

always @(*)begin//write
	case(noc_to_dev_data[2:0])
		0:begin//NOP
			w_alen = 0;
			w_dlen = 0;
			w_addr = 0;
			count_id_d = 0;
			count_addr_d = 0;
			count_data_d = 0;
		end
		2:begin//WRITE
			if(noc_to_dev_ctl)begin
				w_alen = noc_to_dev_data[7:6];
				w_dlen = noc_to_dev_data[5:3];
			end else begin
			    if(count_id<=2)begin
					count_id_d = count_id + 1;
					if(count_id==1)
						w_des_id = noc_to_dev_data;
					else if(count_id==2)
						w_sor_id = noc_to_dev_data;
				else begin
					count_id_d = 0;
					count_addr_d = 0;
				end
				if(count_addr<2**w_alen)begin
					w_addr[8*count_addr + 7: 8*count_addr] = noc_to_dev_data;
					count_addr_d = count_addr + 1;
				end else begin
					count_addr_d = 0;
					count_data_d = 0;
				end
				if(count_data<2**w_dlen)begin
					w_data[8*count_data + 7: 8*count_data] = noc_to_dev_data;
					count_data_d = count_data + 1;
				end else if(count_data<2**w_dlen && (count_data+1)%8==0)begin
					firstin = 1;
					pushin = 1;
					w_data[8*count_data + 7: 8*count_data] = noc_to_dev_data;
					din = w_data[8*(count_data + 1)-1: 8*(count_data + 1)-64];
					count_data_d = count_data + 1;
				end else begin
					firstin = 0;
					pushin = 0;
					noc_from_dev_ctl = 1;
					
				end
						
			end
		end
		4:begin//WRITE RESPONSE
			if(noc_from_dev_ctl)begin
				noc_from_dev_data[5:0] = 6'b000100;
				noc_from_dev_data[7:6] = RC;
			end else begin
			    if(count_id<=2)begin
					count_id_d = count_id + 1;
					if(count_id==1)
						wr_des_id = w_sor_id;
					else if(count_id==2)
						wr_sor_id = w_des_id;
				else begin
					count_id_d = 0;
				end

			end
		end
		5:begin//MESSAGE
			
		end

	endcase
end


always @(posedge clk or posedge reset)begin
	if(reset)begin
		//cs<=NOP;
		noc_to_dev_data[2:0]<=0;
		count_id<=0;
		end else begin
			count_id<= #1 count_id_d;
			count_addr<= #1 count_addr_d;
			count_data<= #1 count_data_d;
		end
	end
end


always @(*)begin
	case(noc_to_dev_data[2:0])
		0:begin//NOP
			r_alen = 0;
			r_dlen = 0;
			r_addr = 0;
			count_id_d = 0;
			count_addr_d = 0;
			count_data_d = 0;
		end
		1:begin//READ
			
		end
	endcase
end

endmodule
