module Control
#(parameter N = 1'b0)
(
	output 	req, cmd, m0ack, m1ack, muxsdata, tris, muxsaddr, smuxm0, smuxm1,
	input 	m0addr, m1addr, m0req, m1req, m0cmd, m1cmd, ack, clk, reset);

enum logic [1:0] {waitreq, waitack, wr} state = waitreq, next = waitreq; // создание типа данных для регистра, указывающего с каким мастером работает slave
enum bit {prtm0, prtm1} prt = prtm0, nextprt = prtm0; // создание типа данных для состояний КА, обрабатывающего запросы для определённого slave
logic cmdbuf = 0;

logic statework, prt0, prt1; 	// вспомогательные переменные(statework 1, если КА находится в одном из этапов транзакции;
										// prt0 1, если в данный момент времени обрабатывется запрос нулевого мастера или приоритет след. операции пренадлежит ему;
										// prt1 1, если в данный момент времени обрабатывется запрос первого мастера или приоритет след. операции пренадлежит ему)

//*******************************************************										

assign prt0 = (prt == prtm0);										// функции вспомогательных элементов
assign prt1 = (prt == prtm1);
assign statework = ((state == waitack) || (state == wr));

//*******************************************************

assign req = statework & ((m0req & prt0) || (m1req & prt1));	// функции выходов
assign cmd = statework & cmdbuf;
assign m0ack = statework & ack & prt0;
assign m1ack = statework & ack & prt1;
assign muxsdata = prt1;
assign muxsaddr = prt1;
assign tris = statework & cmdbuf;
assign smuxm0 = statework & prt0;
assign smuxm1 = statework & prt1;

//*******************************************************

always_ff @(posedge clk or posedge reset) 					// настройка сброса и переключения КА
	if (reset)
		state <= waitreq;
	else
		state <= next;

//*******************************************************

always_ff @(posedge clk or posedge reset)
	if(reset)
		prt <= prtm0;
	else begin
		prt <= nextprt;
		cmdbuf <= (nextprt == prtm0) ? m0cmd : m1cmd;
	end


//*******************************************************		
		
always_comb										// создание условий выбора запроса для slave
	unique case ({state,prt})
		{waitreq,prtm0}						:	if ((~m0req || ~(m0addr == N)) && m1req && (m1addr == N))
													nextprt = prtm1;
												else
													nextprt = prtm0;
		{waitreq,prtm1}						:	if ((~m1req || ~(m1addr == N)) && m0req && (m0addr == N))
													nextprt = prtm0;
												else
													nextprt = prtm1;
		{waitack,prtm0},{waitack,prtm1}		:	if(prt0 && m0req || prt1 && m1req)
													nextprt = prt;
												else
													nextprt = (prt0) ? prtm1 : prtm0;
		{wr,prtm0}							:	if (m0req && (m0addr == N) && (~m1req || ~(m1addr == N)))
													nextprt = prtm0;
												else
													nextprt = prtm1;
		{wr,prtm1}							:	if ((~m0req || ~(m0addr == N)) && m1req && (m1addr == N))
													nextprt = prtm1;
												else
													nextprt = prtm0;
		default	:	nextprt = prt;
	endcase


//*******************************************************
			
always_comb							// кодирование КС, определяющей следующее состояние КА
	unique case (state)
		waitreq :	if (m0req && (m0addr == N) || m1req && (m1addr == N))
						next = waitack;
					else
						next = waitreq;
		waitack	:	if(prt0 && m0req || prt1 && m1req)
						if (ack)
							next = wr;
						else
							next = waitack;
					else
						if(~m0req && ~m1req)
							next = waitreq;
						else
							next = waitack;
		wr		:	if (m0req && (m0addr == N) || m1req && (m1addr == N))
						next = waitack;
					else
						next = waitreq;
		default	:	next = waitreq;
	endcase	

//*******************************************************

endmodule 