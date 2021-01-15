`timescale 1ns/1ns
module Test_CrossBar;

typedef struct packed {			// Тип данных для памяти, в которую будут загружатся вектора стимулов
	logic 			m0req,
					m1req,
					m0cmd,
					m1cmd,
					m0slv,
					m1slv;
}command;

logic m0req, m1req, m0cmd, m1cmd, s0ack, s1ack, clk, reset, m0ack, m1ack;
logic 	[31:0]m0addr, m1addr, m0w, m1w;
tri 		[31:0] m0rw = 'bz, m1rw = 'bz;



//*******************************************************

int k = 0, m0adr, m1adr;

logic [31:0]sw[0:1];											//Вспомогательные перменные
bit trim0 = 1'b0, trim1 = 1'b0;
bit tris[0:1] = {1'b0,1'b0};
logic [1:0]sreq;
logic [1:0]scmd;
logic [1:0]sack;
tri [31:0]srw[0:1] = {'bz,'bz};
logic [31:0]saddr[0:1];
logic [1:0]prt = 2'b00;

//*******************************************************

assign m0adr = m0addr[31];
assign m1adr = m1addr[31];
assign srw[0] = (tris[0]) ? sw[0] : 'bz;
assign srw[1] = (tris[1]) ? sw[1] : 'bz;
assign m0rw = (trim0) ? m0w : 'bz;
assign m1rw = (trim1) ? m1w : 'bz;

//*******************************************************

localparam lenStimel = 31; 	// Количество векторов стимулов

command memStimul[0:lenStimel];

//*******************************************************

CrossBar DUTTEST(	m0rw, m1rw, srw[0], srw[1], saddr[0], saddr[1], sreq[0], sreq[1], scmd[0], scmd[1], m0ack, 
						m1ack, m0addr, m1addr, m0req, m1req, m0cmd, m1cmd, sack[0], sack[1], clk, reset);

//*******************************************************



task genStimul(int i);  // Процедура генерации всех нужных стимулов
	@(negedge clk);
	m0req <= memStimul[i].m0req; m1req <= memStimul[i].m1req; m0cmd <= memStimul[i].m0cmd; m1cmd <= memStimul[i].m1cmd;
	m0addr[31] <= memStimul[i].m0slv; m1addr[31] <= memStimul[i].m1slv; m0addr[30:0] <= 'b0; m1addr[30:0] <= 'b0;
endtask

//*******************************************************

task checkReadM0();
	@(negedge clk);
	if((m0req == sreq[m0adr]) && (m0cmd == scmd[m0adr]) && (m0addr == saddr[m0adr])) begin
		sack[m0adr] <= 1'b1;
		sw[m0adr] <= $urandom;
		tris[m0adr] <= 1'b1;
		@(posedge clk);
		#1;
		if(m0rw == srw[m0adr] && m0ack)
			prt[m0adr] <= 1'b1;
		else
			++k;
		#1;
		sack[m0adr] <= 1'b0;
		tris[m0adr] <= 1'b0;
	end
	else begin
		@(posedge clk);
		++k;
		tris[m0adr] <= 1'b0;
	end
endtask

//*******************************************************

task checkWriteM0();
	m0w <= $urandom;
	trim0 <= 1'b1;
	@(negedge clk);
	if((m0req == sreq[m0adr]) && (m0cmd == scmd[m0adr]) && (m0addr == saddr[m0adr]) && (m0rw == srw[m0adr])) begin
		sack[m0adr] <= 1'b1;
		@(posedge clk);
		#1;
		if(m0ack)
			prt[m0adr] <= 1'b1;
		else
			++k;
		#1;
		sack[m0adr] <= 1'b0;
	end
	else begin
		@(posedge clk);
		++k;
	end
	trim0 <= 1'b0;
endtask

//*******************************************************

task checkReadM1();
	@(negedge clk);
	if((m1req == sreq[m1adr]) && (m1cmd == scmd[m1adr]) && (m1addr == saddr[m1adr])) begin
		sack[m1adr] <= 1'b1;
		sw[m1adr] <= $urandom;
		tris[m1adr] <= 1'b1;
		@(posedge clk);
		#1;
		if(m1rw == srw[m1adr] && m1ack)
			prt[m1adr] <= 1'b0;
		else
			++k;
		#1;
		sack[m1adr] <= 1'b0;
		tris[m1adr] <= 1'b0;
	end
	else begin
		@(posedge clk);
		++k;
		tris[m1adr] <= 1'b0;
	end
endtask

//*******************************************************

task checkWriteM1();
	m1w <= $urandom;
	trim1 <= 1'b1;
	@(negedge clk);
	if((m1req == sreq[m1adr]) && (m1cmd == scmd[m1adr]) && (m1addr == saddr[m1adr]) && (m1rw == srw[m1adr])) begin
		sack[m1adr] <= 1'b1;
		@(posedge clk);
		#1;
		if(m1ack)
			prt[m1adr] <= 1'b0;
		else
			++k;
		#1;
		sack[m1adr] <= 1'b0;
	end
	else begin
		@(posedge clk);
		++k;
	end
	trim1 <= 1'b0;
endtask

//*******************************************************

task checkDuplex();
	if(m0adr == m1adr)					//Проверка двух запросов в один slave
		if(prt[m0adr]) begin
			if (m0cmd && m1cmd) begin
					checkWriteM1();
					@(negedge clk);
					#1;
					checkWriteM0();
			end
			else if (m0cmd && ~m1cmd) begin
					checkReadM1();
					@(negedge clk);
					#1;
					checkWriteM0();
			end
			else if (~m0cmd && m1cmd) begin
					checkWriteM1();
					@(negedge clk);
					#1;
					checkReadM0();
			end
			else begin
					checkReadM1();
					@(negedge clk);
					#1;
					checkReadM0();
			end
		end
		else begin
			if (m0cmd && m1cmd) begin
					checkWriteM0();
					@(negedge clk);
					#1;
					checkWriteM1();
			end
			else if (m0cmd && ~m1cmd) begin
					checkWriteM0();
					@(negedge clk);
					#1;
					checkReadM1();
			end
			else if (~m0cmd && m1cmd) begin
					checkReadM0();
					@(negedge clk);
					#1;
					checkWriteM1();
			end
			else begin
					checkReadM0();
					@(negedge clk);
					#1;
					checkReadM1();
			end
		end
	else begin							//Проверка двух запросов в разные slave
		if (m0cmd && m1cmd)
			fork
				checkWriteM0();
				checkWriteM1();
			join
	else if (m0cmd && ~m1cmd)
		fork
			checkWriteM0();
			checkReadM1();
		join
	else if (~m0cmd && m1cmd)
		fork
			checkReadM0();
			checkWriteM1();
		join
	else
		fork
			checkReadM0();
			checkReadM1();
		join
end
endtask

task checkWork(int i);  // Процедура, проверяющая работу
	if(m0req && m1req)
		checkDuplex();
	else begin
		if(m0req)
			if(m0cmd)
				checkWriteM0();
			else
				checkReadM0();
		else
			if(m1cmd)
				checkWriteM1();
			else
				checkReadM1();
	end
	if(k == 0)
		$display($time, " Hi, all nice %p", memStimul[i]);
	else
		$display($time, " Hi, maybe you will see? %p \n k = %d", memStimul[i], k);
endtask

//*******************************************************

initial begin
	clk = 0;
	forever 	#5 clk = ~clk;
end

//*******************************************************

initial begin								//Основной инициализирующий блок
	$readmemb("vectors.txt", memStimul); 
	#1;
	for (int i = 0; i < lenStimel; ++i) begin
		genStimul(i);
		#1;
		checkWork(i);
	end
	$display("Error = %d", k);
end

//*******************************************************

endmodule
