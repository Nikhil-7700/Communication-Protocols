// Code your testbench here
// or browse Examples
module uart_tb;
  reg clk = 0,rst = 0;
  reg rx = 1;
  reg [7:0] dintx;
  reg newd;
  wire tx; 
  wire [7:0] doutrx;
  wire donetx;
  wire donerx;
  
  wire tx_busy, rx_busy;
   
  uart_top #(1000000, 9600) dut (clk, rst, rx, dintx, newd, tx, doutrx, donetx, donerx, tx_busy, rx_busy);
    
  always #5 clk = ~clk;  
   
  reg [7:0] rx_data = 0;
  reg [7:0] tx_data = 0;
   
  initial begin
    rst = 1;
	newd = 0;
    repeat(5) @(posedge dut.uclk);
    rst = 0;
	//$info("RESET Done for the Tx check.");
     
    for(int i = 0 ; i < 10; i++) begin
      //$display("Tx Test %0d", i);
      rst = 0;
	  repeat(2) @(posedge dut.uclk);
      newd = 1;
      dintx = $urandom();
	  //$info("NEWd asserted high");
       
      wait(tx == 0);
	  //$info("Tx pulled Low: START CONDITION");
      
      for(int j = 0; j < 8; j++) begin
        @(posedge dut.uclk);
        tx_data = {tx,tx_data[7:1]};
      end
	  
	  @(posedge dut.uclk);
      tx_data = {tx,tx_data[7:1]};
       
      @(posedge donetx);
	  newd = 0;
	  if (tx_data == dintx) $display("Tx TEST CASE %0d SUCCESS at time %0t", i, $time);
      else $display("Tx TEST CASE %0d FAILED - dinTx: %0d ; DataRef: %0d", i, dintx, tx_data);
	  //$info("newd asserted low");
       
    end
	
	rst = 1;
    repeat(5) @(posedge dut.uclk);
    rst = 0;
	//$info("RESET Done for the Rx check.");
	
    for(int i = 0 ; i < 10; i++) begin
	  //$display("Rx Test %0d", i);
      rst = 0;
      newd = 0;
	  
      repeat(2) @(posedge dut.uclk);
      rx = 1'b0;
	  //$info("Rx asserted low");
      @(posedge dut.uclk);
      for(int j = 0; j < 8; j++) begin
        rx = $urandom;
		@(posedge dut.uclk);
        rx_data = {rx, rx_data[7:1]};
      end
	  
	  
       
      @(posedge donerx);
	  rx = 1'b1;
	  if (rx_data == doutrx)$display("Rx TEST CASE %0d SUCCESS at time %0t", i, $time);
	  else $display("Tx TEST CASE %0d FAILED - doutRx: %0d ; DataRef: %0d", i, doutrx, rx_data);
	  @(posedge dut.uclk);
     
    end
	
	$finish();
   
   
  end
  
  /*initial begin
    $dumpfile("dump.vcd");
    $dumpvars;
  end*/
 
 
endmodule
