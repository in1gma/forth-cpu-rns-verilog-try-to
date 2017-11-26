module test;
	reg clk;
	reg rst;

	/*Данные*/
	wire [15:0] X;
	wire [15:0] Y;
	reg [15:0] Z;

	/*Разрешено читать/писать*/
	wire write;
	wire read;

	/*Стек*/
	stack s01(clk, rst, read, write, Z, X, Y);

	/*АЛУ*/
	wire [1:0] operator;
	wire [15:0] RESULT;

	alu a01(operator, X, Y, RESULT);

	/*Устройство управления*/
	reg [3:0] command;
	control_unit c01(clk, rst, command, read, write, operator);

	always begin
		/*CLOCK*/
		clk = 'b0;
		#5;
		clk = 'b1;
		#5;
	end

	initial begin
		/*Проверка стека (push, pop)!*/
		/*--------------------------------------------------------*/
		// push 11
		command = 'd1;
		Z = 'd11;
		#10;
		/*--------------------------------------------------------*/
		// push 13
		command = 'd1;
		Z = 'd13;
		#10;
		/*--------------------------------------------------------*/
		// pop 13
		command = 'd2;
		#10;
		/*--------------------------------------------------------*/
		// pop 11
		command = 'd2;
		#10;

		/*Проверка АЛУ (результат в RESULT)!*/
		/*--------------------------------------------------------*/
		// push 3
		command = 'd1;
		Z = 'd7;
		#10;
		/*--------------------------------------------------------*/
		// push 2
		command = 'd1;
		Z = 'd2;
		#10;
		/*--------------------------------------------------------*/
		// mult last and last - 1 = 14
		command = 'd4;
		#10;
		/*--------------------------------------------------------*/
		// add last and last - 1 = 5
		command = 'd3;
		#10;
		/*--------------------------------------------------------*/
		// dup = 2
		command = 'd5;
		#10;

		/*--------------------------------------------------------*/
		// wait
		command = 'd0;
		#10
		/*--------------------------------------------------------*/

		$finish;
	end

	initial begin
		$monitor("%3d: WRITE: %d READ: %d | LAST: %d | LAST-1: %d | DATA (IN): %d | RESULT: %d", $stime, write, read, X, Y, Z, RESULT);
		/*$dumpfile("out");
		$dumpvars(0, test);*/
	end
endmodule