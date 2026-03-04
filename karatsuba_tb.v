`timescale 1ns / 1ps

module Karatsuba_w_tb();

 reg  [127:0] A, B;
 wire [255:0] C;

    karatsuba_multiplier #(128) uut (
        .A(A),
        .B(B),
        .C(C)
    );

    initial begin
        $monitor("Time=%0t | A=%0d | B=%0d | C=%0d", $time, A, B, C);
        A = 128'd25; B = 16'd12; #10;
        A = 128'd123456789; B = 128'd567890123; #10;
        A = 128'd255; B = 128'd255; #10;
        A = 128'd5000; B = 128'd50000; #10;
        A = 128'd10000000000; B = 128'd111111111111110000; #10;
        A = 128'd500000000000000000; B = 128'd100000000000000000000; #10;
        $finish;
    end

endmodule
