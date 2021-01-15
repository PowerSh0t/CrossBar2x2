module Multiplex
#(parameter M = 32)

(inout [M-1:0]m0rw, m1rw, s0rw, s1rw,
output [M-1:0]s0addr, s1addr,
input [M-1:0]m0addr, m1addr,
input	clk, reset, muxs0addr, muxs1addr, muxs0, muxs1, muxm0, muxm1, tris0, tris1, trim0, trim1);

logic [M-1:0]wbusm0, wbusm1, wbuss0, wbuss1, busm0, busm1, buss0, buss1;
logic [M-1:0] m0data, m1data, m0addrbuf, m1addrbuf;


always_ff @(posedge clk or posedge reset)
if(reset)
	m0data <= 'b0;
else
	m0data <= wbusm0;
	
always_ff @(posedge clk or posedge reset)
if(reset)
	m1data <= 'b0;
else
	m1data <= wbusm1;


always_ff @(posedge clk or posedge reset)
if(reset)
	m0addrbuf <= 'b0;
else
	m0addrbuf <= m0addr;

always_ff @(posedge clk or posedge reset)
if(reset)
	m1addrbuf <= 'b0;
else
	m1addrbuf <= m1addr;

assign s0addr = (muxs0addr) ? m1addrbuf : m0addrbuf;
assign s1addr = (muxs1addr) ? m1addrbuf : m0addrbuf;
assign buss0 = (muxs0) ? m1data : m0data;
assign buss1 = (muxs1) ? m1data : m0data;
assign busm0 = (muxm0) ? wbuss1 : wbuss0;
assign busm1 = (muxm1) ? wbuss1 : wbuss0;


assign s0rw = (tris0) ? buss0 : 'bZ;
assign s1rw = (tris1) ? buss1 : 'bZ;
assign m0rw = (trim0) ? busm0 : 'bZ;
assign m1rw = (trim1) ? busm1 : 'bZ;
assign wbusm0 = m0rw;
assign wbusm1 = m1rw;
assign wbuss0 = s0rw;
assign wbuss1 = s1rw;

endmodule
