module CrossBar 
#(parameter M = 32)
(	inout 	[M-1:0]m0rw, m1rw, s0rw, s1rw,
	output 	[M-1:0]s0addr, s1addr,
	output 	s0req, s1req, s0cmd, s1cmd, m0ack, m1ack,
	input 	[M-1:0] m0addr, m1addr,
	input 	m0req, m1req, m0cmd, m1cmd, s0ack, s1ack, clk, reset);

logic muxs0addr, muxs1addr, muxs0, muxs1, muxm0, muxm1, tris0, tris1,trim0, trim1; //переменные связывающие модули
logic s0m0ack, s0m1ack, s1m0ack, s1m1ack, s0muxm0, s0muxm1, s1muxm0, s1muxm1; //переменные для промежуточных вычислений


Control Cntrl1 (s0req, s0cmd, s0m0ack, s0m1ack, muxs0, tris0, muxs0addr, s0muxm0, s0muxm1, m0addr[31], m1addr[31], m0req, m1req, m0cmd, m1cmd, s0ack, clk, reset);
Control #( 1'b1) Cntrl2 (s1req, s1cmd, s1m0ack, s1m1ack, muxs1, tris1, muxs1addr, s1muxm0, s1muxm1, m0addr[31], m1addr[31], m0req, m1req, m0cmd, m1cmd, s1ack, clk, reset);

Multiplex Communication (m0rw, m1rw, s0rw, s1rw, s0addr, s1addr, m0addr, m1addr, clk, reset, muxs0addr, muxs1addr, muxs0, muxs1, muxm0, muxm1, tris0, tris1, trim0, trim1);

assign m0ack = s0m0ack ^ s1m0ack;
assign m1ack = s0m1ack ^ s1m1ack;
assign muxm0 = ~s0muxm0 & s1muxm0;
assign muxm1 = ~s0muxm1 & s1muxm1;
assign trim0 = m0req & ~m0cmd;
assign trim1 = m1req & ~m1cmd;

endmodule 