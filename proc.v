/*STACK*/
module stack(input logic clk, input rst, input logic read_allow, input logic write_allow, input logic [15:0] data, output wire [15:0] op1, output wire [15:0] op2);
	logic [6:0] pointer = 0;
	reg [15:0] stack [127:0];

	reg [15:0] tmp1;
	reg [15:0] tmp2;

	always @(posedge clk)
	begin
		tmp1 = stack[pointer];
		tmp2 = stack[pointer - 1];
	end

	assign op1 = tmp1;
	assign op2 = tmp2;

	always @(posedge clk or negedge rst) begin
		if (rst) begin
			pointer = 0;
		end
		else begin
			if (read_allow) begin
				/*Границы*/
				if (pointer > 'd0) begin
					pointer = pointer - 1;
				end
			end
			if (write_allow & read_allow) begin
				pointer = pointer - 1;
			end
			if (write_allow) begin
				/*Границы*/
				if (pointer < 'd127) begin
					pointer = pointer + 1;
					stack[pointer] = data;
				end
			end
		end
	end
endmodule

/*ARITHMETIC LOGIC UNIT*/
module alu(input logic [1:0] operation, input logic [15:0] operand01, input logic [15:0] operand02, output logic [15:0] result);
	wire [15:0] sum;
	wire [15:0] mult;

	// Сумматор
	adder_pos a(operand01, operand02, sum);
	// Умножитель
	mux_pos m(operand01, operand02, mult);

	always @(*) begin
		case (operation)
			/*"+"*/
			'd1:
				result = sum;
			/*"*"*/
			'd2:
				result = mult;
			/*"dup"*/
			'd3:
				result = operand01;
		endcase
	end
endmodule

/*CONTROL UNIT*/
module control_unit(input logic clk, input logic rst, input logic [3:0] command, output logic read_allow, output logic write_allow, output logic [1:0] operator);
	always @(posedge clk or posedge rst, command) begin
		if (rst) begin
			// reset
			write_allow = 0;
			read_allow = 0;
			operator = 0;
		end
		else begin
			case (command)
				/*PUSH*/
				'd1:
					begin
						write_allow = 1;
						read_allow = 0;
						operator = 'd0;
					end
				/*POP*/
				'd2:
					begin
						write_allow = 0;
						read_allow = 1;
						operator = 'd0;
					end
				/*ADD*/
				'd3:
					begin
						write_allow = 1;
						read_allow = 1;
						operator = 'd1;
					end
				/*MULTIPLICATION*/
				'd4:
					begin
						write_allow = 1;
						read_allow = 1;
						operator = 'd2;
					end
				/*DUPLICATE*/
				'd5:
					begin
						write_allow = 1;
						read_allow = 0;
						operator = 'd3;
					end
			endcase
		end
	end
endmodule

/*Сумматор из 2-й лаб.*/
module adder_pos(input logic [15:0] IN_A_POS, input logic [15:0] IN_B_POS, output wire [15:0] OUT_POS);
	wire [17:0] IN_A_RNS, IN_B_RNS, OUT;

	/*Перевод в СОК*/
	pos_to_rns converter01(IN_A_POS, IN_A_RNS);
	pos_to_rns converter02(IN_B_POS, IN_B_RNS);

	/*Рассчет*/
	adder_rns add01(IN_A_RNS, IN_B_RNS, OUT);

	/*Перевод из СОК*/
	rns_to_pos converter03(OUT, OUT_POS);
endmodule

/*Сумматор СОК*/
module adder_rns(input logic [17:0] X, input logic [17:0] Y, output wire [17:0] Z);
	/*Временные переменные*/
	wire [20:0] tmp;
	
	assign tmp[6:0] = X[5:0] + Y[5:0];
	assign tmp[13:7] = X[11:6] + Y[11:6];
	assign tmp[20:14] = X[17:12] + Y[17:12];

	assign Z[5:0] = tmp[6:0] % 6'd37;
 	assign Z[11:6] = tmp[13:7] % 6'd41;
 	assign Z[17:12] = tmp[20:14] % 6'd43;
endmodule

/*Умножитель из 4-й лаб.*/
module mux_pos(input logic [15:0] IN_A_POS, input logic [15:0] IN_B_POS, output wire [15:0] OUT_POS);
	wire [17:0] IN_A_RNS, IN_B_RNS, OUT;

	/*Перевод в СОК*/
	pos_to_rns converter01(IN_A_POS, IN_A_RNS);
	pos_to_rns converter02(IN_B_POS, IN_B_RNS);

	/*Рассчет*/
	mux_rns mux01(IN_A_RNS, IN_B_RNS, OUT);

	/*Перевод из СОК*/
	rns_to_pos converter03(OUT, OUT_POS);
endmodule

module mux_rns(input logic [17:0] X, input logic [17:0] Y, output wire [17:0] Z);
	/*Временные переменные*/
	wire [47:0] tmp;

	/*Умножаем*/
	mux #('d8) mult01({2'b0, X[5:0]}, {2'b0, Y[5:0]}, tmp[15:0]); //добавим 2 бита вперед до 8 бит
	mux #('d8) mult02({2'b0, X[11:6]}, {2'b0, Y[11:6]}, tmp[31:16]);
	mux #('d8) mult03({2'b0, X[17:12]}, {2'b0, Y[17:12]}, tmp[47:32]);

	/*Результат*/
	assign Z[5:0] = tmp[15:0] % 6'd37;
	assign Z[11:6] = tmp[31:16] % 6'd41;
	assign Z[17:12] = tmp[47:32] % 6'd43;
endmodule

/*Умножитель из 3-й лаб.*/
module mux(input logic [SIZE - 1:0] X, input logic [SIZE - 1:0] Y, output wire [2*SIZE - 1:0] Z);
parameter SIZE = 'd16;
	generate
		if (SIZE == 'b1) begin
			assign Z = X*Y;
		end 
		else begin		
			wire [SIZE/2 - 1:0] XH, XL, YH, YL;

			wire [SIZE - 1:0] P1, P2, P3, P4;

			assign XL = X[SIZE/2 - 1:0]; 
			assign XH = X[SIZE - 1:SIZE/2];
			assign YL = Y[SIZE/2 - 1:0];
			assign YH = Y[SIZE - 1:SIZE/2];

			mux #(SIZE/2) m1(XH, YH, P1);
			mux #(SIZE/2) m2(XL, YL, P2);
			mux #(SIZE/2) m3(XH, YL, P3);
			mux #(SIZE/2) m4(XL, YH, P4);

			assign Z = {P1, {SIZE{1'b0}}} + {P3 + P4, {SIZE/2{1'b0}}} + P2;
		end
	endgenerate
endmodule

/*Конвертеры из 2-й лаб.*/
module rns_to_pos(input logic [17:0] value, output wire [15:0] result);
	/*Временные переменные*/
	wire [16:0] mf = 16'd65231;

	wire [62:0] coeff;
	assign coeff[20:0] = value[5:0]*15'd29971; 
	assign coeff[41:21] = value[11:6]*13'd7955;
	assign coeff[62:42] = value[17:12]*15'd27306;

	/*Результат*/
	assign result = (coeff[20:0] + coeff[41:21] + coeff[62:42]) % mf;
endmodule

module pos_to_rns(input logic [15:0] value, output wire [17:0] result);
	/*ОСНОВАНИЕ {37, 41, 43}*/
	assign result[5:0] = value % 6'd37;
	assign result[11:6] = value % 6'd41;
	assign result[17:12] = value % 6'd43;
endmodule