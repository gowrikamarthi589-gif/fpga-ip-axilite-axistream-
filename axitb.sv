`timescale 1ns/1ps

module tb_axi_processing_ip;

    parameter DATA_WIDTH = 32;

    // =========================================================
    // CLOCK / RESET
    // =========================================================
    logic aclk;
    logic aresetn;

    // =========================================================
    // AXI4-LITE WRITE ADDRESS
    // =========================================================
    logic [5:0]  s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;

    // =========================================================
    // AXI4-LITE WRITE DATA
    // =========================================================
    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    logic        s_axi_wready;

    // =========================================================
    // AXI4-LITE WRITE RESPONSE
    // =========================================================
    logic [1:0] s_axi_bresp;
    logic       s_axi_bvalid;
    logic       s_axi_bready;

    // =========================================================
    // AXI4-LITE READ ADDRESS
    // =========================================================
    logic [5:0] s_axi_araddr;
    logic       s_axi_arvalid;
    logic       s_axi_arready;

    // =========================================================
    // AXI4-LITE READ DATA
    // =========================================================
    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    // =========================================================
    // AXI4-STREAM INPUT
    // =========================================================
    logic [DATA_WIDTH-1:0] s_axis_tdata;
    logic                  s_axis_tvalid;
    logic                  s_axis_tready;
    logic                  s_axis_tlast;

    // =========================================================
    // AXI4-STREAM OUTPUT
    // =========================================================
    logic [DATA_WIDTH-1:0] m_axis_tdata;
    logic                  m_axis_tvalid;
    logic                  m_axis_tready;
    logic                  m_axis_tlast;


    // =========================================================
    // DUT
    // =========================================================
    axi_processing_ip #(
        .DATA_WIDTH(DATA_WIDTH)
    )
    dut (
        .aclk(aclk),
        .aresetn(aresetn),

        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),

        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),

        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),

        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),

        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),

        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),

        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );


    // =========================================================
    // CLOCK
    // 100 MHz
    // =========================================================
    initial begin
        aclk = 1'b0;

        forever #5 aclk = ~aclk;
    end


    // =========================================================
    // RESET
    // =========================================================
    initial begin

        aresetn = 1'b0;

        s_axi_awaddr  = 0;
        s_axi_awvalid = 0;

        s_axi_wdata   = 0;
        s_axi_wstrb   = 4'h0;
        s_axi_wvalid  = 0;

        s_axi_bready  = 1;

        s_axi_araddr  = 0;
        s_axi_arvalid = 0;
        s_axi_rready  = 1;

        s_axis_tdata  = 0;
        s_axis_tvalid = 0;
        s_axis_tlast  = 0;

        m_axis_tready = 1;

        #100;

        aresetn = 1'b1;

    end


    // =========================================================
    // AXI4-LITE WRITE TASK
    // =========================================================
    task automatic axi_write(
        input logic [5:0]  address,
        input logic [31:0] data
    );

        begin

            @(posedge aclk);

            s_axi_awaddr  <= address;
            s_axi_awvalid <= 1'b1;

            s_axi_wdata   <= data;
            s_axi_wstrb   <= 4'hF;
            s_axi_wvalid  <= 1'b1;

            wait(s_axi_awready && s_axi_wready);

            @(posedge aclk);

            s_axi_awvalid <= 1'b0;
            s_axi_wvalid  <= 1'b0;

            wait(s_axi_bvalid);

            @(posedge aclk);

            s_axi_bready <= 1'b1;

            wait(!s_axi_bvalid);

            @(posedge aclk);

        end

    endtask


    // =========================================================
    // AXI4-LITE READ TASK
    // =========================================================
    task automatic axi_read(
        input logic [5:0] address
    );

        begin

            @(posedge aclk);

            s_axi_araddr  <= address;
            s_axi_arvalid <= 1'b1;

            wait(s_axi_arready);

            @(posedge aclk);

            s_axi_arvalid <= 1'b0;

            wait(s_axi_rvalid);

            $display(
                "AXI READ : Address = %h  Data = %h",
                address,
                s_axi_rdata
            );

            @(posedge aclk);

        end

    endtask


    // =========================================================
    // AXI4-STREAM SEND TASK
    // =========================================================
    task automatic send_stream(
        input logic [DATA_WIDTH-1:0] data,
        input logic                  last
    );

        begin

            @(posedge aclk);

            s_axis_tdata  <= data;
            s_axis_tvalid <= 1'b1;
            s_axis_tlast  <= last;

            wait(s_axis_tready);

            @(posedge aclk);

            s_axis_tvalid <= 1'b0;
            s_axis_tlast  <= 1'b0;

        end

    endtask


    // =========================================================
    // OUTPUT MONITOR
    // =========================================================
    always @(posedge aclk) begin

        if (m_axis_tvalid && m_axis_tready) begin

            $display(
                "STREAM OUT : Time=%0t  Data=%0d  TLAST=%b",
                $time,
                $signed(m_axis_tdata),
                m_axis_tlast
            );

        end

    end


    // =========================================================
    // MAIN TEST
    // =========================================================
    initial begin

        wait(aresetn == 1'b1);

        #20;

        $display("==========================================");
        $display(" AXI PROCESSING IP TEST STARTED");
        $display("==========================================");


        // =====================================================
        // ENABLE IP
        // CONTROL = bit0 ENABLE
        // =====================================================
        axi_write(6'h00, 32'h0000_0001);


        // =====================================================
        // TEST 1 : ADD
        // input + constant
        // =====================================================
        $display("");
        $display("TEST 1 : ADD");

        axi_write(6'h08, 32'd0);
        axi_write(6'h0C, 32'd10);

        send_stream(32'd5,  1'b0);
        send_stream(32'd10, 1'b0);
        send_stream(32'd20, 1'b0);
        send_stream(32'd30, 1'b1);

        #50;


        // =====================================================
        // TEST 2 : SUBTRACT
        // input - constant
        // =====================================================
        $display("");
        $display("TEST 2 : SUBTRACT");

        axi_write(6'h08, 32'd1);
        axi_write(6'h0C, 32'd5);

        send_stream(32'd20, 1'b0);
        send_stream(32'd30, 1'b0);
        send_stream(32'd40, 1'b1);

        #50;


        // =====================================================
        // TEST 3 : MULTIPLY
        // input * gain
        // =====================================================
        $display("");
        $display("TEST 3 : MULTIPLY");

        axi_write(6'h08, 32'd2);
        axi_write(6'h10, 32'd3);

        send_stream(32'd5,  1'b0);
        send_stream(32'd10, 1'b0);
        send_stream(32'd20, 1'b1);

        #50;


        // =====================================================
        // TEST 4 : MAC
        // accumulator = accumulator + input*gain
        // =====================================================
        $display("");
        $display("TEST 4 : MAC");

        axi_write(6'h08, 32'd3);
        axi_write(6'h10, 32'd2);

        send_stream(32'd5,  1'b0);
        send_stream(32'd10, 1'b0);
        send_stream(32'd20, 1'b1);

        #50;


        // =====================================================
        // TEST 5 : THRESHOLD
        // =====================================================
        $display("");
        $display("TEST 5 : THRESHOLD");

        axi_write(6'h08, 32'd4);
        axi_write(6'h0C, 32'd50);

        send_stream(32'd20, 1'b0);
        send_stream(32'd50, 1'b0);
        send_stream(32'd75, 1'b0);
        send_stream(32'd100, 1'b1);

        #50;


        // =====================================================
        // TEST 6 : ABSOLUTE VALUE
        // =====================================================
        $display("");
        $display("TEST 6 : ABSOLUTE VALUE");

        axi_write(6'h08, 32'd5);

        send_stream(-32'sd10, 1'b0);
        send_stream(32'd20,   1'b0);
        send_stream(-32'sd30, 1'b1);

        #50;


        // =====================================================
        // TEST 7 : SCALE
        // input * gain + offset
        // =====================================================
        $display("");
        $display("TEST 7 : SCALE");

        axi_write(6'h08, 32'd6);

        axi_write(6'h10, 32'd2);
        axi_write(6'h14, 32'd10);

        send_stream(32'd5,  1'b0);
        send_stream(32'd10, 1'b0);
        send_stream(32'd20, 1'b1);

        #50;


        // =====================================================
        // READ STATUS
        // =====================================================
        $display("");
        $display("READING STATUS REGISTER");

        axi_read(6'h04);


        // =====================================================
        // READ VERSION
        // =====================================================
        $display("");
        $display("READING VERSION REGISTER");

        axi_read(6'h1C);


        #100;

        $display("");
        $display("==========================================");
        $display(" AXI PROCESSING IP TEST COMPLETED");
        $display("==========================================");

        $finish;

    end

endmodule