module reconfig_demo(
    input wire clk,           // 50MHz external clock
    input wire reset_n,       // Active low reset
    input wire spi_sck,       // SPI clock from Arduino
    input wire spi_mosi,      // SPI data from Arduino
    input wire spi_ss,        // SPI slave select (active low)
    output reg spi_miso,      // SPI data to Arduino
    output reg [3:0] led_out  // 4 LEDs: [LED3:LED0]
);

// Double-register asynchronous SPI inputs to FPGA clock domain
reg [1:0] sck_sync, mosi_sync, ss_sync;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        sck_sync <= 2'b00;
        mosi_sync <= 2'b00;
        ss_sync <= 2'b11; // inactive high default
    end else begin
        sck_sync <= {sck_sync[0], spi_sck};
        mosi_sync <= {mosi_sync[0], spi_mosi};
        ss_sync <= {ss_sync[0], spi_ss};
    end
end

wire sck_rising = (sck_sync == 2'b01);
wire sck_falling = (sck_sync == 2'b10);
wire ss_active = (ss_sync[1] == 0);  // active low

// SPI byte reception
reg [2:0] bit_count;
reg [7:0] rx_byte;
reg byte_received;

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        bit_count <= 0;
        rx_byte <= 8'b0;
        byte_received <= 0;
    end else if (!ss_active) begin
        bit_count <= 0;
        byte_received <= 0;
    end else if (sck_rising) begin
        rx_byte <= {rx_byte[6:0], mosi_sync[1]};
        bit_count <= bit_count + 1;
        if (bit_count == 7) begin
            byte_received <= 1;
            bit_count <= 0;
        end else begin
            byte_received <= 0;
        end
    end else begin
        byte_received <= 0;
    end
end

// Registers for function and inputs
reg [1:0] logic_function;  // 2 bits for 4 functions
reg [1:0] input_a, input_b;
reg [1:0] result;

// Update configuration based on command received
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        logic_function <= 2'b00;
        input_a <= 2'b00;
        input_b <= 2'b00;
    end else if (byte_received) begin
        case (rx_byte[7:6])
            2'b00: logic_function <= rx_byte[1:0];   // 2 bits for function selector
            2'b01: input_a <= rx_byte[1:0];          // inputs are 2 bits
            2'b10: input_b <= rx_byte[1:0];
            2'b11: ; // no operation for read command here
        endcase
    end
end

// Implement logic functions:

always @(*) begin
    case (logic_function)
        2'b00: result = input_a & input_b;     // AND
        2'b01: result = input_a | input_b;     // OR
        2'b10: result = input_a ^ input_b;     // XOR
        2'b11: result = ~(input_a & input_b);  // NAND
        default: result = 2'b00;
    endcase
end

// SPI transmit shift register for MISO
reg [7:0] tx_byte;
reg [2:0] tx_bit_count;

reg ss_sync_d;
always @(posedge clk or negedge reset_n) begin
    if (!reset_n) ss_sync_d <= 1'b1;
    else ss_sync_d <= ss_sync[1];
end

wire ss_falling_edge = (ss_sync_d == 1'b1) && (ss_sync[1] == 1'b0);

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        tx_byte <= 8'b0;
        tx_bit_count <= 0;
        spi_miso <= 1'b0;
    end else if (ss_falling_edge) begin
        // Pack function and result in one byte to send back:
        // bits [7:6] = 0
        // bits [5:4] = logic_function (2 bits, left justified)
        // bit [3:2] = result
        // bits [1:0] = 0 padding
		  tx_byte <= {2'b00, logic_function, result, 2'b00};
        tx_bit_count <= 0;
        spi_miso <= tx_byte[7];  // MSB first
    end else if (ss_active && sck_falling) begin
        tx_byte <= {tx_byte[6:0], 1'b0};  // shift left
        tx_bit_count <= tx_bit_count + 1;
        spi_miso <= tx_byte[6];
    end else if (ss_sync[1] == 1) begin
        spi_miso <= 1'b0;
        tx_bit_count <= 0;
    end
end

// Output 4 LEDs (LED3 to LED0):
// LED0, LED1 = logic_function (2 bits)
// LED2, LED3 = result

always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
        led_out <= 4'b0000;
    end else begin
		  led_out <= {result, logic_function};
    end
end

endmodule
