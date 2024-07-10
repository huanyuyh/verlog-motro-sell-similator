module metro(
input coin1,//投币一元口
input coin10, //投币十元口
input clk,//时钟脉冲
input yes,//确认按键
input no,//取消按键
input [1:0] numTicket,//购买票数
input [7:0] destination,//目的地

output reg [7:0] reMoney,//找零寄存器
output reg [2:0] outTicket,//出票寄存器
output reg omoney,//找零脉冲使能
output reg oticket,//出票脉冲使能
output oclkmoney,//找零输出脉冲
output oclkticket//出票率输出脉冲
);
parameter action1 = 2'b00;// 状态机操作1 确认与取消
parameter action2 = 2'b01;//状态机操作2 出票和找零
parameter action3 = 2'b10;//状态机操作3 退钱
reg [7:0] saveMoney;//保存输入总钱数
reg [7:0] needMoney;//需要钱数
wire one_posedge;//投币1元脉冲
wire ten_posedge;//投币10元脉冲
wire yes_posedge;//确认脉冲
wire no_posedge;//取消脉冲
reg delay_one;//一元脉冲延时监测
reg delay_ten;//十元脉冲延时监测
reg delay_yes;//确认脉冲延时监测
reg delay_no;//取消脉冲延时监测
reg [7:0] nowPosition = 8'b00111111;	//藏龙东街
reg [7:0] numStation;//乘坐站数
reg [1:0] action = action1;//初始化状态机
initial
begin
    saveMoney = 1'b0;
	 needMoney = 1'b0;
	 numStation = 1'b0;
	 reMoney = 1'b0;
	 outTicket = 1'b0;
	 omoney = 1'b0;
	 oticket = 1'b0;
	 
end

assign oclkmoney = omoney?clk:0;//找零脉冲使能输出
assign oclkticket = oticket?clk:0;//出票脉冲使能输出
always@(posedge clk) begin
if(one_posedge)begin//投币1元脉冲
		saveMoney <= saveMoney + 8'b00000001;
	end
	if(ten_posedge)begin//投币十元脉冲
		saveMoney <= saveMoney + 8'b00001010;
	end
	if(destination)begin//目的地计算乘坐站数
		if(destination>nowPosition)begin
			numStation <= destination - nowPosition;
		end
		else begin
			numStation <= nowPosition - destination;	
		end
		if(numStation>0&&numStation<6'b000110)begin//乘坐小于5站2元
			needMoney <= 2*(numTicket+1);
		end
		else if (numStation>6'b000101&&numStation<6'b001011) begin//乘坐小于10站3元
			needMoney <= 3*(numTicket+1);
		end
		else if (numStation>6'b001010&&numStation<6'b010000) begin//乘坐小于15站4元
			needMoney <= 4*(numTicket+1);
		end
		else if (numStation>6'b001111&&numStation<6'b010101) begin//乘坐小于20站5元
			needMoney <= 5*(numTicket+1);
		end
		else if (numStation>6'b010100&&numStation<6'b011010) begin//乘坐小于25站6元
			needMoney <= 6*(numTicket+1);
		end
		else begin
			needMoney <= (numStation-1)/5+2*(numTicket+1);
			end
	end
	case(action)
	action1: begin//状态机1 确认和取消
		if(delay_yes)begin
			if(saveMoney >= needMoney)begin//钱够则确认
				reMoney <= saveMoney - needMoney;//计算找零
				outTicket <= numTicket+1;//输出票数
				saveMoney <= 1'b0;//存钱清零
				action <= action2;//进状态2
			end
		end
		if(delay_no)begin//取消
			reMoney <= saveMoney;//退出所有钱
			saveMoney <= 0;//清零
			needMoney <= 0;
			outTicket <= 0;
			action <= action3;//进状态3
		end 
	end
	action2: begin//状态2找零与出票
		if(reMoney==0&&outTicket==0)begin//找零结束回状态1
			action = action1;
		end
		if(reMoney>0)begin
			reMoney <= reMoney -1;
			omoney <= 1;
		end
		else begin
			omoney <= 0;
		end
		if(outTicket>0)begin
			outTicket <= outTicket -1;
			oticket = 1;
		end
		else begin
			oticket <= 0;
		end
	end
	action3: begin//状态3 退钱
		if(reMoney>0)begin
			reMoney <= reMoney -1;
			omoney <= 1;
		end
		else begin
			omoney <= 0;
			action = action1;//结束回状态1
		end
	end
	endcase
	
	
		
		 
		 
		
//		 if(coin1)begin
//			  saveMoney = saveMoney + 1'b1;
//		 end
//		 if(coin10)begin
//			  saveMoney = saveMoney + 4'b1010;
//		 end
		 
		 


end
//投币脉冲监测
always@(posedge clk)
begin
//脉冲延迟
	delay_one <= coin1;
	delay_ten <= coin10;
	delay_yes <= yes;
	delay_no <= no;
end
//投币脉冲信号赋值
assign one_posedge = coin1 & (~delay_one);
assign ten_posedge = coin10 & (~delay_ten);
assign yes_posedge = yes & (~delay_yes);
assign no_posedge = no & (~delay_no);

endmodule
