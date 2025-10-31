// ============================================================
// Module: flit_pipeline
// Description: Parameterizable pipeline for flit_data and flit_vld
// Notes:
//   - flit_data registers are NOT in reset path
//   - flit_vld registers ARE in reset path
//   - Separate always_ff blocks for clean synthesis
// ============================================================

module flit_pipeline #(
    parameter int FLIT_DW    = 512,  // Flit data width
    parameter int PIPE_DEPTH = 2     // Number of pipeline stages (>=1)
)(
    input  logic                 clk,
    input  logic                 rst_n,

    // Input
    input  logic [FLIT_DW-1:0]   flit_data_in,
    input  logic                 flit_vld_in,

    // Output
    output logic [FLIT_DW-1:0]   flit_data_out,
    output logic                 flit_vld_out
);

    // Internal pipeline storage
    logic [FLIT_DW-1:0] data_pipe [PIPE_DEPTH-1:0];
    logic               vld_pipe  [PIPE_DEPTH-1:0];

    // Pipeline: DATA (no reset)
    always_ff @(posedge clk) begin
        data_pipe[0] <= flit_data_in;
        for (int i = 1; i < PIPE_DEPTH; i++) begin
            data_pipe[i] <= data_pipe[i-1];
        end
    end

    // Pipeline: VALID (with reset)
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < PIPE_DEPTH; i++) begin
                vld_pipe[i] <= 1'b0;
            end
        end
        else begin
            vld_pipe[0] <= flit_vld_in;
            for (int i = 1; i < PIPE_DEPTH; i++) begin
                vld_pipe[i] <= vld_pipe[i-1];
            end
        end
    end

    // Outputs
    assign flit_data_out = data_pipe[PIPE_DEPTH-1];
    assign flit_vld_out  = vld_pipe[PIPE_DEPTH-1];

endmodule
