`timescale 1ns / 1ps

module karatsuba_multiplier #(parameter N = 128)(
    input  wire [N-1:0] A,
    input  wire [N-1:0] B,
    output wire [2*N-1:0] C
);
localparam BASE = 16;
generate
if (N <= BASE) begin : base
wire [15:0] a8;
wire [15:0] b8;
wire [31:0] p8;
assign a8 = A;
assign b8 = B;

wallace_16bit dut1(.a(a8),.b(b8),.p(p8));
assign C = p8;
end 
else begin : rec
localparam HALF = N / 2;
localparam A0_w = HALF;                
localparam A1_w = N - HALF;            

wire [A0_w-1:0] A0 = A[A0_w-1:0];
wire [A1_w-1:0] A1 = A[N-1:A0_w];
wire [A0_w-1:0] B0 = B[A0_w-1:0];
wire [A1_w-1:0] B1 = B[N-1:A0_w];

localparam S_w = (A0_w > A1_w) ? (A0_w + 1) : (A1_w + 1);
wire [S_w-1:0] sumA = { {(S_w-A1_w){1'b0}}, A1 } + { {(S_w-A0_w){1'b0}}, A0 };
wire [S_w-1:0] sumB = { {(S_w-A1_w){1'b0}}, B1 } + { {(S_w-A0_w){1'b0}}, B0 };
localparam p0_w   = A0_w + A0_w;        
localparam p2_w   = A1_w + A1_w;        
localparam p11_w  = S_w + S_w;          

wire [p0_w-1:0]  p0;
wire [p2_w-1:0]  p2;
wire [p11_w-1:0] p11;

karatsuba_multiplier #(A0_w) mul_low(
                .A(A0),
                .B(B0),
                .C(p0)
            );

karatsuba_multiplier #(A1_w) mul_high (
                .A(A1),
                .B(B1),
                .C(p2)
            );

karatsuba_multiplier #(S_w) mul_mid (
                .A(sumA),
                .B(sumB),
                .C(p11)
            );
            
localparam P_MAX = (p11_w > p2_w) ? p11_w : p2_w;
localparam P_WIDE = (P_MAX > p0_w) ? P_MAX + 2 : p0_w + 2; 
            
wire signed [P_WIDE-1:0] sp11 = {{(P_WIDE - p11_w){1'b0}}, p11};
wire signed [P_WIDE-1:0] sp2  = {{(P_WIDE - p2_w){1'b0}}, p2};
wire signed [P_WIDE-1:0] sp0  = {{(P_WIDE - p0_w){1'b0}}, p0};

wire signed [P_WIDE-1:0] sp1 = sp11 - sp2 - sp0; 
wire [P_WIDE-1:0] p1 = sp1;
localparam TOT_W = 2*N;
wire [TOT_W-1:0] part_p0 = {{(TOT_W - p0_w){1'b0}}, p0};
wire [TOT_W-1:0] part_p1 = {{(TOT_W - P_WIDE){1'b0}}, p1} << HALF;
wire [TOT_W-1:0] part_p2 = {{(TOT_W - p2_w){1'b0}}, p2} << (2*HALF);
assign C = part_p0 + part_p1 + part_p2;
end
endgenerate
endmodule

// 16x16 Wallace multiplier 

module wallace_mul(input [7:0] a, b, output [15:0] p);
    wire [15:0] pp [7:0];
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : PP
            assign pp[i] = ({8'b0, (a & {8{b[i]}})}) << i;
        end
    endgenerate
    wire sh1,ch1,sh2,ch2,sf1,cf1,sf2,cf2,sf3,cf3,sf4,cf4,sf5,cf5;
    wallace_ha dut0(.a(pp[1][2]),.b(pp[2][2]),.s(sh1),.c_out(ch1));
    wallace_fa uut0(.a(pp[0][3]),.b(pp[1][3]),.cin(pp[2][3]),.s(sf1),.c_out(cf1));
    wallace_fa uut1(.a(pp[0][4]),.b(pp[1][4]),.cin(pp[2][4]),.s(sf2),.c_out(cf2));
    wallace_fa uut2(.a(pp[0][5]),.b(pp[1][5]),.cin(pp[2][5]),.s(sf3),.c_out(cf3));
    wallace_fa uut3(.a(pp[0][6]),.b(pp[1][6]),.cin(pp[2][6]),.s(sf4),.c_out(cf4));
    wallace_fa uut4(.a(pp[0][7]),.b(pp[1][7]),.cin(pp[2][7]),.s(sf5),.c_out(cf5));
    wallace_ha dut1(.a(pp[1][8]),.b(pp[2][8]),.s(sh2),.c_out(ch2));
    //reducing another layer
    wire sh11,ch11,sh22,ch22,sf11,cf11,sf22,cf22,sf33,cf33,sf44,cf44,sf55,cf55;
    wallace_ha dut01(.a(pp[4][5]),.b(pp[5][5]),.s(sh11),.c_out(ch11));
    wallace_fa uut01(.a(pp[3][6]),.b(pp[4][6]),.cin(pp[5][6]),.s(sf11),.c_out(cf11));
    wallace_fa uut11(.a(pp[3][7]),.b(pp[4][7]),.cin(pp[5][7]),.s(sf22),.c_out(cf22));
    wallace_fa uut21(.a(pp[3][8]),.b(pp[4][8]),.cin(pp[5][8]),.s(sf33),.c_out(cf33));
    wallace_fa uut31(.a(pp[3][9]),.b(pp[4][9]),.cin(pp[5][9]),.s(sf44),.c_out(cf44));
    wallace_fa uut41(.a(pp[3][10]),.b(pp[4][10]),.cin(pp[5][10]),.s(sf55),.c_out(cf55));
    wallace_ha dut11(.a(pp[4][11]),.b(pp[5][11]),.s(sh22),.c_out(ch22));
    // further reduction to the next stage
    wire x1,y1,z1,z2,z3,z4,z5,z6,w1,w2,w3,w4,w5,w6;
    wallace_ha ut20(.a(sf1),.b(pp[3][3]),.s(x1),.c_out(y1));
    wallace_fa ut01(.a(cf1),.b(sf2),.cin(pp[3][4]),.s(z1),.c_out(w1));
    wallace_fa ut11(.a(cf2),.b(sf3),.cin(pp[3][5]),.s(z2),.c_out(w2));
    wallace_fa ut21(.a(cf3),.b(sf4),.cin(ch11),.s(z3),.c_out(w3));
    wallace_fa ut31(.a(cf4),.b(sf5),.cin(cf11),.s(z4),.c_out(w4));
    wallace_fa ut41(.a(cf5),.b(sh2),.cin(cf22),.s(z5),.c_out(w5));
    wallace_fa ut51(.a(ch2),.b(pp[2][9]),.cin(cf33),.s(z6),.c_out(w6));
    
    wire a1,a2,b1,b2,c1,c2,c3,c4,c5,d1,d2,d3,d4,d5;
    wallace_ha t01(.a(pp[6][7]),.b(pp[7][7]),.s(a1),.c_out(b1));
    wallace_fa s01(.a(sf33),.b(pp[6][8]),.cin(pp[7][8]),.s(c1),.c_out(d1));
    wallace_fa s11(.a(sf44),.b(pp[6][9]),.cin(pp[7][9]),.s(c2),.c_out(d2));
    wallace_fa s21(.a(sf55),.b(pp[6][10]),.cin(pp[7][10]),.s(c3),.c_out(d3));
    wallace_fa s31(.a(sh22),.b(pp[6][11]),.cin(pp[7][11]),.s(c4),.c_out(d4));
    wallace_fa s41(.a(pp[5][12]),.b(pp[6][12]),.cin(pp[7][12]),.s(c5),.c_out(d5));
    wallace_ha t11(.a(pp[6][13]),.b(pp[7][13]),.s(a2),.c_out(b2));
    
    wire e1,e2,e3,e4,e5,e6,e7,f1,f2,f3,f4,f5,f6,f7,g1,i1,g2,i2;
    wallace_ha sf01(.a(z1),.b(pp[4][4]),.s(e1),.c_out(f1));
    wallace_fa f11(.a(w1),.b(z2),.cin(sh11),.s(e2),.c_out(f2));
    wallace_fa f21(.a(w2),.b(z3),.cin(sf11),.s(e3),.c_out(f3));
    wallace_fa f31(.a(w3),.b(z4),.cin(sf22),.s(e4),.c_out(f4));
    wallace_fa f41(.a(w4),.b(z5),.cin(b1),.s(e5),.c_out(f5));
    wallace_fa f51(.a(w5),.b(z6),.cin(d1),.s(e6),.c_out(f6));
    wallace_fa f61(.a(w6),.b(cf44),.cin(d2),.s(e7),.c_out(f7));
    wallace_ha hh1(.a(cf55),.b(d3),.s(g1),.c_out(i1));
    wallace_ha hh2(.a(ch22),.b(d4),.s(g2),.c_out(i2));
    
    // further reducing to the last stage
    wire s1,s2,s3,s4,s5,s6,s7,h1,h2,h3,h4,h5,h6,h7,s8,h8,s9,h9;
    wallace_ha fa1(.a(e3),.b(pp[6][6]),.s(s1),.c_out(h1));
    wallace_fa fa2(.a(f3),.b(e4),.cin(a1),.s(s2),.c_out(h2));
    wallace_fa fa3(.a(f4),.b(e5),.cin(c1),.s(s3),.c_out(h3));
    wallace_fa fa4(.a(f5),.b(e6),.cin(c2),.s(s4),.c_out(h4));
    wallace_fa fa5(.a(f6),.b(e7),.cin(c3),.s(s5),.c_out(h5));
    wallace_fa fa6(.a(f7),.b(g1),.cin(c4),.s(s6),.c_out(h6));
    wallace_fa fa7(.a(i1),.b(g2),.cin(c5),.s(s7),.c_out(h7));
    wallace_fa fa8(.a(i2),.b(d5),.cin(a2),.s(s8),.c_out(h8));
    wallace_ha fa11(.a(b2),.b(pp[7][14]),.s(s9),.c_out(h9));
    wire [15:0]c_o;
    wallace_cla cla1(.a(pp[0][0]),.b(1'b0),.cin(1'b0),.s(p[0]),.c_out(c_o[0]));
    wallace_cla cla2(.a(pp[0][1]),.b(pp[1][1]),.cin(c_o[0]),.s(p[1]),.c_out(c_o[1]));
    wallace_cla cla3(.a(pp[0][2]),.b(sh1),.cin(c_o[1]),.s(p[2]),.c_out(c_o[2]));
    wallace_cla cla4(.a(ch1),.b(x1),.cin(c_o[2]),.s(p[3]),.c_out(c_o[3]));
    wallace_cla cla5(.a(y1),.b(e1),.cin(c_o[3]),.s(p[4]),.c_out(c_o[4]));
    wallace_cla cla6(.a(f1),.b(e2),.cin(c_o[4]),.s(p[5]),.c_out(c_o[5]));
    wallace_cla cla7(.a(f2),.b(s1),.cin(c_o[5]),.s(p[6]),.c_out(c_o[6]));
    wallace_cla cla8(.a(h1),.b(s2),.cin(c_o[6]),.s(p[7]),.c_out(c_o[7]));
    wallace_cla cla9(.a(h2),.b(s3),.cin(c_o[7]),.s(p[8]),.c_out(c_o[8]));
    wallace_cla cla10(.a(h3),.b(s4),.cin(c_o[8]),.s(p[9]),.c_out(c_o[9]));
    wallace_cla cla11(.a(h4),.b(s5),.cin(c_o[9]),.s(p[10]),.c_out(c_o[10]));
    wallace_cla cla12(.a(h5),.b(s6),.cin(c_o[10]),.s(p[11]),.c_out(c_o[11]));
    wallace_cla cla13(.a(h6),.b(s7),.cin(c_o[11]),.s(p[12]),.c_out(c_o[12]));
    wallace_cla cla14(.a(h7),.b(s8),.cin(c_o[12]),.s(p[13]),.c_out(c_o[13]));
    wallace_cla cla15(.a(h8),.b(s9),.cin(c_o[13]),.s(p[14]),.c_out(c_o[14]));
    wallace_cla cla16(.a(h9),.b(1'b0),.cin(c_o[14]),.s(p[15]),.c_out(c_o[15]));
    
    endmodule
    
    
    module wallace_ha(input a,b,output s,c_out);
    assign s=a^b;
    assign c_out=a&b;
    endmodule
    
    module wallace_fa(input a,b,cin,output s,c_out);
    assign s=a^b^cin;
    assign c_out=(a&b)|(b&cin)|(cin&a);
    endmodule
    
    
    module wallace_cla(input a,b,cin,output s,c_out);
    wire g,p;
    assign g=a&b;
    assign p=a^b;
    assign s=(p^cin);
    assign c_out=g|(p&cin);
    endmodule
    
    module wallace_16bit(
        input  [15:0] a,
        input  [15:0] b,
        output [31:0] p
    );
    
        wire [7:0] a_lo = a[7:0];
        wire [7:0] a_hi = a[15:8];
        wire [7:0] b_lo = b[7:0];
        wire [7:0] b_hi = b[15:8];
    
        wire [15:0] p0;   
        wire [15:0] p1;   
        wire [15:0] p2;   
        wire [15:0] p3;  
        wallace_mul M0 (.a(a_lo), .b(b_lo), .p(p0));
        wallace_mul M1 (.a(a_lo), .b(b_hi), .p(p1));
        wallace_mul M2 (.a(a_hi), .b(b_lo), .p(p2));
        wallace_mul M3 (.a(a_hi), .b(b_hi), .p(p3));
 
        wire [31:0] term0 = {16'b0, p0};            
        wire [31:0] term1 = {8'b0, p1, 8'b0};       
        wire [31:0] term2 = {8'b0, p2, 8'b0};       
        wire [31:0] term3 = {p3, 16'b0};            
        assign p = term0 + term1 + term2 + term3;
    endmodule

