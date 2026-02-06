// ------ UART COMMUNICATION PROTOCOL ------ //

// UART TOP
module uart_top #(
  parameter clk_freq = 1000000,
  parameter baud_rate = 9600
) (
  input clk, rst,
  input rx,
  
  input [7:0] dintx,
  input newd,
  
  output tx,
  output [7:0] doutrx,
  output donetx,
  output donerx,  
  
  output tx_busy,
  output rx_busy
);

  localparam clk_count = (clk_freq/baud_rate);

  reg [31:0] count = 0;
  
  reg uclk = 0;
  
  always @(posedge clk) begin
    
	if (count < clk_count/2) begin
	  uclk <= uclk;
	  count <= count + 1;
	end
	else begin
	  uclk <= ~uclk;
	  count <= 0;
	end
  
  end

  uart_tx utx (uclk, rst, newd, dintx, donetx, tx, tx_busy);
  
  uart_rx urx (uclk, rst, rx, donerx, doutrx, rx_busy);
  
endmodule


// UART Transmitter
module uart_tx(
  input clk, rst,
  input newd,
  input [7:0] txdin,
  
  output reg done,
  output reg tx,
  
  output reg dut_busy
);
  
  typedef enum reg {idle, transfer} state_t;
  
  state_t current_state, next_state;
  
  reg [3:0] count;
  reg [7:0] din;
  
  always @(posedge clk) begin
    
	if (rst) current_state <= idle;
	
	else current_state <= next_state;
	
  end
  
  reg inc_count;			// To increment the count
  always @(posedge clk) begin
    if (inc_count) count <= count + 1;
	else count <= 0;
  end
  
  always @(*) begin
    
	case (current_state)
	
	  idle: begin
	    done <= 1'b0;
		
		inc_count <= 0;
		
				
		if (newd) begin
		  tx <= 1'b0;				// START Condition
		  next_state <= transfer;
		  din <= txdin;
		  dut_busy <= 1;
		end
		
		else begin
		  tx <= 1'b1;				
		  next_state <= idle;
		  dut_busy <= 0;
		end
		
	  end
	  
	  transfer: begin
	    
		if (count <= 3'd7) begin
		  done <= 1'b0;
		  inc_count <= 1;
		  next_state <= transfer;
		  tx <= din[count];
		  dut_busy <= 1;
		end
		
		else begin
		  done <= 1'b1;
		  next_state <= idle;
		  tx <= 1'b1;				// STOP Condition
		  inc_count <= 0;
		  dut_busy <= 0;
		end
		
	  end
	  
	  default: next_state <= idle;
	  
	endcase
	
  end


endmodule


// UART Reciever
module uart_rx(
  input clk, rst,
  input rx,
  
  output reg done,
  output reg [7:0] rxdout,
  
  output reg dut_busy
);


  typedef enum reg {idle, start} state_t;
  
  state_t current_state, next_state;
  
  reg [3:0] count;
  
  always @(posedge clk) begin
    
	if (rst) current_state <= idle;
	
	else current_state <= next_state;
  
  end
  
  reg inc_count;
  always @(posedge clk) begin
    if (inc_count) count <= count + 1;
	else count <= 0;
  end
  
  reg push;
  always @(posedge clk) begin
    if (push) rxdout <= {rx, rxdout[7:1]};
  end
  
  always @(*) begin
  
    case (current_state)
	
	  idle: begin
	    done <= 1'b0;
		rxdout <= 8'b0;
		
		inc_count <= 0;
		push <= 0;
		
		if (!rx) begin
		  next_state <= start;
		  dut_busy <= 1;
		end
		else begin
		  next_state <= idle;
		  dut_busy <= 0;
		end
	  end
	  
	  start: begin
	  
	    if (count <= 3'd7) begin
		  push <= 1;
		  next_state <= start;
		  done <= 1'b0;
		  inc_count <= 1;
		  dut_busy <= 1;
		end
		
		else begin
		  next_state <= idle;
		  done <= 1'b1;
		  inc_count <= 0;
		  dut_busy <= 0;
		  push <= 0;
		end
		
	  end
	  
	  default: next_state <= idle;
	
	endcase
  
  end


endmodule
