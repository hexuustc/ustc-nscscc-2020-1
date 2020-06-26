`timescale 1ns / 1ps

module ID(
    //global
    input clk,
    input rst,

    //from IF/ID reg
    input [31:0] instr,
    input [31:0] pc_plus_4,
    
    //from WB
    input [6:0] WriteRegW,
    input [31:0] ResultW,
    input [63:0] HI_LO_data,
    input HI_LO_write_enable_from_WB,
    input RegWriteW,

    //from MEM
    input [31:0] ALUoutM,

    //from Hazard Unit
    input ForwardAD,
    input ForwardBD,

    //to EX
    output [5:0] ALUOp,

    //to ID/EX reg
        //outputs from ctl_unit
        output HI_LO_write_enableD,
        output MemReadType,
        output MemReadD,
        output RegWriteD,
        output MemtoRegD,
        output MemWriteD,
        output ALUSrcDA,
        output ALUSrcDB,
        output RegDstD,
        output Imm_sel_and_Branch_taken,
        //outputs from reg_file
        output [31:0] RsValue,
        output [31:0] RtValue,
        //outputs from Instr
        output [31:0] pc_plus_8,
        output [4:0] Rs,
        output [4:0] Rt, 
        output [4:0] Rd,
        output [15:0] imm,
    //to IF stage
    output EPC_sel,
    output BranchD,
    output Jump,
    output [31:0] PCSrc_reg,
    output [31:0] EPC,
    output [31:0] jump_addr,
    //to IF/ID stage
    output CLR_EN,
    //to Harzard unit
    output exception
    
    );

    wire Imm_sel, Branch_taken, RegWriteCD, RegWriteBD;
    wire [31:0] Read_data_1, Read_data_2;

    assign pc_plus_8 = pc_plus_4 + 4;
    assign jump_addr = pc_plus_4 + {{14{imm[15]}},imm,2'b00};
    assign Imm_sel_and_Branch_taken = Imm_sel & Branch_taken;
    assign CLR_EN = Jump | BranchD;
    assign RegWriteD = RegWriteBD | RegWriteCD;
    assign PCSrc_reg = RsValue;

    mux rd1_mux(.m(ForwardAD),
                .in_0(Read_data_1),
                .in_1(ALUoutM),
                .out(RsValue));

    mux rd2_mux(.m(ForwardBD),
                .in_0(Read_data_2),
                .in_1(ALUoutM),
                .out(RtValue));

    Control_Unit CPU_CTL(.Op(instr[31:26]),
                        .func(instr[5:0]),

                        .EPC_sel(EPC_sel),
                        .HI_LO_write_enableD(HI_LO_write_enableD),
                        .MemReadType(MemReadType),
                        .Jump(Jump),
                        .MemReadD(MemReadD),
                        .RegWriteD(RegWriteCD),
                        .MemtoRegD(MemtoRegD),
                        .MemWriteD(MemWriteD),
                        .ALUSrcDA(ALUSrcDA),
                        .ALUSrcDB(ALUSrcDB),
                        .RegDstD(RegDstD),
                        .Imm_sel(Imm_sel));

    register_file reg_file(.clk(clk),
                           .rst(rst),
                           .regwrite(RegWriteW),
                           .hl_write_enable_from_wb(HI_LO_write_enable_from_WB),
                           .read_addr_1(Rs),
                           .read_addr_2(Rd),
                           .hl_data(HI_LO_data),
                           .write_addr(WriteRegW),
                           .write_data(ResultW),
                           .read_data_1(Read_data_1),
                           .read_data_2(Read_data_2),
                           .epc(EPC));

    Branch_judge brch_jdg(.Op(instr[31:26]),
                          .rt(instr[20:16]),
                          .RsValue(RsValue),
                          .RtValue(RtValue),
                          .RegWriteBD(RegWriteBD),
                          .BranchD(BranchD),
                          .branch_taken(Branch_taken));

    decoder dcd(.ins(instr[31:0]),
               .ALUop(ALUop),
               .Rs(Rs),
               .Rt(Rt),
               .Rd(Rd),
               .imm(imm),
               .exception(exception));
    
endmodule